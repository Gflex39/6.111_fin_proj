`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module playback 
(
  input wire clk_in,
  input wire rst_in,
  input wire start_playback_bounce,
  input wire start_playback_hole,
  input wire signal_12khz,
  output logic signed [7:0] audio_out,
  output logic [31:0] debug_out
);
  parameter audio_len_bounce = 9600;
  parameter audio_len_hole = 65535;
  logic playing_back_bounce;
  logic playing_back_hole;
  logic [15:0] counter;
  logic signed [7:0] brom_out_bounce;
  logic signed [7:0] brom_out_hole;
  assign debug_out = (audio_out==0);
  always_ff @(posedge clk_in) begin
    if(rst_in) begin
      counter <= 0;
      audio_out <= 0;
      playing_back_bounce <= 0;
    end
    else begin
      if(start_playback_bounce && ~playing_back_bounce) begin 
        playing_back_bounce <= 1;
        counter <= 0;
      end
      else if(start_playback_hole && ~playing_back_hole) begin
        playing_back_hole <= 1;
        counter <= 0;
      end
      else if(playing_back_bounce) begin
        audio_out <= brom_out_bounce;
        if(signal_12khz) begin
          if(counter==audio_len_bounce-1) begin
            playing_back_bounce <= 0;
            counter <= 0;
          end
          else counter <= counter + 1;
        end
      end
      else if(playing_back_hole) begin
        audio_out <= brom_out_hole;
        if(signal_12khz) begin
          if(counter==audio_len_hole-1) begin
            playing_back_hole <= 0;
            counter <= 0;
          end
          else counter <= counter + 1;
        end
      end
      else audio_out <= 0;
    end

  end

  xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),                       // Specify RAM data width
        .RAM_DEPTH(9600),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(bounce.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) bram_ball_bounce (
        .addra(counter),     // Address bus, width determined from RAM_DEPTH
        .dina(8'b0),       // RAM input data, width determined from RAM_WIDTH
        .clka(clk_in),       // Clock
        .wea(1'b0),         // Write enable
        .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(rst_in),       // Output reset (does not affect memory contents)
        .regcea(1'b1),   // Output register enable
        .douta(brom_out_bounce)      // RAM output data, width determined from RAM_WIDTH
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),                       // Specify RAM data width
        .RAM_DEPTH(65536),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(hole.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) bram_ball_hole (
        .addra(counter),     // Address bus, width determined from RAM_DEPTH
        .dina(8'b0),       // RAM input data, width determined from RAM_WIDTH
        .clka(clk_in),       // Clock
        .wea(1'b0),         // Write enable
        .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(rst_in),       // Output reset (does not affect memory contents)
        .regcea(1'b1),   // Output register enable
        .douta(brom_out_hole)      // RAM output data, width determined from RAM_WIDTH
    );
endmodule
`default_nettype wire