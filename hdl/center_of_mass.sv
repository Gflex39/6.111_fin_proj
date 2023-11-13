`timescale 1ns / 1ps
`default_nettype none

module center_of_mass (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire valid_in,
                         input wire tabulate_in,
                         output logic [10:0] x_out,
                         output logic [9:0] y_out,
                         output logic valid_out);
  logic [31:0] x_sum;
  logic [31:0] y_sum;
  logic [31:0] count;
  logic [31:0] x_final;
  logic [31:0] x_rem;
  logic [31:0] y_final;
  logic [31:0] y_rem;
  logic xbusy;
  logic xerror;
  logic xdone;
  logic ybusy;
  logic yerror;
  logic ydone;
  logic x_good;
  logic y_good;
  logic xfound;
  logic yfound;
  logic tabulating;
  logic calculating;


   
  always_ff @(posedge clk_in) begin
    if(rst_in)begin
      x_sum <=0;
      xfound <= 0;
      yfound <= 0;
      y_sum <= 0;
      count <= 0;
      valid_out <= 0;
      x_good <= 0;
      y_good <= 0;
      tabulating <= 0;
      calculating <= 0;
    end else begin
      if(tabulate_in == 0 & calculating == 0) begin
        tabulating <= 0;
        valid_out <= 0;
        if(valid_in) begin
          x_sum <= x_sum + x_in;
          y_sum <= y_sum + y_in;
          count <= count + 1;
        end
      end else begin
        if(xbusy) begin
          x_good <= 0;
        end if(ybusy) begin
          y_good <= 0;
        end if(xdone) begin
          if(xerror) begin
            x_good <= 0;
            calculating <= 0;
            valid_out <= 0;
          end else begin
            x_good <= 0;
            xfound <= 1;
            valid_out <= 0;
          end
        end if(ydone) begin
          if(yerror) begin
            y_good <= 0;
            calculating <= 0;
            valid_out <= 0;
          end else begin
            y_good <= 0;
            yfound <= 1;
            valid_out <= 0;
          end
        end if(xfound & yfound) begin
          valid_out <= 1;
          x_out <= x_final;
          y_out <= y_final;
          x_sum <= 0;
          y_sum <= 0;
          count <= 0;
          x_good <= 0;
          y_good <= 0;
          xfound <= 0;
          yfound <= 0;
          calculating <= 0;
        end else begin
          valid_out <= 0;
        end if(tabulating == 0 & tabulate_in == 1) begin
          if(count == 0) begin
            valid_out <= 0;
          end else begin
            calculating <= 1;
            x_good <= 1;
            valid_out <= 0;
            y_good <= 1;
            tabulating <= 1;
          end
        end 
      end
    end
  end
  divider #(
        .WIDTH(32))
        xdivide(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(x_sum),
        .divisor_in(count),
        .data_valid_in(x_good),
        .quotient_out(x_final),
        .remainder_out(x_rem),
        .data_valid_out(xdone),
        .error_out(xerror),
        .busy_out(xbusy)
      );

  divider #(
        .WIDTH(32))
        ydivide(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(y_sum),
        .divisor_in(count),
        .data_valid_in(y_good),
        .quotient_out(y_final),
        .remainder_out(y_rem),
        .data_valid_out(ydone),
        .error_out(yerror),
        .busy_out(ybusy)
      );


endmodule


`default_nettype wire
