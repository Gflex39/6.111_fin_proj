`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz, //
  input wire ble_uart_tx,
  input wire ble_uart_rts,
  input wire [15:0] sw, //all 16 input slide switches
  input wire [3:0] btn, //all four momentary button switches
  output logic [2:0] hdmi_tx_p, //hdmi output signals (blue, green, red)
  output logic [2:0] hdmi_tx_n, //hdmi output signals (negatives)
  output logic hdmi_clk_p, hdmi_clk_n, //differential hdmi clock
  output logic [3:0] ss0_an,//anode control for upper four digits of seven-seg display
  output logic [3:0] ss1_an,//anode control for lower four digits of seven-seg display
  output logic [6:0] ss0_c, //cathode controls for the segments of upper four digits
  output logic [6:0] ss1_c,//cathod controls for the segments of lower four digits
  output logic ble_uart_cts,
  output logic ble_uart_rx,
  output logic spkl, spkr
  );






  /* have btnd control system reset */


  //Clocking Variables:
  logic clk_pixel, clk_5x; //clock lines
  logic locked; //locked signal (we'll leave unused but still hook it up)
  logic top;
  assign top = sw[0];

  logic [31:0] debug_var;
  logic sys_rst;
  assign sys_rst = btn[0];
  assign ble_uart_cts=1;
  logic [7:0] data;
  logic [6:0] ss_c;
  logic new_input;

  logic clk_slow;
  logic [2:0] counter_clk;

  always_ff @(posedge clk_pixel) begin
    if(sys_rst) begin
      clk_slow <= 0;
      counter_clk <= 0;
    end
    else begin
      if(counter_clk==3) begin
        clk_slow <= 1;
        counter_clk <= 0;
      end
      else begin
        clk_slow <= 0;
        counter_clk <= counter_clk + 1;
      end
    end
  end

  // seven_segment_controller mssc(.clk_in(clk_pixel),
  //                                 .rst_in(sys_rst),
  //                                 .val_in(data),
  //                                 .cat_out(ss_c),
  //                                 .an_out({ss0_an, ss1_an}));

  logic [1:0] terrain_type;
  logic [7:0] score;
  seven_segment_controller mssc(.clk_in(clk_pixel),
                                  .rst_in(sys_rst),
                                  .val_in(db),//{ball_speed_16, 8'b0, score}),
                                  .cat_out(ss_c),
                                  .an_out({ss0_an, ss1_an}));

  uart_rx #(.BAUD_COUNT(645)) test(.tx(ble_uart_tx),.rst(sys_rst),.clk(clk_pixel),.data_out(data),.valid_out(new_input));


    // all low (on). to turn off digits, set high
    assign ss0_c = ss_c; //control upper four digit's cathodes!
    assign ss1_c = ss_c; //same as above but for lower four digits!
  
  




  //clock manager...creates 74.25 Hz and 5 times 74.25 MHz for pixel and TMDS
  hdmi_clk_wiz_720p mhdmicw (.clk_pixel(clk_pixel),.clk_tmds(clk_5x),
          .reset(0), .locked(locked), .clk_ref(clk_100mhz));

  //signals related to driving the video pipeline
  logic [10:0] hcount;
  logic [9:0] vcount;
  logic vert_sync;
  logic hor_sync;
  logic active_draw;
  logic new_frame;
  logic [5:0] frame_count;
  logic [15:0] ballx_16; // fixed point
  logic [15:0] bally_16; // fixed point
  logic [15:0] ball_speed_16; // fixed point
  logic [15:0] angle_16;
  logic [15:0] cam_angle_16;
  logic [2:0] state_out;
  logic [8:0] angle;
  // assign ballx = sw[7:0];
  // assign bally = sw[14:8];
  // assign ballx = 40;
  // assign bally = 60;

  //assign angle = sw[8:0];
  assign angle = 360 - cam_angle_16[8:0];

  //from week 04! (make sure you include in your hdl)
  video_sig_gen mvg(
      .clk_pixel_in(clk_pixel),
      .rst_in(sys_rst),
      .hcount_out(hcount),
      .vcount_out(vcount),
      .vs_out(vert_sync),
      .hs_out(hor_sync),
      .ad_out(active_draw),
      .nf_out(new_frame),
      .fc_out(frame_count));

  logic [7:0] img_red, img_green, img_blue;
  logic [7:0] im_red, im_green, im_blue;
  //x_com and y_com are the image sprite locations
  // logic [10:0] x_com;
  // logic [9:0] y_com;
  // logic pop;
  // logic [15:0] q;
  // lfsr_16 popping(
  //       .clk_in(clk_pixel),
  //       .rst_in(sys_rst),
  //       .seed_in(16'b0011100111100001),
  //       .q_out(q)
  //     );
  // //update center of mass x_com, y_com based on new_com signal

  //use this in the first part of checkoff 01:
  //instance of image sprite.
  map_sprite_1 #(
    .WIDTH(160),
    .HEIGHT(90))
    com_sprite_b (
    .pixel_clk_in(clk_slow),
    .rst_in(sys_rst),
    .ballx(ballx_16),
    .bally(bally_16),
    .angle(angle),
    .hcount_in(hcount),   //TODO: needs to use pipelined signal (PS1)
    .vcount_in(vcount),   //TODO: needs to use pipelined signal (PS1)
    .red_out(im_red),
    .green_out(im_green),
    .blue_out(im_blue));


  logic [31:0] db;
  map_sprite_3 #(
    .WIDTH(160),
    .HEIGHT(90))
    com_sprite_m (
    .pixel_clk_in(clk_slow),
    .rst_in(sys_rst),
    .ballx(ballx_16),
    .bally(bally_16),
    .angle(angle),
    .hcount_in(hcount),   //TODO: needs to use pipelined signal (PS1)
    .vcount_in(vcount),   //TODO: needs to use pipelined signal (PS1)
    .red_out(img_red),
    .green_out(img_green),
    .blue_out(img_blue),
    .debug_out(db));

  logic [7:0] red, green, blue;
  logic [7:0] map1_red_pipe [2:0];
  logic [7:0] map1_blue_pipe [2:0];
  logic [7:0] map1_green_pipe [2:0];

  always_ff @(posedge clk_pixel)begin
    map1_blue_pipe[0] <= im_blue;
    map1_blue_pipe[1] <= map1_blue_pipe[0];
    map1_blue_pipe[2] <= map1_blue_pipe[1];
    map1_red_pipe[0] <= im_red;
    map1_red_pipe[1] <= map1_red_pipe[0];
    map1_red_pipe[2] <= map1_red_pipe[1];
    map1_green_pipe[0] <= im_green;
    map1_green_pipe[1] <= map1_green_pipe[0];
    map1_green_pipe[2] <= map1_green_pipe[1];
  end

  // assign red = (top)?img_red:im_red;
  // assign green = (top)?img_green:im_green;
  // assign blue = (top)?img_blue:im_blue;

  assign red = (top)?img_red:map1_red_pipe[1];
  assign green = (top)?img_green:map1_green_pipe[1];
  assign blue = (top)?img_blue:map1_blue_pipe[1];

  // assign red = map1_red_pipe[1];
  // assign green = map1_green_pipe[1];
  // assign blue = map1_blue_pipe[1];

  // assign red = img_red;
  // assign green = img_green;
  // assign blue = img_blue;

  
  logic horsync_pipe [5:0];
  always_ff @(posedge clk_pixel)begin
    horsync_pipe[0] <= hor_sync;
    for (int i=1; i<6; i = i+1)begin
      horsync_pipe[i] <= horsync_pipe[i-1];
    end
  end
  logic vertsync_pipe [5:0];
  always_ff @(posedge clk_pixel)begin
    vertsync_pipe[0] <= vert_sync;
    for (int i=1; i<6; i = i+1)begin
      vertsync_pipe[i] <= vertsync_pipe[i-1];
    end
  end
  logic adraw_pipe [5:0];
  always_ff @(posedge clk_pixel)begin
    adraw_pipe[0] <= active_draw;
    for (int i=1; i<6; i = i+1)begin
      adraw_pipe[i] <= adraw_pipe[i-1];
    end
  end

  logic [9:0] tmds_10b [0:2]; //output of each TMDS encoder!
  logic tmds_signal [2:0]; //output of each TMDS serializer!

  //three tmds_encoders (blue, green, red)
  //blue should have {vert_sync and hor_sync for control signals)
  //red and green have nothing
  tmds_encoder tmds_red(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .data_in(red),
    .control_in(2'b0),
    .ve_in(adraw_pipe[5]),
    .tmds_out(tmds_10b[2]));

  tmds_encoder tmds_green(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .data_in(green),
    .control_in(2'b0),
    .ve_in(adraw_pipe[5]),
    .tmds_out(tmds_10b[1]));

  tmds_encoder tmds_blue(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .data_in(blue),
    .control_in({vertsync_pipe[5],horsync_pipe[5]}),
    .ve_in(adraw_pipe[5]),
    .tmds_out(tmds_10b[0]));

  //four tmds_serializers (blue, green, red, and clock)
  tmds_serializer red_ser(
    .clk_pixel_in(clk_pixel),
    .clk_5x_in(clk_5x),
    .rst_in(sys_rst),
    .tmds_in(tmds_10b[2]),
    .tmds_out(tmds_signal[2]));

  tmds_serializer green_ser(
    .clk_pixel_in(clk_pixel),
    .clk_5x_in(clk_5x),
    .rst_in(sys_rst),
    .tmds_in(tmds_10b[1]),
    .tmds_out(tmds_signal[1]));

  tmds_serializer blue_ser(
    .clk_pixel_in(clk_pixel),
    .clk_5x_in(clk_5x),
    .rst_in(sys_rst),
    .tmds_in(tmds_10b[0]),
    .tmds_out(tmds_signal[0]));

  //output buffers generating differential signal:
  OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
  OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
  OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
  OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));

  gameplay gameplay_module (
    .clk_in(clk_pixel),
    .new_game(sys_rst),
    .charging_hit(btn[1]),
    .camera_pan_left(sw[15]),
    .camera_pan_right(sw[14]),
    .new_frame(new_frame),
    .user_input(data),
    .user_rdy(new_input),

    .ball_position_x(ballx_16),
    .ball_position_y(bally_16),
    .ball_speed(ball_speed_16),
    .ball_direction(angle_16),
    .cam_angle(cam_angle_16),
    .score(score),
    .state_out(state_out),
    .debug_out(debug_var)
  );


endmodule // top_level



`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 

