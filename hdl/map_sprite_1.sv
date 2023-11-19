`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module map_sprite_1 #(
  parameter WIDTH=160, HEIGHT=90) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] hcount_in,
  input wire [9:0]  vcount_in,
  input wire [7:0] ballx,
  input wire [6:0] bally,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );

  

  // calculate rom address
  logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
  logic [5:0] circle_addr;
  logic [7:0] pixelx;
  logic [6:0] pixely;
  logic [2:0] lox;
  logic [2:0] loy;
  assign pixelx = hcount_in/8;
  assign lox = hcount_in % 8;
  assign pixely = vcount_in/8;
  assign loy = vcount_in % 8;
  assign image_addr = pixelx + (pixely * WIDTH);
  logic isball;
  assign isball = (ballx == pixelx) & (bally == pixely);
  assign circle_addr = lox + loy*8;
  logic circle_out;


  





  logic [3:0] imageBROMout;
  logic [23:0] finalcolors;
  logic imagesprite_pipe [3:0];
  logic circleout_pipe [3:0];
  always_ff @(posedge pixel_clk_in)begin
    if(lox == 0 | lox == 7) begin
      if(loy == 0 | loy == 1 | loy == 6 | loy == 7 ) begin
        circleout_pipe[0] <= 0;
      end else begin
        circleout_pipe[0] <= 1;
      end 
    end else if(lox == 1|lox ==6) begin
      if(loy == 0 | loy == 7) begin
        circleout_pipe[0] <= 0;
      end else begin
        circleout_pipe[0] <= 1;
      end 
    end else begin
      circleout_pipe[0] <= 1;
    end
    imagesprite_pipe[0] <= isball;
    
    for (int i=1; i<4; i = i+1)begin
      imagesprite_pipe[i] <= imagesprite_pipe[i-1];
    end
    for (int j = 1;j<4;j=j+1) begin
      circleout_pipe[j] <= circleout_pipe[j-1];
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
  assign red_out =    imagesprite_pipe[3]==1?(circleout_pipe[3]==1?8'b11111111:finalcolors[23:16]):(finalcolors[23:16]==8'b00000000 ?(circleout_pipe[3] == 1?8'b00000000:8'b01111100):finalcolors[23:16]);
  assign green_out =  imagesprite_pipe[3]==1?(circleout_pipe[3]==1?8'b11111111:finalcolors[15:8]):(finalcolors[15:8]==8'b00000000 ?(circleout_pipe[3] == 1?8'b00000000:8'b11111100):finalcolors[15:8]);
  assign blue_out =   imagesprite_pipe[3]==1?(circleout_pipe[3]==1?8'b11111111:finalcolors[7:0]):(finalcolors[7:0]==8'b00000000 ?(circleout_pipe[3] == 1?8'b00000000:8'b00000000):finalcolors[7:0]);

endmodule






`default_nettype none
