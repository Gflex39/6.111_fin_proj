`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module gameplay 
    #(  
        parameter STARTING_BALL_X = 10,
        parameter STARTING_BALL_Y = 10,
        /*
            .mem file should be formatted as follows.
            each line is 0-3
            128^2 lines total
        */
        parameter MAP_BROM_FILE="data/map1.mem"
    )
    (   input wire clk_in,
        input wire new_game, // essentially rst_in
        input wire charging_hit,
        input wire camera_pan_left,
        input wire camera_pan_right,
        input wire new_frame,
        input wire [7:0] user_input,
        input wire user_rdy,

        // Fixed point numbers; 8 digits before & after decimal
        output logic [15:0] ball_position_x,
        output logic [15:0] ball_position_y,
        output logic [15:0] ball_speed, // in pixels per frame

        // NOT fixed point; just ints
        output logic [15:0] ball_direction, // 0 to 360; 0=+x, 90=+y, 180=-x, 270=-y;
        output logic [15:0] cam_angle, // different from ball_direction; user can move cam while ball is moving and at rest;

        //output logic out_ready, // 1 when all outs are ready
        output logic [7:0] score,
        output logic [2:0] state_out,
        output logic lfsr_out, // color of tile
        output logic [15:0] lfsr_addra,
        output logic [31:0] debug_out

    );

    parameter WIDTH = 160;
    parameter HEIGHT = 90;
    parameter GROUND_DECEL = 2; // in pixels/frame^2, fixed point
    parameter SAND_DECEL = 10;
    parameter MAX_INIT_SPEED = 16'b0000_0001_1000_0000; // 2 in fixed point; pixels per frame
    parameter MAX_SPEED_TO_SCORE = 16'b0000_0000_1000_0000; // 0.5 in fixed point; pixels per frame
    parameter MAX_ANGLE = 16'b0000_0001_0110_1000; // 360
    parameter SPEED_COUNTER_THRESH = 390625; // 2 secs to fully charge bar
    parameter ANGLE_COUNTER_THRESH = 1111111; // 90 deg per sec

    typedef enum {SETTING_UP=0, RESTING=1, CHARGING_HIT=2, ON_HIT=3, BALL_MOVING=4, ON_WALL_COLLISION=5, IN_HOLE=6} gameplay_state;

    gameplay_state state;
    assign debug_out={state};
    assign state_out = state;

    logic speed_incr; 
    logic [31:0] speed_counter; // 0 to 390625 -> 2 secs to fully charge bar
    logic [31:0] angle_counter_left; // 0 to 1111111 -> 1 sec per 90 degrees
    logic [31:0] angle_counter_right; // 0 to 1111111 -> 1 sec per 90 degrees

    logic [3:0] terrain_type;
    // terrain types of edges of ball for collision detection
    logic [3:0] terrain_type_xplus;
    logic [3:0] terrain_type_xminus;
    logic [3:0] terrain_type_yplus;
    logic [3:0] terrain_type_yminus;
    logic [3:0] wall_direction;
    logic [15:0] new_ball_direction;

    reflection_helper ref_helper (
        .ball_direction(ball_direction),
        .wall_direction(wall_direction),
        .new_ball_direction(new_ball_direction)
    );



    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(4),                       // Specify RAM data width
        .RAM_DEPTH(65536),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(map4.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) bram_ball (
        .addra((ball_position_x>>8)+ WIDTH*(ball_position_y>>8)),     // Address bus, width determined from RAM_DEPTH
        .dina(2'b0),       // RAM input data, width determined from RAM_WIDTH
        .clka(clk_in),       // Clock
        .wea(1'b0),         // Write enable
        .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(new_game),       // Output reset (does not affect memory contents)
        .regcea(1'b1),   // Output register enable
        .douta(terrain_type)      // RAM output data, width determined from RAM_WIDTH
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(4),                       // Specify RAM data width
        .RAM_DEPTH(65536),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(map4.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) bram_ball_xplus (
        .addra(((ball_position_x+8'b0111_0000)>>8 )+ WIDTH*(ball_position_y>>8)),     // Address bus, width determined from RAM_DEPTH
        .dina(2'b0),       // RAM input data, width determined from RAM_WIDTH
        .clka(clk_in),       // Clock
        .wea(1'b0),         // Write enable
        .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(new_game),       // Output reset (does not affect memory contents)
        .regcea(1'b1),   // Output register enable
        .douta(terrain_type_xplus)      // RAM output data, width determined from RAM_WIDTH
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(4),                       // Specify RAM data width
        .RAM_DEPTH(65536),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(map4.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) bram_ball_xminus (
        .addra(((ball_position_x-8'b0111_0000)>>8) + WIDTH*(ball_position_y>>8)),     // Address bus, width determined from RAM_DEPTH
        .dina(2'b0),       // RAM input data, width determined from RAM_WIDTH
        .clka(clk_in),       // Clock
        .wea(1'b0),         // Write enable
        .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(new_game),       // Output reset (does not affect memory contents)
        .regcea(1'b1),   // Output register enable
        .douta(terrain_type_xminus)      // RAM output data, width determined from RAM_WIDTH
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(4),                       // Specify RAM data width
        .RAM_DEPTH(65536),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(map4.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) bram_ball_yplus (
        .addra((ball_position_x>>8) + WIDTH*((ball_position_y+8'b0111_0000)>>8)),     // Address bus, width determined from RAM_DEPTH
        .dina(2'b0),       // RAM input data, width determined from RAM_WIDTH
        .clka(clk_in),       // Clock
        .wea(1'b0),         // Write enable
        .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(new_game),       // Output reset (does not affect memory contents)
        .regcea(1'b1),   // Output register enable
        .douta(terrain_type_yplus)      // RAM output data, width determined from RAM_WIDTH
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(4),                       // Specify RAM data width
        .RAM_DEPTH(65536),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(map4.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) bram_ball_yminus (
        .addra((ball_position_x>>8 )+ WIDTH*((ball_position_y-8'b0111_0000)>>8)),     // Address bus, width determined from RAM_DEPTH
        .dina(2'b0),       // RAM input data, width determined from RAM_WIDTH
        .clka(clk_in),       // Clock
        .wea(1'b0),         // Write enable
        .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(new_game),       // Output reset (does not affect memory contents)
        .regcea(1'b1),   // Output register enable
        .douta(terrain_type_yminus)      // RAM output data, width determined from RAM_WIDTH
    );

    logic [1:0] lfsr_counter;
    logic [15:0] q_out;

    lfsr_16 lfsr (
        .clk_in(clk_in), 
        .rst_in(new_game),
        .seed_in(16'b0000_0000_0000_0001),
        .q_out(q_out)
    );

    logic [15:0] cos_abs;
    logic [15:0] sin_abs;
    logic cos_sign;
    logic sin_sign;
    logic [2:0] on_hit_cycles;
    cos_sin_lookup angle_lookup (
        .clk_in(clk_in),
        .angle(ball_direction),
        .cos_abs(cos_abs),
        .sin_abs(sin_abs),
        .cos_sign(cos_sign),
        .sin_sign(sin_sign)
    );

    logic [31:0] delta_x;
    logic [31:0] delta_y;
    assign delta_x = ball_speed * cos_abs;
    assign delta_y = ball_speed * sin_abs;

    always_ff @(posedge clk_in) begin
        if(new_game) begin
            state <= SETTING_UP;
            speed_incr <= 1;
            ball_speed <= 0;
            ball_direction <= 0;
            cam_angle <= 0;
            speed_counter <= 0;
            angle_counter_left <= 0;
            angle_counter_right <= 0;
            on_hit_cycles <= 0;
            wall_direction <= 0;
            score <= 0;
            lfsr_addra <= 0;
            lfsr_counter <= 0;
            lfsr_out <= 0;

            // initialize ball at starting position
            ball_position_x <= (STARTING_BALL_X<<8);
            ball_position_y <= (STARTING_BALL_Y<<8);
        end
        else begin

            /*
                Update camera_angle
            */
            if(camera_pan_right) begin
                if(angle_counter_right==ANGLE_COUNTER_THRESH) begin
                    if(cam_angle>0) cam_angle <= cam_angle - 1;
                    else cam_angle = MAX_ANGLE-1;
                    angle_counter_right <= 0;
                end
                else angle_counter_right <= angle_counter_right + 1;
            end

            if(camera_pan_left) begin
                if(angle_counter_left==ANGLE_COUNTER_THRESH) begin
                    if(cam_angle<MAX_ANGLE) cam_angle <= cam_angle + 1;
                    else cam_angle <= 1;
                    angle_counter_left <= 0;
                end
                else angle_counter_left <= angle_counter_left + 1;
            end
            /*
            */

            case (state)
                SETTING_UP: begin
                    if(lfsr_counter==1) begin
                        if(lfsr_addra < 3600) lfsr_addra <= lfsr_addra + 1;
                        else state <= RESTING;
                        lfsr_counter <= 0;
                    end
                    else lfsr_counter <= lfsr_counter + 1;
                    lfsr_out <= q_out[0]; 
                end
                RESTING: begin
                    if(charging_hit) state <= CHARGING_HIT;
                    // ball_direction <= cam_angle;

                    // if(user_rdy) begin 
                    //     state <= BALL_MOVING;
                    //     ball_speed<=user_input;
                    //     score <= score + 1;
                    // end
                end
                CHARGING_HIT: begin
                    if(charging_hit) begin
                        if(speed_counter==SPEED_COUNTER_THRESH) begin
                            if(speed_incr) begin
                                if(ball_speed < MAX_INIT_SPEED) ball_speed <= ball_speed + 1;
                                else speed_incr <= 0;
                            end
                            else begin // once the speed bar reaches max, go back down to 0
                                if(ball_speed > 0) ball_speed <= ball_speed - 1;
                                else speed_incr <= 1;
                            end
                            speed_counter <= 0;
                        end
                        else speed_counter <= speed_counter + 1;                   
                    end
                    else begin
                        state <= ON_HIT;
                        
                    end
                end
                ON_HIT: begin
                    // give ample time for sin/cos BROM to run before moving on to BALL_MOVING

                    if(on_hit_cycles==0) ball_direction <= cam_angle;

                    if(on_hit_cycles==3) begin 
                        state <= BALL_MOVING;
                        on_hit_cycles <= 0;
                        score <= score + 1;
                    end
                    else on_hit_cycles <= on_hit_cycles + 1;

                end
                BALL_MOVING: begin
                    if(new_frame) begin
                        // update position & speed
                        if(terrain_type==0 && ball_speed<MAX_SPEED_TO_SCORE) state <= IN_HOLE;
                        else if(ball_speed==0) state <= RESTING;


                        //Check if a collision has occured in any direction
                        else if((terrain_type_xplus==1 || terrain_type_xplus==8 || terrain_type_xplus==9|| terrain_type_xplus==10 || terrain_type_xplus==11)|| ((terrain_type_xplus==4 || terrain_type_xplus==5) && (ball_direction<135 || ball_direction>315)) ||((terrain_type_xplus==6 || terrain_type_xplus==7) && (ball_direction<45 || ball_direction>225))) begin
                            
                            state <= ON_WALL_COLLISION; 
                        //Checks if hitting a flat edge
                            if(terrain_type_xplus==1 || terrain_type_xplus==8 || terrain_type_xplus==9|| terrain_type_xplus==10 || terrain_type_xplus==11)begin
                                ball_position_x<= {ball_position_x[15:8],8'b0};
                                wall_direction <= 0;
                        //Checks if coming at the correct angle     
                            end else if (terrain_type_xplus==4 || terrain_type_xplus==5)begin
                                wall_direction<=4;
                            end else wall_direction<=6;


                        end else if((terrain_type_yplus==1 || terrain_type_yplus==6 || terrain_type_yplus==7 || terrain_type_yplus==8 || terrain_type_yplus==9)|| ((terrain_type_yplus==4 || terrain_type_yplus==5) && (ball_direction<135 || ball_direction>315))  ||((terrain_type_yplus==10 || terrain_type_yplus==11) && ball_direction<225 && ball_direction>45)) begin
                            
                            state <= ON_WALL_COLLISION; 
                        //Checks if hitting a flat edge
                            if(terrain_type_yplus==1 || terrain_type_yplus==6 || terrain_type_yplus==7 || terrain_type_yplus==8 || terrain_type_yplus==9)begin
                                ball_position_y<= {ball_position_y[15:8],8'b0};
                                wall_direction <= 1;
                        //Checks if coming at the correct angle     
                            end else if (terrain_type_yplus==4 || terrain_type_yplus==5)begin
                                wall_direction<=4;
                            end else wall_direction<=10;

                        end else if((terrain_type_xminus==1 || terrain_type_xminus==6 || terrain_type_xminus==7 || terrain_type_xminus==4 || terrain_type_xminus==5)|| ((terrain_type_xminus==8 || terrain_type_xminus==9) && ball_direction<315 && ball_direction>135) ||((terrain_type_xminus==10 || terrain_type_xminus==11) && ball_direction<225 && ball_direction>45)) begin
                            
                            state <= ON_WALL_COLLISION; 
                        //Checks if hitting a flat edge
                            if(terrain_type_xminus==1 || terrain_type_xminus==6 || terrain_type_xminus==7 || terrain_type_xminus==4 || terrain_type_xminus==5)begin
                                ball_position_x<= {ball_position_x[15:8]+8'b1,8'b0};
                                wall_direction <= 2;
                        //Checks if coming at the correct angle     
                            end else if (terrain_type_xminus==8 || terrain_type_xminus==9)begin
                                wall_direction<=8;
                            end else wall_direction<=10;

                         
                        end else if((terrain_type_yminus==1 || terrain_type_yminus==10 || terrain_type_yminus==11 || terrain_type_yminus==4 || terrain_type_yminus==5)|| ((terrain_type_yminus==6 || terrain_type_yminus==7) && (ball_direction<45 || ball_direction>225)) ||((terrain_type_yminus==8 || terrain_type_yminus==9) && ball_direction<315 && ball_direction>135)) begin
                            
                            state <= ON_WALL_COLLISION; 
                        //Checks if hitting a flat edge
                            if((terrain_type_yminus==1 || terrain_type_yminus==10 || terrain_type_yminus==11 || terrain_type_yminus==4 || terrain_type_yminus==5))begin
                                ball_position_y<= {ball_position_y[15:8]+8'b1,8'b0};
                                wall_direction <= 3;
                        //Checks if coming at the correct angle     
                            end else if ((terrain_type_yminus==6 || terrain_type_yminus==7))begin
                                wall_direction<=6;
                            end else wall_direction<=8;

                            
                        end else begin
                            if(terrain_type==2 || terrain_type==4|| terrain_type==6|| terrain_type==8|| terrain_type==10) begin // grass
                                if(ball_speed <= GROUND_DECEL) ball_speed <= 0;
                                else ball_speed <= ball_speed - GROUND_DECEL;
                            end
                            else if(terrain_type==3|| terrain_type==5|| terrain_type==7|| terrain_type==9|| terrain_type==11) begin // sand
                                if(ball_speed <= SAND_DECEL) ball_speed <= 0;
                                else ball_speed <= ball_speed - SAND_DECEL;
                            end
                            
                            
                            // we can ignore the 2-cycle latency of reading sin/cos from BROM since we only use the output at 60fps
                            if(cos_sign) ball_position_x <= ball_position_x + (delta_x>>8);
                            else ball_position_x <= ball_position_x - (delta_x>>8);

                            if(sin_sign) ball_position_y <= ball_position_y + (delta_y>>8);
                            else ball_position_y <= ball_position_y - (delta_y>>8);
                        end
                    end
                end
                ON_WALL_COLLISION: begin
                    if(new_frame)begin
                        ball_direction <= new_ball_direction;
                        state <= BALL_MOVING;
                    end
                end

                IN_HOLE: begin


                end

            endcase
        end


    end


endmodule


`default_nettype wire