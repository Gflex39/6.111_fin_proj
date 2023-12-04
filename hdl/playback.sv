`timescale 1ns / 1ps
`default_nettype none

module playback 
(
  input wire clk_in,
  input wire rst_in,
  input wire start_playback,
  input wire signal_12khz,
  output logic signed [7:0] audio_out
);
  parameter audio_len = 19200;
  logic playing_back;
  logic [15:0] counter;
  always_ff @(posedge clk_in) begin
    if(rst_in) begin
      counter <= 0;
      audio_out <= 0;
      playing_back <= 0;
    end
    else begin
      if(start_playback && ~playing_back) begin 
        playing_back <= 1;
        counter <= 0;
      end
      if(playing_back) begin
        if(signal_12khz) begin
          if(counter==audio_len-1) begin
            playing_back <= 0;
            counter <= 0;
          end
          else counter <= counter + 1;
        end
      end
    end

  end

  xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),                       // Specify RAM data width
        .RAM_DEPTH(65536),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(bounce.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) bram_ball (
        .addra(counter),     // Address bus, width determined from RAM_DEPTH
        .dina(8'b0),       // RAM input data, width determined from RAM_WIDTH
        .clka(clk_in),       // Clock
        .wea(1'b0),         // Write enable
        .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(rst_in),       // Output reset (does not affect memory contents)
        .regcea(1'b1),   // Output register enable
        .douta(audio_out)      // RAM output data, width determined from RAM_WIDTH
    );
endmodule
`default_nettype wire