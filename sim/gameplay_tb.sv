// set the timestep on the internal simulation clock
`timescale 1ns / 1ps
`default_nettype none

 
//The timescale specifies the timestep size (1ns) and time resolution of rounding (1ps)
//we'll usually use 1ns/1ps in our class
 
module gameplay_tb();
 
  //make inputs and outputs of appropriate size for the module testing:
  logic clk_in;
  logic new_game;
  logic charging_hit;
  logic camera_pan_right;
  logic [15:0] bp_x;
  logic [15:0] bp_y;
  logic [15:0] ball_speed;
  logic [15:0] ball_direction;
  logic [15:0] cam_angle;
  logic out_ready;
  logic [2:0] state;

  always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
  end
 
  //create an instance of the module. UUT= unit under test, but call it whatever:
  //always use named port convention when declaring (it is much easier to protect from bugs)
  gameplay game(
    .clk_in(clk_in), 
    .new_game(new_game), 
    .charging_hit(charging_hit),
    .camera_pan_left(1'b0), 
    .camera_pan_right(camera_pan_right), 
    .new_frame(1'b0),
    .ball_position_x(bp_x),
    .ball_position_y(bp_y),
    .ball_speed(ball_speed),
    .ball_direction(ball_direction),
    .cam_angle(cam_angle),
    .out_ready(out_ready),
    .state_out(state));
  

  initial begin
        $dumpfile("gameplay.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,gameplay_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        new_game = 0; //initialize rst (super important)
        #10
        new_game = 1;
        #10
        new_game = 0;
        #10

        camera_pan_right = 1;
        charging_hit = 1;
        #10000000
        charging_hit = 0;
        #30000000    

        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule 