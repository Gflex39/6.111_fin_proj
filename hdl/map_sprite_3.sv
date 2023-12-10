

`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module map_sprite_3 #(
  parameter WIDTH=160, HEIGHT=90,BORDER=16'b1101_1111_0000_0000) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] hcount_in,
  input wire [9:0]  vcount_in,
  input wire [15:0] ballx,
  input wire [15:0] bally,
  input wire [15:0] angle, 
  input wire [3:0] change,

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

  logic [23:0] camera_pos_x;
  logic [23:0] camera_pos_y;
  logic [23:0] near_depth;
  logic [23:0] far_depth;
  logic [23:0] ball_depth;
  assign near_depth = 0;
  assign ball_depth = 15+near_depth;
  assign far_depth = 63;

  logic [23:0] temp_ballposx;
  logic [23:0] temp_ballposy;

  assign temp_ballposx = {4'b0,ballx,4'b0}+({4'b0,BORDER,4'b0});
  assign temp_ballposy = {4'b0,bally,4'b0}+({4'b0,BORDER,4'b0});

  logic [23:0] ballpospipe_x [1:0];
  logic [23:0] ballpospipe_y [1:0];
  always_ff @(posedge pixel_clk_in)begin
    ballpospipe_x[0] <= temp_ballposx;
    ballpospipe_x[1] <= ballpospipe_x[0];
    ballpospipe_y[0] <= temp_ballposy;
    ballpospipe_y[1] <= ballpospipe_y[0];
    hcount_pipe[0]  <= hcount_in;
    hcount_pipe[1]  <= hcount_pipe[0];
    vcount_pipe[0]  <= vcount_in;
    vcount_pipe[1]  <= vcount_pipe[0];




    hcount_pipe[2]  <= hcount_pipe[1];

    vcount_pipe[2]  <= vcount_pipe[1];
    hcount_pipe[3]  <= hcount_pipe[2];

    vcount_pipe[3]  <= vcount_pipe[2];
  end

  logic [23:0] ballposx;
  logic [23:0] ballposy;

  assign ballposx = ballpospipe_x[1];
  assign ballposy = ballpospipe_y[1];

  assign camera_pos_x = ballposx+(cos_sign_ang==0?(((ball_depth)*(cos_abs_ang<<4))):0)-(cos_sign_ang==1?(((ball_depth)*(cos_abs_ang<<4))):0);
  assign camera_pos_y = ballposy-(sin_sign_ang==0?((ball_depth*(sin_abs_ang<<4))):0)+(sin_sign_ang==1?((ball_depth*(sin_abs_ang<<4))):0);
  logic [19:0] near_mag;
  initial near_mag = 16'b0; //16'b0000_0101_0011_1010; // fixed point
  logic [19:0] far_mag;
  // assign far_mag = 16'b0010_1000; //16'b0110_1101_1101_0110;
  initial far_mag = 16'b0001_0001;
  logic[31:0] far_count;

  always_ff @(posedge pixel_clk_in ) begin 
    if(rst_in)begin
      far_mag <= 16'b0001_0001;
      far_count<=0;

    end else begin
    if(change[0])begin 
      
      if(far_count==100000 && far_mag < 16'b1111_1111)begin
        far_mag<=far_mag+1;
        far_count<=0;
      end else far_count<=far_count+1;
      
    end
    else if(change[1])begin
        if(far_count==100000 && far_mag > near_mag)begin
        far_mag<=far_mag-1;
        far_count<=0;
      end else far_count<=far_count+1;
    end
    else far_count<=0;
    end
 
  end

  logic[31:0] near_count;

  always_ff @(posedge pixel_clk_in ) begin 
    if(rst_in)begin
      near_mag <= 16'b0000_0000;
      

    end else begin
    if(change[2])begin 
      
      if(near_count==100000 && near_mag < far_mag)begin
        near_mag<=near_mag+1;
        near_count<=0;
      end else near_count<=near_count+1;
      
    end
    else if(change[3])begin
        if(near_count==100000 && near_mag > 16'b0000_0000)begin
        near_mag<=near_mag-1;
        near_count<=0;
      end else near_count<=near_count+1;
    end
    else near_count<=0;
    end
 
  end











  assign debug_out={ballx,bally};//{camera_pos_x,camera_pos_y};
  logic [23:0] farl_x;
  logic [23:0] farl_y;
  logic [23:0] farr_x;
  logic [23:0] farr_y;
  logic [23:0] nearl_x;
  logic [23:0] nearl_y;
  logic [23:0] nearr_x;
  logic [23:0] nearr_y;


//Doesnt need to be shifted because the cos_abs is already in fixes point while far_mag is not, this is good
  logic  [23:0] farl_x_helper;
  assign farl_x_helper = far_mag*(cos_abs_lang<<4);
  logic  [23:0] farl_y_helper;
  assign farl_y_helper = far_mag*(sin_abs_lang<<4);
  logic  [23:0] farr_x_helper;
  assign farr_x_helper = far_mag*(cos_abs_rang<<4);
  logic  [23:0] farr_y_helper;
  assign farr_y_helper = far_mag*(sin_abs_rang<<4);
  logic  [23:0] nearl_x_helper;
  assign nearl_x_helper = near_mag*(cos_abs_lang<<4);
  logic  [23:0] nearl_y_helper;
  assign nearl_y_helper = near_mag*(sin_abs_lang<<4);
  logic  [23:0] nearr_x_helper;
  assign nearr_x_helper = near_mag*(cos_abs_rang<<4);
  logic  [23:0] nearr_y_helper;
  assign nearr_y_helper = near_mag*(sin_abs_rang<<4);


  //Same thing as before one is shifted one is not making the outcome shifted
  assign farl_x = camera_pos_x-(cos_sign_lang==0?(farl_x_helper):0)+(cos_sign_lang==1?(farl_x_helper ):0);
  assign farl_y = camera_pos_y +(sin_sign_lang==0?(farl_y_helper ):0)-(sin_sign_lang==1?(farl_y_helper ):0);
  assign farr_x = camera_pos_x -(cos_sign_rang==0?(farr_x_helper ):0)+(cos_sign_rang==1?(farr_x_helper ):0);
  assign farr_y = camera_pos_y +(sin_sign_rang==0?(farr_y_helper ):0)-(sin_sign_rang==1?(farr_y_helper ):0);
  assign nearl_x = camera_pos_x -(cos_sign_lang==0?(nearl_x_helper ):0)+(cos_sign_lang==1?(nearl_x_helper ):0);
  assign nearl_y = camera_pos_y +(sin_sign_lang==0?(nearl_y_helper ):0)-(sin_sign_lang==1?(nearl_y_helper ):0);
  assign nearr_x = camera_pos_x -(cos_sign_rang==0?(nearr_x_helper ):0)+(cos_sign_rang==1?(nearr_x_helper ):0);
  assign nearr_y = camera_pos_y +(sin_sign_rang==0?(nearr_y_helper ):0)-(sin_sign_rang==1?(nearr_y_helper ):0);

  logic [10:0] hcount;
  assign hcount = hcount_pipe[1];
  logic [9:0] vcount;
  assign vcount = vcount_pipe[1];


  // fixed point; 16 decimal points
  logic [39:0] pos_x_32;
  logic [39:0] pos_y_32;
  logic [39:0] pos_x;
  logic [39:0] pos_y;
  
  logic [39:0] sidel_x;
  logic [39:0] sidel_y;
  logic [39:0] sider_x;
  logic [39:0] sider_y;
  


  // logic[39:0] poo;

  // logic [39:0] l;
  // assign l =(farl_x)*(32'b101101000<<16)/((vcount<<16)-(32'b101101000<<16));
  // logic [39:0] plo;
  
  
  // logic [39:0] k;


  // logic [39:0] f;
  // assign plo=(32'b101101000<<20)/((vcount<<12)-(32'b101101000<<12));
  // assign k  =(sidel_x>>16)*(1280-hcount)*8'b0011_0011;


  //  assign bj=((sider_x)>>16)*(hcount)*8'b0011_0011;
  // assign f  =(sider_x)>>16;

  logic [39:0] bj;
 


  logic [23:0] tfarl_x [41:0]; 
  logic [23:0] tfarl_y [41:0];
  logic [23:0] tfarr_x [41:0];
  logic [23:0] tfarr_y [41:0];
  logic [23:0] tnearl_x [41:0];
  logic [23:0] tnearl_y [41:0];
  logic [23:0] tnearr_x [41:0];
  logic [23:0] tnearr_y [41:0];
  logic [10:0] hcounter_pipe [41:0];
  logic [9:0] vcounter_pipe [41:0];

  always_ff @( posedge pixel_clk_in) begin 
    multiplier1 <= multiplier;
    hcounter_pipe[0] <= hcount;
    vcounter_pipe[0] <= vcount;
    tfarl_x[0]<=farl_x;
    tfarl_y[0]<=farl_y;
    tfarr_x[0]<=farr_x;
    tfarr_y[0]<=farr_y;
    tnearl_x[0]<=nearl_x;
    tnearl_y[0]<=nearl_y;
    tnearr_x[0]<=nearr_x;
    tnearr_y[0]<=nearr_y;
    for (int i=1; i<42; i = i+1)begin
      hcounter_pipe[i] <= hcounter_pipe[i-1];
      vcounter_pipe[i] <= vcounter_pipe[i-1];
      tfarl_x[i]<=tfarl_x[i-1];
      tfarl_y[i]<=tfarl_y[i-1];
      tfarr_x[i]<=tfarr_x[i-1];
      tfarr_y[i]<=tfarr_y[i-1];
      tnearl_x[i]<=tnearl_x[i-1];
      tnearl_y[i]<=tnearl_y[i-1];
      tnearr_x[i]<=tnearr_x[i-1];
      tnearr_y[i]<=tnearr_y[i-1];
    end
  end

  logic valid_division;
  logic [39:0] multiplier;
  logic [39:0] scale=32'd360;
  logic [39:0] multiplier1;
  
  divider4 #(.WIDTH(40)) depth_calc (
        .clk_in(pixel_clk_in),
        .rst_in(rst_in),
        .dividend_in(((32'd720-scale)<<20)),
        .divisor_in(((vcount<<12)-(scale<<12))),
        .data_valid_in(1),
        .quotient_out(multiplier),
        .data_valid_out(valid_division)
    );


  
  logic sky;
  assign sky = vcounter_pipe[39] <= scale;

  // logic [39:0] sidelx_pipe [3:0];
  // logic [39:0] sidely_pipe [3:0];
  // logic [39:0] siderx_pipe [3:0];
  // logic [39:0] sidery_pipe [3:0];

  // always_ff @( posedge pixel_clk_in) begin
  //   sidelx_pipe[0] <= multiplier*tfarl_x[39];
  //   sidely_pipe[0] <= multiplier*tfarl_y[39];
  //   siderx_pipe[0] <= multiplier*tfarr_x[39];
  //   sidery_pipe[0] <= multiplier*tfarr_y[39];
  //   sidelx_pipe[1] <= sidelx_pipe[0]+nearl_x;
  //   sidely_pipe[1] <= multiplier*tfarl_y[39];
  //   siderx_pipe[1] <= multiplier*tfarr_x[39];
  //   sidery_pipe[1] <= multiplier*tfarr_y[39];
  // end



  assign sidel_x = (sky)?0:(multiplier*tfarl_x[39])-((multiplier-(1<<8))*tnearl_x[39]); //101101000 is 360
  assign sidel_y = (sky)?0:(multiplier*tfarl_y[39])-((multiplier-(1<<8))*tnearl_y[39]); //101101000 is 360
  assign sider_x = (sky)?0:(multiplier*tfarr_x[39])-((multiplier-(1<<8))*tnearr_x[39]); //101101000 is 360
  assign sider_y = (sky)?0:(multiplier*tfarr_y[39])-((multiplier-(1<<8))*tnearr_y[39]); //101101000 is 360


  logic [79:0] p1x;
  multiplier m1x (
    .clk_in(pixel_clk_in),
    .a((sider_x)>>16),
    .b(hcounter_pipe[39]),
    .pdt(p1x)
  );
  logic [79:0] p1y;
  multiplier m1y (
    .clk_in(pixel_clk_in),
    .a((sider_y)>>16),
    .b(hcounter_pipe[39]),
    .pdt(p1y)
  );
  logic [79:0] p2x;
  multiplier m2x (
    .clk_in(pixel_clk_in),
    .a((sidel_x)>>16),
    .b(1280-hcounter_pipe[39]),
    .pdt(p2x)
  );
  logic [79:0] p2y;
  multiplier m2y (
    .clk_in(pixel_clk_in),
    .a((sidel_y)>>16),
    .b(1280-hcounter_pipe[39]),
    .pdt(p2y)
  );
  assign pos_x_32 = (p1x*8'b0011_0011+p2x*8'b0011_0011);
  assign pos_y_32 = (p1y*8'b0011_0011+p2y*8'b0011_0011);
  //assign pos_x_32 = (((sider_x)>>16)*(hcounter_pipe[39])*8'b0011_0011+(sidel_x>>16)*(1280-hcounter_pipe[39])*8'b0011_0011);
  //assign pos_y_32 = (((sider_y)>>16)*(hcounter_pipe[39])*8'b0011_0011+((sidel_y)>>16)*(1280-hcounter_pipe[39])*8'b0011_0011);



  // assign sidel_x = (sky)?0:(((32'd720-scale)<<20)/((vcount_pipe[2]<<12)-(scale<<12))*tfarl_x)-((((32'd720-scale)<<20)/((vcount_pipe[2]<<12)-(scale<<12))-(1<<8))*tnearl_x); //101101000 is 360
  // assign sidel_y = (sky)?0:(((32'd720-scale)<<20)/((vcount_pipe[2]<<12)-(scale<<12))*tfarl_y)-((((32'd720-scale)<<20)/((vcount_pipe[2]<<12)-(scale<<12))-(1<<8))*tnearl_y); //101101000 is 360
  // assign sider_x = (sky)?0:(((32'd720-scale)<<20)/((vcount_pipe[2]<<12)-(scale<<12))*tfarr_x)-((((32'd720-scale)<<20)/((vcount_pipe[2]<<12)-(scale<<12))-(1<<8))*tnearr_x); //101101000 is 360
  // assign sider_y = (sky)?0:(((32'd720-scale)<<20)/((vcount_pipe[2]<<12)-(scale<<12))*tfarr_y)-((((32'd720-scale)<<20)/((vcount_pipe[2]<<12)-(scale<<12))-(1<<8))*tnearr_y);
  
  
  // logic [39:0] tsidel_x;
  // logic [39:0] tsidel_y;
  // logic [39:0] tsider_x;
  // logic [39:0] tsider_y;

  // always_ff @( posedge pixel_clk_in) begin 
  //   tsidel_x<=sidel_x;
  //   tsidel_y<=sidel_y;
  //   tsider_x<=sider_x;
  //   tsider_y<=sider_y;
  // end
  
  //  //101101000 is 360
  // assign pos_x_32 = (((tsider_x)>>16)*(hcount_pipe[3])*8'b0011_0011+(tsidel_x>>16)*(1280-hcount_pipe[3])*8'b0011_0011);
  // assign pos_y_32 = (((tsider_y)>>16)*(hcount_pipe[3])*8'b0011_0011+((tsidel_y)>>16)*(1280-hcount_pipe[3])*8'b0011_0011);






  // logic fi;
  // logic pi;
  // logic lo;
  // logic fl;

  // assign fi=(pos_x_32>={12'b0,BORDER,12'b0});
  // assign pi=(pos_x_32<={12'b0,BORDER,12'b0}+(160<<20));
  // assign lo=(pos_y_32>={12'b0,BORDER,12'b0});
  // assign fl= (pos_y_32<={12'b0,BORDER,12'b0}+(90<<20));


  assign pos_x = pos_x_32-{12'b0,BORDER,12'b0};
  assign pos_y = pos_y_32-{12'b0,BORDER,12'b0};

  logic onboard;
  assign onboard = (pos_x_32>={12'b0,BORDER,12'b0}) && (pos_x_32<={12'b0,BORDER,12'b0}+(160<<20))&&(pos_y_32>={12'b0,BORDER,12'b0})&&(pos_y_32<={12'b0,BORDER,12'b0}+(90<<20));
  logic [$clog2(160*90)-1:0] image_addr;
  logic [15:0] map_coord_x;
  logic [15:0] map_coord_y;
  assign map_coord_x = onboard?pos_x[27:12]+(1<<7):0;
  assign map_coord_y = onboard?pos_y[27:12]+(1<<7):0;
  assign image_addr = onboard?((map_coord_y>>8)*160+(map_coord_x>>8)):0;


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
    .INIT_FILE(`FPATH(map4.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
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
    .INIT_FILE(`FPATH(palette.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
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