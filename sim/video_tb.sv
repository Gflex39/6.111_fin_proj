// set the timestep on the internal simulation clock
`timescale 1ns / 1ps
`default_nettype none
 
//The timescale specifies the timestep size (1ns) and time resolution of rounding (1ps)
//we'll usually use 1ns/1ps in our class
 
module video_tb();
 
  //make inputs and outputs of appropriate size for the module testing:
  logic clk;
  logic[15:0] ballx_16=16'h40<<8;
  logic[15:0] bally_16=16'd10<<8;
  logic angle=0;
    logic [10:0] hcount;
  logic [9:0] vcount;




    map_sprite_3 #(
        .WIDTH(160),
        .HEIGHT(90))
        com_sprite_m (
        .pixel_clk_in(clk),
        // .rst_in(),
        .grass_color(24'heb4034),
        .ballx(ballx_16),
        .bally(bally_16),
        .angle(angle),
        .hcount_in(hcount),   //TODO: needs to use pipelined signal (PS1)
        .vcount_in(vcount)   //TODO: needs to use pipelined signal (PS1)
        // .red_out(img_red),
        // .green_out(img_green),
        // .blue_out(img_blue),
        );
//   map_sprite_3 demo(.tx(tx),.clk(clk),.data_out(data),.valid_out(valid));

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk = !clk;
  end
  //All simulations start with the the "initial block's top
  // They then run forward in order like regular code.
  //lines that are one after the other happen "instaneously together"
  //Time passes using the # notation. (#10 is 10 nanoseconds)
  // set the initial values of the module inputs
  initial begin
    $dumpfile("video_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,video_tb);
    $display("Starting Sim");
    clk=0;
    for (int j=0;j<720;j=j+1)begin
        for (int i=0;i<1280;i=i+1)begin
        hcount=i;
        vcount=j;

        #10;
        end
    //   $display("Sending first number");


    end




    $display("\n---------\nFinishing Simulation!");
    $finish; //finish simulation.
  end
endmodule // alu_tb