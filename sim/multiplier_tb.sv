`timescale 1ns/1ps

module multiplier_tb;

  parameter WIDTH = 40;
  
  reg clk_in;
  reg [WIDTH-1 : 0] a_in, b_in;
  wire [2*WIDTH-1 : 0] y_out; 

  // response checking

  // DUT
  multiplier DUT (.clk_in(clk_in), .a(a_in), .b(b_in), .pdt(y_out));

  // stimulus
  initial
  begin
    $dumpfile("multiplier.vcd");
    $dumpvars(0, multiplier_tb);

    clk_in = 0;
    
    # 5 a_in = 1; b_in = 2;
    #10 a_in = 3; b_in = 4;
    #10 a_in = 5; b_in = 6;
    #10 a_in = 7; b_in = 8;
    #10 a_in = 9; b_in = 10;
    #10 a_in = 11; b_in = 12;
    
    #60 $finish;
  end
  
  always  
    #5  clk_in =  ! clk_in; 
  
endmodule
