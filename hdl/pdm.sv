`timescale 1ns / 1ps
`default_nettype none


module pdm(
            input wire clk_in,
            input wire rst_in,
            input wire signed [7:0] level_in,
            input wire tick_in,
            output logic pdm_out
  );
  //your code here!
  logic signed [8:0] ff_out; 
  always_ff @(posedge clk_in) begin
    if(rst_in) begin
      ff_out <= 0;
    end
    else begin
      if(tick_in) begin
          ff_out <= level_in + ff_out - (ff_out[8]?-128:127);
          pdm_out <= ~ff_out[8];
        end
      end
    end
endmodule


`default_nettype wire