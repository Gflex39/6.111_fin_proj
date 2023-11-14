// set the timestep on the internal simulation clock
`timescale 1ns / 1ps
`default_nettype none
 
//The timescale specifies the timestep size (1ns) and time resolution of rounding (1ps)
//we'll usually use 1ns/1ps in our class
 
module uart_tb();
 
  //make inputs and outputs of appropriate size for the module testing:
  logic tx;
  logic [7:0] data;
  logic valid;
  logic clk;

  uart_rx demo(.tx(tx),.clk(clk),.data_out(data),.valid_out(valid));

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
    $dumpfile("uart_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,uart_tb);
    $display("Starting Sim");
    clk=0;
    for (int j=0;j<2;j=j+1)begin
      // $display("Sending first number");
      tx=1;
      #500;
      tx=0;
      #100;
      for(int i=0;i<8;i=i+1)begin
        tx=i;
        #100;
      end

    end
    tx=1;
     #60;



    $display("\n---------\nFinishing Simulation!");
    $finish; //finish simulation.
  end
endmodule // alu_tb