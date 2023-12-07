// set the timestep on the internal simulation clock
`timescale 1ns / 1ps
`default_nettype none

 
//The timescale specifies the timestep size (1ns) and time resolution of rounding (1ps)
//we'll usually use 1ns/1ps in our class
 
module playback_tb();
 
  //make inputs and outputs of appropriate size for the module testing:
  logic clk_in;
  logic new_game;
  logic start_playback;
  logic signal_12khz;
  logic [7:0] audio_out;
  
  always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
  end

  always begin
    signal_12khz = 1;
    #10;
    signal_12khz = 0;
    #83323;
  end
 
  //create an instance of the module. UUT= unit under test, but call it whatever:
  //always use named port convention when declaring (it is much easier to protect from bugs)
  playback my_playback (
    .clk_in(clk_in),
    .rst_in(new_game),
    .start_playback(start_playback),
    .signal_12khz(signal_12khz),
    .audio_out(audio_out)
  );
  

  initial begin
        $dumpfile("playback.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,playback_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        new_game = 0; //initialize rst (super important)
        #10
        new_game = 1;
        #10
        new_game = 0;
        #10
        start_playback = 1;
        #10
        start_playback = 0;
        #1000000

        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule 