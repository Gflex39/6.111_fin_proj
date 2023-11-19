`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

/**
    
**/
module reflection_helper 
    (
        input wire [15:0] ball_direction,
        input wire [1:0] wall_direction, // 0=(+x), 1=(y+), 2=(x-), 3=(y-)
        output logic [15:0] new_ball_direction
    );

    always_comb begin
      if(wall_direction==0) begin
        if(ball_direction<=90) new_ball_direction = 180 - ball_direction; // Q1
        else new_ball_direction = 540-ball_direction; // Q4
      end
      else if(wall_direction==1) new_ball_direction = 360 - ball_direction; // Q1 or Q2
      else if(wall_direction==2) begin
        if(ball_direction<=180) new_ball_direction = 180 - ball_direction; // Q2
        else new_ball_direction = 540 - ball_direction; // Q3
      end
      else new_ball_direction = 360 - ball_direction;
    end
endmodule

`default_nettype wire