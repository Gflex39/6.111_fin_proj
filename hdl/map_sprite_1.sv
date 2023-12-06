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
  input wire [15:0] ballx,
  input wire [15:0] bally,
  input wire [15:0] angle,
  input wire grass_color,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );

  logic [15:0] cos_abs;
  logic [15:0] sin_abs;
  logic cos_sign;
  logic sin_sign;

  cos_sin_lookup angle_lookup (
        .clk_in(pixel_clk_in),
        .angle(angle),
        .cos_abs(cos_abs),
        .sin_abs(sin_abs),
        .cos_sign(cos_sign),
        .sin_sign(sin_sign)
    );

  logic [10:0] angle30_pipe_h [1:0];
  logic [10:0] angle60_pipe_h [1:0];
  logic [10:0] angle90_pipe_h [1:0];
  logic [9:0] angle30_pipe_v [1:0];
  logic [9:0] angle60_pipe_v [1:0];
  logic [9:0] angle90_pipe_v [1:0];

  logic [9:0] vcount_pipe [1:0];
  logic [10:0] hcount_pipe [1:0];

  

  // calculate rom address
  logic [10:0] ballposx;
  logic [9:0] ballposy;
  logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
  logic [7:0] pixelx;
  logic [6:0] pixely;
  logic [2:0] balllox;
  logic [2:0] ballloy;
  logic [2:0] lox;
  logic [2:0] loy;
  assign ballposx = ballx[15:5];
  assign ballposy = bally[14:5];
  
  logic [15:0] temp_balllox;
  assign temp_balllox = (hcount_in-ballposx+3);
  assign balllox = temp_balllox[2:0];

  logic [15:0] temp_ballloy;
  assign temp_ballloy = (vcount_in-ballposy+3);
  assign ballloy = temp_ballloy[2:0];

  assign pixelx = hcount_in>>3;
  assign lox = hcount_in[2:0];
  assign pixely = vcount_in>>3;
  assign loy = vcount_in[2:0];
  assign image_addr = pixelx + (pixely * WIDTH);
  logic isball;
  assign isball = (ballposx-3 <= hcount_in & ballposx+4 >= hcount_in) & (ballposy-3 <= vcount_in & ballposy+4 >= vcount_in);



  





  logic [3:0] imageBROMout;
  logic [23:0] finalcolors;
  logic imagesprite_pipe [1:0];
  logic circleout_pipe [1:0];
  logic ballout_pipe [1:0];
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

    if(balllox == 0 | balllox == 7) begin
      if(ballloy == 0 | ballloy == 1 | ballloy == 6 | ballloy == 7 ) begin
        ballout_pipe[0] <= 0;
      end else begin
        ballout_pipe[0] <= 1;
      end 
    end else if(balllox == 1|balllox ==6) begin
      if(ballloy == 0 | ballloy == 7) begin
        ballout_pipe[0] <= 0;
      end else begin
        ballout_pipe[0] <= 1;
      end 
    end else begin
      ballout_pipe[0] <= 1;
    end


    imagesprite_pipe[0] <= isball;
    hcount_pipe[0] <= hcount_in;
    vcount_pipe[0] <= vcount_in;

    angle30_pipe_h[0] <= ballposx;
    angle60_pipe_h[0] <= ballposx;
    angle90_pipe_h[0] <= ballposx;
    angle30_pipe_v[0] <= ballposy+1;
    angle60_pipe_v[0] <= ballposy+1;
    angle90_pipe_v[0] <= ballposy+1;

    // angle30_pipe_h[1] <= angle30_pipe_h[0];
    // angle60_pipe_h[1] <= angle60_pipe_h[0];
    // angle90_pipe_h[1] <= angle90_pipe_h[0];
    // angle30_pipe_v[1] <= angle30_pipe_v[0];
    // angle60_pipe_v[1] <= angle60_pipe_v[0];
    // angle90_pipe_v[1] <= angle90_pipe_v[0];

    angle30_pipe_h[1] <= angle30_pipe_h[0]-(cos_sign==0?((30*cos_abs)>>8)-1:0)+(cos_sign==1?((30*cos_abs)>>8):0);
    angle60_pipe_h[1] <= angle60_pipe_h[0]-(cos_sign==0?((60*cos_abs)>>8)-1:0)+(cos_sign==1?((60*cos_abs)>>8):0);
    angle90_pipe_h[1] <= angle90_pipe_h[0]-(cos_sign==0?((90*cos_abs)>>8)-1:0)+(cos_sign==1?((90*cos_abs)>>8):0);

    angle30_pipe_v[1] <= angle30_pipe_v[0]+(sin_sign==0?((30*sin_abs)>>8)-1:0)-(sin_sign==1?((30*sin_abs)>>8):0);
    angle60_pipe_v[1] <= angle60_pipe_v[0]+(sin_sign==0?((60*sin_abs)>>8)-1:0)-(sin_sign==1?((60*sin_abs)>>8):0);
    angle90_pipe_v[1] <= angle90_pipe_v[0]+(sin_sign==0?((90*sin_abs)>>8)-1:0)-(sin_sign==1?((90*sin_abs)>>8):0);



    // angle30_pipe_h[3] <= angle30_pipe_h[2];
    // angle60_pipe_h[3] <= angle60_pipe_h[2];
    // angle90_pipe_h[3] <= angle90_pipe_h[2];
    // angle30_pipe_v[3] <= angle30_pipe_v[2];
    // angle60_pipe_v[3] <= angle60_pipe_v[2];
    // angle90_pipe_v[3] <= angle90_pipe_v[2];
    for (int i=1; i<2; i = i+1)begin
      imagesprite_pipe[i] <= imagesprite_pipe[i-1];
      hcount_pipe[i] <= hcount_pipe[i-1];
    end
    for (int j = 1;j<2; j=j+1) begin
      circleout_pipe[j] <= circleout_pipe[j-1];
      ballout_pipe[j] <= ballout_pipe[j-1];
      vcount_pipe[j] <= vcount_pipe[j-1];
    end
  end




  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(4),                       // Specify RAM data width
    .RAM_DEPTH(WIDTH*HEIGHT),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(map2.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
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
  
  always_comb begin
    case(imageBROMout) 
      0: finalcolors = 24'h000000;
      1: finalcolors = 24'h8B4F39;
      2: finalcolors = grass_color?24'h7CFC00:24'h73DE0B;
      3: finalcolors = grass_color?24'h9C972C:24'hB0AA28;
      4: finalcolors = grass_color?24'h7CFC00:24'h73DE0B;
      5: finalcolors = grass_color?24'h9C972C:24'hB0AA28;
      6: finalcolors = grass_color?24'h7CFC00:24'h73DE0B;
      7: finalcolors = grass_color?24'h9C972C:24'hB0AA28;
      8: finalcolors = grass_color?24'h7CFC00:24'h73DE0B;
      9: finalcolors = grass_color?24'h9C972C:24'hB0AA28;
      10: finalcolors = grass_color?24'h7CFC00:24'h73DE0B;
      11: finalcolors = grass_color?24'h9C972C:24'hB0AA28;
      
    endcase

  end

  // xilinx_single_port_ram_read_first #(
  //   .RAM_WIDTH(24),                       // Specify RAM data width
  //   .RAM_DEPTH(4),                     // Specify RAM depth (number of entries)
  //   .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
  //   .INIT_FILE(`FPATH(palette.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  // ) paletteBROM (
  //   .addra(imageBROMout),     // Address bus, width determined from RAM_DEPTH
  //   .dina(0),       // RAM input data, width determined from RAM_WIDTH
  //   .clka(pixel_clk_in),       // Clock
  //   .wea(0),         // Write enable
  //   .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
  //   .rsta(rst_in),       // Output reset (does not affect memory contents)
  //   .regcea(1),   // Output register enable
  //   .douta(finalcolors)      // RAM output data, width determined from RAM_WIDTH
  // );

  logic allow=(imageBROMout<4||((imageBROMout==4 || imageBROMout==5) && (7-hcount_pipe[1][2:0]>=vcount_pipe[1][2:0]))||((imageBROMout==6 || imageBROMout==7) && (hcount_pipe[1][2:0]+1<vcount_pipe[1][2:0]))||((imageBROMout==8 || imageBROMout==9) && (6-hcount_pipe[1][2:0]<vcount_pipe[1][2:0]))||((imageBROMout==10 || imageBROMout==11) && (hcount_pipe[1][2:0]+1>vcount_pipe[1][2:0])));
  // logic allow=1;
  logic [23:0] wall=24'h8B4F39;
  // Modify the module below to use your BRAMs!
  assign red_out =    ((vcount_pipe[1] == angle30_pipe_v[1] & hcount_pipe[1] == angle30_pipe_h[1])|(vcount_pipe[1] == angle60_pipe_v[1] & hcount_pipe[1] == angle60_pipe_h[1])|(vcount_pipe[1] == angle90_pipe_v[1] & hcount_pipe[1] == angle90_pipe_h[1]))?8'b00000000:(imagesprite_pipe[1]==1?(ballout_pipe[1]==1?8'b11111111:finalcolors[23:16]):(finalcolors[23:16]==8'b00000000 ?(circleout_pipe[1] == 1?8'b00000000:8'b01111100):(allow)?finalcolors[23:16]:wall[23:16]));
  assign green_out =  ((vcount_pipe[1] == angle30_pipe_v[1] & hcount_pipe[1] == angle30_pipe_h[1])|(vcount_pipe[1] == angle60_pipe_v[1] & hcount_pipe[1] == angle60_pipe_h[1])|(vcount_pipe[1] == angle90_pipe_v[1] & hcount_pipe[1] == angle90_pipe_h[1]))?8'b00000000:(imagesprite_pipe[1]==1?(ballout_pipe[1]==1?8'b11111111:finalcolors[15:8]):(finalcolors[15:8]==8'b00000000 ?(circleout_pipe[1] == 1?8'b00000000:8'b11111100):(allow)?finalcolors[15:8]:wall[15:8]));
  assign blue_out =   ((vcount_pipe[1] == angle30_pipe_v[1] & hcount_pipe[1] == angle30_pipe_h[1])|(vcount_pipe[1] == angle60_pipe_v[1] & hcount_pipe[1] == angle60_pipe_h[1])|(vcount_pipe[1] == angle90_pipe_v[1] & hcount_pipe[1] == angle90_pipe_h[1]))?8'b11111111:(imagesprite_pipe[1]==1?(ballout_pipe[1]==1?8'b11111111:finalcolors[7:0]):(finalcolors[7:0]==8'b00000000 ?(circleout_pipe[1] == 1?8'b00000000:8'b00000000):(allow)?finalcolors[7:0]:wall[7:0]));
  // assign red_out =    (imagesprite_pipe[3]==1?(8'b11111111):finalcolors[23:16]);
  // assign green_out =  (imagesprite_pipe[3]==1?(8'b11111111):(finalcolors[15:8]));
  // assign blue_out =   (imagesprite_pipe[3]==1?(8'b11111111):finalcolors[7:0]);
endmodule






`default_nettype none