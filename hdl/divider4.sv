`timescale 1ns / 1ps
`default_nettype none

module divider4 #(parameter WIDTH = 40) (input wire clk_in,
                input wire rst_in,
                input wire[WIDTH-1:0] dividend_in,
                input wire[WIDTH-1:0] divisor_in,
                input wire data_valid_in,
                output logic[WIDTH-1:0] quotient_out,
                output logic data_valid_out);

  logic [39:0] p[39:0]; //40 stages
  logic [39:0] dividend [39:0];
  logic [39:0] divisor [39:0];
  logic data_valid [39:0];

  assign data_valid_out = data_valid[39];
  assign quotient_out = dividend[39];

  always @(*) begin
    data_valid[0] = data_valid_in;
    divisor[0] = divisor_in;
    if (data_valid_in)begin
      if ({39'b0,dividend_in[39]}>=divisor_in[39:0])begin
        p[0] = {39'b0,dividend_in[39]} - divisor_in[39:0];
        dividend[0] = {dividend_in[38:0],1'b1};
      end else begin
        p[0] = {39'b0,dividend_in[39]};
        dividend[0] = {dividend_in[38:0],1'b0};
      end
    end
    for (int i=2; i<40; i=i+2)begin
      data_valid[i] = data_valid[i-1];
      if ({p[i-1][38:0],dividend[i-1][39]}>=divisor[i-1][39:0])begin
        p[i] = {p[i-1][38:0],dividend[i-1][39]} - divisor[i-1][39:0];
        dividend[i] = {dividend[i-1][38:0],1'b1};
      end else begin
        p[i] = {p[i-1][38:0],dividend[i-1][39]};
        dividend[i] = {dividend[i-1][38:0],1'b0};
      end
      divisor[i] = divisor[i-1];
    end
  end

  always_ff @(posedge clk_in)begin
    for (int i=1; i<40; i=i+2)begin
      data_valid[i] <= data_valid[i-1];
      if ({p[i-1][38:0],dividend[i-1][39]}>=divisor[i-1][39:0])begin
        p[i] <= {p[i-1][38:0],dividend[i-1][39]} - divisor[i-1][39:0];
        dividend[i] <= {dividend[i-1][38:0],1'b1};
      end else begin
        p[i] <= {p[i-1][38:0],dividend[i-1][39]};
        dividend[i] <= {dividend[i-1][38:0],1'b0};
      end
      divisor[i] <= divisor[i-1];
    end
  end
endmodule

`default_nettype wire
