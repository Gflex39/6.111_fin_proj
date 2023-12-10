module multiplier #(WIDTH = 40, LEVEL = 6) (
  input wire clk_in,
  input wire [WIDTH-1:0] a,
  input wire [WIDTH-1:0] b,
  output logic [2*WIDTH-1:0] pdt
);
  /*
  * parameter 'WIDTH' is the width of multiplier/multiplicand;.Application Notes 10-5
  * parameter 'LEVEL' is the intended number of stages of the
  * pipelined multiplier;
  * which is typically the smallest integer greater than or equal
  * to base 2 logarithm of 'WIDTH'
  */

  reg [WIDTH-1 : 0] a_int, b_int;
  reg [2*WIDTH-1 : 0] pdt_int [LEVEL-1 : 0];
  integer i;

  assign pdt = pdt_int [LEVEL-1];

  always @ (posedge clk_in) begin

    // registering input of the multiplier
    a_int <= a;
    b_int <= b;

    // 'LEVEL' LEVELs of registers to be inferred at the output
    // of the multiplier
    pdt_int[0] <= a_int * b_int;
    for(i =1;i <LEVEL;i =i +1) begin
      pdt_int [i] <= pdt_int [i-1];
      //$display("pdt_int = %5d",pdt_int[i]);
    end

  end // always @ (posedge clk_in)
endmodule // pipelined_multiplier