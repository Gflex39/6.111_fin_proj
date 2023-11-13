`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

/**
    This module, given an input x_in and y_in for the position of a 1x1 ball sprite,
    outputs the nearest integral x,y for the center, and the 4 sides (r,l,u,d) of the sprite. 
    All inputs and outputs are represented as 16-bit fixed-point numbers, 8 before the decimal point and 8 after.
**/
module rounder 
    (
        input wire [15:0] x_in,
        input wire [15:0] y_in,
        output logic [15:0] x_out_c,
        output logic [15:0] x_out_r,
        output logic [15:0] x_out_l,
        output logic [15:0] y_out_c,
        output logic [15:0] y_out_u,
        output logic [15:0] y_out_d
    );

    logic [7:0] x;
    logic [7:0] y;

    assign x = x_in[15:8]+1;
    assign y = y_in[15:8]+1;

    always_comb begin
        if(x_in[7]) x_out_c = {x, 8'b00000000};
        else x_out_c = {x_in[15:8], 8'b00000000};
        x_out_r = {x, 8'b00000000};
        x_out_l = {x_in[15:8], 8'b00000000};

        if(y_in[7]) y_out_c = {y, 8'b00000000};
        else y_out_c = {y_in[15:8], 8'b00000000};
        y_out_u = {y, 8'b00000000};
        y_out_d = {y_in[15:8], 8'b00000000};
    end
endmodule

`default_nettype wire