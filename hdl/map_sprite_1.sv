`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module map_sprite_1 #(
  parameter WIDTH=128, HEIGHT=128) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] hcount_in,
  input wire [9:0]  vcount_in,
  input wire [6:0] ballx,
  input wire [6:0] bally,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );

  

  // calculate rom address
  logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
  logic [6:0] pixelx;
  logic [6:0] pixely;
  assign pixelx = hcount_in/10;
  assign pixely = 8*vcount_in/45;
  assign image_addr = pixelx + (pixely * WIDTH);
  logic isball;
  assign isball = (ballx == pixelx) & (bally == pixely);



  logic [3:0] imageBROMout;
  logic [23:0] finalcolors;
  logic imagesprite_pipe [3:0];

  always_ff @(posedge pixel_clk_in)begin
    imagesprite_pipe[0] <= isball;
    for (int i=1; i<4; i = i+1)begin
      imagesprite_pipe[i] <= imagesprite_pipe[i-1];
    end
  end




  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(4),                       // Specify RAM data width
    .RAM_DEPTH(WIDTH*HEIGHT),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(map1.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) imageBROM (
    .addra(image_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(imageBROMout)      // RAM output data, width determined from RAM_WIDTH
  );
  

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(24),                       // Specify RAM data width
    .RAM_DEPTH(3),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(palette.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) paletteBROM (
    .addra(imageBROMout),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(finalcolors)      // RAM output data, width determined from RAM_WIDTH
  );

  // Modify the module below to use your BRAMs!
  assign red_out =    imagesprite_pipe[3]==0?finalcolors[23:16]:8'b11111111;
  assign green_out =  imagesprite_pipe[3]==0?finalcolors[15:8]:8'b11111111;
  assign blue_out =   imagesprite_pipe[3]==0?finalcolors[7:0]:8'b11111111;
endmodule






`default_nettype none
