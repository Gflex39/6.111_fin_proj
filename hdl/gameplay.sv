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
        parameter MAP_BROM_FILE="image.mem"
    )
    (   input wire clk_in,
        input wire new_game, // essentially rst_in
        input wire charging_hit,
        input wire camera_pan_left,
        input wire camera_pan_right,
        input wire new_frame,

        // Fixed point numbers; 8 digits before & after decimal
        output logic [15:0] ball_position_x,
        output logic [15:0] ball_position_y,
        output logic [15:0] ball_speed, // in pixels per frame

        // NOT fixed point; just ints
        output logic [15:0] ball_direction, // 0 to 360; 0=+x, 90=+y, 180=-x, 270=-y;
        output logic [15:0] cam_angle, // different from ball_direction; user can move cam while ball is moving and at rest;

        output logic out_ready, // 1 when all outs are ready
        output logic [2:0] state_out
    );

    parameter WIDTH = 128;
    parameter HEIGHT = 128;
    parameter GROUND_DECEL = 2; // in pixels/frame^2, fixed point
    parameter MAX_INIT_SPEED = 16'b0000_0010_0000_0000; // 2 in fixed point; pixels per frame
    parameter MAX_ANGLE = 16'b0000_0001_0110_1000; // 360
    parameter SPEED_COUNTER_THRESH = 390625; // 2 secs to fully charge bar
    parameter ANGLE_COUNTER_THRESH = 1111111; // 90 deg per sec

    typedef enum {RESTING=0, CHARGING_HIT=1, ON_HIT=2, BALL_MOVING=3, ON_WALL_COLLISION=4, IN_HOLE=5} gameplay_state;

    gameplay_state state;

    assign state_out = state;


    logic speed_incr; 
    logic [31:0] speed_counter; // 0 to 390625 -> 2 secs to fully charge bar
    logic [31:0] angle_counter_left; // 0 to 1111111 -> 1 sec per 90 degrees
    logic [31:0] angle_counter_right; // 0 to 1111111 -> 1 sec per 90 degrees


    // center of the ball
    logic [15:0] ball_position_x_rounded_c;
    logic [15:0] ball_position_y_rounded_c;

    // the 4 sides of the ball, for collision detection
    logic [15:0] ball_position_x_rounded_r;
    logic [15:0] ball_position_x_rounded_l;
    logic [15:0] ball_position_y_rounded_u;
    logic [15:0] ball_position_y_rounded_d;

    logic [1:0] terrain_type;


    // rounder pos_rounder (
    //     .x_in(ball_position_x),
    //     .y_in(ball_position_y),
    //     .x_out_c(ball_position_x_rounded_c),
    //     .x_out_r(ball_position_x_rounded_r),
    //     .x_out_l(ball_position_x_rounded_l),
    //     .y_out_c(ball_position_y_rounded_c),
    //     .y_out_u(ball_position_y_rounded_u),
    //     .y_out_d(ball_position_y_rounded_d)
    // );



    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(2),                       // Specify RAM data width
        .RAM_DEPTH(65536),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(MAP_BROM_FILE))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) bram_palette (
        .addra(ball_position_x_rounded_c>>8 + 128*(ball_position_y_rounded_c>>8)),     // Address bus, width determined from RAM_DEPTH
        .dina(2'b0),       // RAM input data, width determined from RAM_WIDTH
        .clka(clk_in),       // Clock
        .wea(1'b0),         // Write enable
        .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(new_game),       // Output reset (does not affect memory contents)
        .regcea(1'b1),   // Output register enable
        .douta(terrain_type)      // RAM output data, width determined from RAM_WIDTH
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
            state <= RESTING;
            speed_incr <= 1;
            ball_speed <= 0;
            ball_direction <= 0;
            cam_angle <= 0;
            speed_counter <= 0;
            angle_counter_left <= 0;
            angle_counter_right <= 0;
            on_hit_cycles <= 0;

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
                    else cam_angle = 1;
                    angle_counter_left <= 0;
                end
                else angle_counter_left <= angle_counter_left + 1;
            end
            /*
            */

            case (state)
                RESTING: begin
                    if(charging_hit) state <= CHARGING_HIT;
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
                    end
                    else on_hit_cycles <= on_hit_cycles + 1;

                end
                BALL_MOVING: begin
                    if(new_frame) begin
                        // update position & speed
                        if(ball_speed==0) state <= RESTING;
                        else begin
                            if(ball_speed <= GROUND_DECEL) ball_speed <= 0;
                            else ball_speed <= ball_speed - GROUND_DECEL;
                            
                            // we can ignore the 2-cycle latency of reading sin/cos from BROM since we only use the output at 60fps
                            if(cos_sign) ball_position_x <= ball_position_x + (delta_x>>8);
                            else ball_position_x <= ball_position_x - (delta_x>>8);

                            if(sin_sign) ball_position_y <= ball_position_y + (delta_y>>8);
                            else ball_position_y <= ball_position_y - (delta_y>>8);
                        end
                    end
                end
                ON_WALL_COLLISION: begin


                    state <= BALL_MOVING;
                end

                IN_HOLE: begin


                end

            endcase
        end


    end


endmodule


`default_nettype wire