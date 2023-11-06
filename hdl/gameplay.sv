`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module gameplay 
    #(  parameter WIDTH=128, 
        parameter HEIGHT=128,
        parameter MAP_BROM_FILE="image.mem"
    )
    (   input wire clk_in,
        input wire new_game, // essentially rst_in
        input wire charging_hit,
        input wire camera_pan_left,
        input wire camera_pan_right,
        input wire new_frame

        /*
            Fixed point numbers; 8 digits before & after decimal
        */
        output logic [15:0] ball_position_x,
        output logic [15:0] ball_position_y,
        output logic [15:0] ball_speed, // in pixels per frame
        output logic [15:0] ball_direction, // 0 to 360; 0=+x, 90=+y, 180=-x, 270=-y
        output logic [16:0] cam_angle // different from ball_direction; user can move cam while ball is moving and at rest

        output logic out_ready, // 1 when all outs are ready
        output logic [2:0] state_out
    );

    parameter MAX_INIT_SPEED = 16'b0000_0010_0000_0000; // 2 in fixed point
    parameter MAX_ANGLE = 17'b1_0110_1000_0000_0000; // 360 in fixed point
    parameter SPEED_COUNTER_THRESH = 390625; // 2 secs to fully charge bar
    parameter ANGLE_COUNTER_THRESH = 4340; // 90 deg per sec

    typedef enum {RESTING=0, CHARGING_HIT=1, ON_HIT=2, BALL_MOVING=3, ON_WALL_COLLISION=4, IN_HOLE=5} gameplay_state;

    gameplay_state state;


    logic speed_incr; 
    logic [31:0] speed_counter; // 0 to 390625 -> 2 secs to fully charge bar
    logic [15:0] angle_counter_left; // 0 to 4340 -> 1 sec per 90 degrees
    logic [15:0] angle_counter_right; // 0 to 4340 -> 1 sec per 90 degrees

    always_ff @(posedge clk_in) begin
        if(new_game) begin
            state <= RESTING;
            speed_incr <= 1;
            speed <= 0;
            cam_angle <= 0;
            speed_counter <= 0;
            angle_counter_left <= 0;
            angle_counter_right <= 0;

            // initialize ball at starting position
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
                    state <= BALL_MOVING;
                    ball_direction <= cam_angle;
                end
                BALL_MOVING: begin
                    if(new_frame) begin
                        // update position & speed

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