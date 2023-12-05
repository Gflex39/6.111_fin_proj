

`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module map_sprite_3 #(
  parameter WIDTH=160, HEIGHT=90) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] hcount_in,
  input wire [9:0]  vcount_in,
  input wire [15:0] ballx,
  input wire [15:0] bally,
  input wire [15:0] angle, 
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out,
  output logic [31:0] debug_out
  );

  logic [9:0] vcount_pipe [3:0];
  logic [10:0] hcount_pipe [3:0];
  logic skypipe [3:0];
  logic onboard_pipe [3:0];
  logic [3:0] imageBROMout;
  logic [23:0] finalcolors;

  logic [15:0] halfcam;
  assign halfcam = 55;

  logic [15:0] cos_abs_ang;
  logic [15:0] sin_abs_ang;
  logic cos_sign_ang;
  logic sin_sign_ang;
  logic [15:0] cos_55;
  assign cos_55 = 16'b0000000010010010;

  cos_sin_lookup angle_lookp (
        .clk_in(pixel_clk_in),
        .angle(angle),
        .cos_abs(cos_abs_ang),
        .sin_abs(sin_abs_ang),
        .cos_sign(cos_sign_ang),
        .sin_sign(sin_sign_ang)
    );
  
  logic [15:0] rangle;
  assign rangle = (angle<halfcam)?angle+360-halfcam:angle-halfcam;
  logic [15:0] cos_abs_rang;
  logic [15:0] sin_abs_rang;
  logic cos_sign_rang;
  logic sin_sign_rang;

  cos_sin_lookup rangle_lookp (
        .clk_in(pixel_clk_in),
        .angle(rangle),
        .cos_abs(cos_abs_rang),
        .sin_abs(sin_abs_rang),
        .cos_sign(cos_sign_rang),
        .sin_sign(sin_sign_rang)
    );

  logic [15:0] langle;
  assign langle = (angle+halfcam>=360)?angle+halfcam-360:angle+halfcam;
  logic [15:0] cos_abs_lang;
  logic [15:0] sin_abs_lang;
  logic cos_sign_lang;
  logic sin_sign_lang;

  cos_sin_lookup langle_lookp (
        .clk_in(pixel_clk_in),
        .angle(langle),
        .cos_abs(cos_abs_lang),
        .sin_abs(sin_abs_lang),
        .cos_sign(cos_sign_lang),
        .sin_sign(sin_sign_lang)
    );  

  logic [15:0] camera_pos_x;
  logic [15:0] camera_pos_y;
  logic [15:0] near_depth;
  logic [15:0] far_depth;
  logic [15:0] ball_depth;
  assign near_depth = 3;
  assign ball_depth = 4+near_depth;
  assign far_depth = 600;

  logic [15:0] temp_ballposx;
  logic [15:0] temp_ballposy;

  // assign temp_ballposx = ballx[15:5]+720;
  // assign temp_ballposy = bally[15:5]+720;
  assign temp_ballposx = ballx[15:5]+6400;
  assign temp_ballposy = bally[15:5]+6400;

  logic [15:0] ballpospipe_x [1:0];
  logic [15:0] ballpospipe_y [1:0];
  always_ff @(posedge pixel_clk_in)begin
    ballpospipe_x[0] <= temp_ballposx;
    ballpospipe_x[1] <= ballpospipe_x[0];
    ballpospipe_y[0] <= temp_ballposy;
    ballpospipe_y[1] <= ballpospipe_y[0];
    hcount_pipe[0]  <= hcount_in;
    hcount_pipe[1]  <= hcount_pipe[0];
    vcount_pipe[0]  <= vcount_in;
    vcount_pipe[1]  <= vcount_pipe[0];
  end

  logic [15:0] ballposx;
  logic [15:0] ballposy;

  assign ballposx = ballpospipe_x[1];
  assign ballposy = ballpospipe_y[1];

  assign camera_pos_x = ballposx+(cos_sign_ang==0?((ball_depth*cos_abs_ang)>>5):0)-(cos_sign_ang==1?((ball_depth*cos_abs_ang)>>5):0);
  assign camera_pos_y = ballposy-(sin_sign_ang==0?((ball_depth*sin_abs_ang)>>5):0)+(sin_sign_ang==1?((ball_depth*sin_abs_ang)>>5):0);
  logic [31:0] near_mag;
  assign near_mag = 32'b0000_0000_0000_0000_0001_0000_0000_0000; //16'b0000_0101_0011_1010; // fixed point
  logic [31:0] far_mag;
  assign far_mag = 32'b0000_0000_0000_0100_0000_0000_0000_0000; //16'b0110_1101_1101_0110;
  assign debug_out=near_mag;//{camera_pos_x,camera_pos_y};
  logic [15:0] farl_x;
  logic [15:0] farl_y;
  logic [15:0] farr_x;
  logic [15:0] farr_y;
  logic [15:0] nearl_x;
  logic [15:0] nearl_y;
  logic [15:0] nearr_x;
  logic [15:0] nearr_y;

  logic [31:0] farl_x_helper;
  assign farl_x_helper = far_mag*cos_abs_lang;
  logic [31:0] farl_y_helper;
  assign farl_y_helper = far_mag*sin_abs_lang;
  logic [31:0] farr_x_helper;
  assign farr_x_helper = far_mag*cos_abs_rang;
  logic [31:0] farr_y_helper;
  assign farr_y_helper = far_mag*sin_abs_rang;
  logic [31:0] nearl_x_helper;
  assign nearl_x_helper = near_mag*cos_abs_lang;
  logic [31:0] nearl_y_helper;
  assign nearl_y_helper = near_mag*sin_abs_lang;
  logic [31:0] nearr_x_helper;
  assign nearr_x_helper = near_mag*cos_abs_rang;
  logic [31:0] nearr_y_helper;
  assign nearr_y_helper = near_mag*sin_abs_rang;


  assign farl_x = camera_pos_x-(cos_sign_lang==0?(farl_x_helper>>13):0)+(cos_sign_lang==1?(farl_x_helper>>13):0);
  assign farl_y = camera_pos_y+(sin_sign_lang==0?(farl_y_helper>>13):0)-(sin_sign_lang==1?(farl_y_helper>>13):0);
  assign farr_x = camera_pos_x-(cos_sign_rang==0?(farr_x_helper>>13):0)+(cos_sign_rang==1?(farr_x_helper>>13):0);
  assign farr_y = camera_pos_y+(sin_sign_rang==0?(farr_y_helper>>13):0)-(sin_sign_rang==1?(farr_y_helper>>13):0);
  assign nearl_x = camera_pos_x-(cos_sign_lang==0?(nearl_x_helper>>13):0)+(cos_sign_lang==1?(nearl_x_helper>>13):0);
  assign nearl_y = camera_pos_y+(sin_sign_lang==0?(nearl_y_helper>>13):0)-(sin_sign_lang==1?(nearl_y_helper>>13):0);
  assign nearr_x = camera_pos_x-(cos_sign_rang==0?(nearr_x_helper>>13):0)+(cos_sign_rang==1?(nearr_x_helper>>13):0);
  assign nearr_y = camera_pos_y+(sin_sign_rang==0?(nearr_y_helper>>13):0)-(sin_sign_rang==1?(nearr_y_helper>>13):0);

  logic [10:0] hcount;
  assign hcount = hcount_pipe[1];
  logic [9:0] vcount;
  assign vcount = vcount_pipe[1];

  logic sky;
  assign sky = vcount < 360;

  // fixed point; 16 decimal points
  logic [31:0] pos_x_32;
  logic [31:0] pos_y_32;
  logic [15:0] pos_x;
  logic [15:0] pos_y;
  
  logic [31:0] sidel_x;
  logic [31:0] sidel_y;
  logic [31:0] sider_x;
  logic [31:0] sider_y;
  


  // assign sidel_x = (sky)?0:((vcount - 360)*nearl_x + (719-vcount)*farl_x)*8'b1011_0110;
  // assign sidel_y = (sky)?0:((vcount - 360)*nearl_y + (719-vcount)*farl_y)*8'b1011_0110;
  // assign sider_x = (sky)?0:((vcount - 360)*nearr_x + (719-vcount)*farr_x)*8'b1011_0110;
  // assign sider_y = (sky)?0:((vcount - 360)*nearr_y + (719-vcount)*farr_y)*8'b1011_0110;
  logic [15:0] multiplier;
  assign multiplier = sky?0:1/(vcount-359);
  assign sidel_x = (sky)?0:(farl_x*multiplier + nearl_x - nearl_x*multiplier)<<16;
  assign sidel_y = (sky)?0:(farl_y*multiplier + nearl_y - nearl_y*multiplier)<<16;
  assign sider_x = (sky)?0:(farr_x*multiplier + nearr_x - nearr_x*multiplier)<<16;
  assign sider_y = (sky)?0:(farr_y*multiplier + nearr_y - nearr_y*multiplier)<<16;
  assign pos_x_32 = (sider_x>>16)*(hcount)*8'b0011_0011+(sidel_x>>16)*(1279-hcount)*8'b0011_0011;
  assign pos_y_32 = (sider_y>>16)*(hcount)*8'b0011_0011+(sidel_y>>16)*(1279-hcount)*8'b0011_0011;


  assign pos_x = pos_x_32>>16;
  assign pos_y = pos_y_32>>16;

  logic onboard;
  assign onboard = (pos_x>=6400) & (pos_x<=7680)&(pos_y>=6400)&(pos_y<=7120);
  // logic onboard;
  // assign onboard = (pos_x>=720) & (pos_x<=2000)&(pos_y>=720)&(pos_y<=1440);
  logic [$clog2(160*90)-1:0] image_addr;
  logic [12:0] map_coord_x;
  logic [12:0] map_coord_y;
  // assign map_coord_x = onboard?pos_x[15:3]-90:0;
  // assign map_coord_y = onboard?pos_y[15:3]-90:0;
  assign map_coord_x = onboard?pos_x[15:3]-800:0;
  assign map_coord_y = onboard?pos_y[15:3]-800:0;
  assign image_addr = onboard?(map_coord_y*160+map_coord_x):0;


  always_ff @(posedge pixel_clk_in)begin
    skypipe[0] <= sky;
    onboard_pipe[0] <= onboard;
    for (int i=1; i<4; i = i+1)begin
      skypipe[i] <= skypipe[i-1];
      onboard_pipe[i] <= onboard_pipe[i-1];
    end
  end


  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(4),                       // Specify RAM data width
    .RAM_DEPTH(WIDTH*HEIGHT),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(map2_copy.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) imageBRO (
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
    .RAM_DEPTH(4),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(palette_copy.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) paletteBRO (
    .addra(imageBROMout),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(finalcolors)      // RAM output data, width determined from RAM_WIDTH
  );
  assign red_out = skypipe[3]?8'b10000111:((onboard_pipe[3]==0)?8'b00000001:finalcolors[23:16]);
  assign green_out = skypipe[3]?8'b11001110:((onboard_pipe[3]==0)?8'b00110010:finalcolors[15:8]);
  assign blue_out = skypipe[3]?8'b11111010:((onboard_pipe[3]==0)?8'b00100000:finalcolors[7:0]);


endmodule






`default_nettype none