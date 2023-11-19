`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module cos_sin_lookup
    (
        input wire clk_in,
        input wire [15:0] angle,
        output logic [15:0] cos_abs,
        output logic [15:0] sin_abs,

        // 1 for +, 0 for -
        output logic cos_sign,
        output logic sin_sign

    );


    always_comb begin
        if(angle<90) begin
            cos_sign = 1;
            sin_sign = 1;
        end else if (angle<180) begin
            cos_sign = 0;
            sin_sign = 1;
        end else if(angle<270) begin
            cos_sign = 0;
            sin_sign = 0;
        end else if(angle<360) begin
            cos_sign = 1;
            sin_sign = 0;
        end else begin // for edge cases like angle=360
            cos_sign = 1;
            sin_sign = 1;
        end

    end

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(16),                       // Specify RAM data width
        .RAM_DEPTH(361),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(cos_lookup.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) cos_lookup (
        .addra(angle[8:0]),     // Address bus, width determined from RAM_DEPTH
        .dina(16'b0),       // RAM input data, width determined from RAM_WIDTH
        .clka(clk_in),       // Clock
        .wea(1'b0),         // Write enable
        .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(1'b0),       // Output reset (does not affect memory contents)
        .regcea(1'b1),   // Output register enable
        .douta(cos_abs)      // RAM output data, width determined from RAM_WIDTH
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(16),                       // Specify RAM data width
        .RAM_DEPTH(361),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(sin_lookup.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) sin_lookup (
        .addra(angle[8:0]),     // Address bus, width determined from RAM_DEPTH
        .dina(16'b0),       // RAM input data, width determined from RAM_WIDTH
        .clka(clk_in),       // Clock
        .wea(1'b0),         // Write enable
        .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(1'b0),       // Output reset (does not affect memory contents)
        .regcea(1'b1),   // Output register enable
        .douta(sin_abs)      // RAM output data, width determined from RAM_WIDTH
    );

endmodule

`default_nettype wire