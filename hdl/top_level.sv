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
  output logic ble_uart_rx
  );






  /* have btnd control system reset */


  //Clocking Variables:
  logic clk_pixel, clk_5x; //clock lines
  logic locked; //locked signal (we'll leave unused but still hook it up)


  logic [31:0] debug_var;
  logic sys_rst;
  assign sys_rst = btn[0];
  assign ble_uart_cts=1;
  logic [7:0] data;
  logic [6:0] ss_c;



  // seven_segment_controller mssc(.clk_in(clk_pixel),
  //                                 .rst_in(sys_rst),
  //                                 .val_in(data),
  //                                 .cat_out(ss_c),
  //                                 .an_out({ss0_an, ss1_an}));

  logic [1:0] terrain_type;
  seven_segment_controller mssc(.clk_in(clk_pixel),
                                  .rst_in(sys_rst),
                                  .val_in(debug_var),
                                  .cat_out(ss_c),
                                  .an_out({ss0_an, ss1_an}));

  uart_rx #(.BAUD_COUNT(645)) test(.tx(ble_uart_tx),.rst(sys_rst),.clk(clk_pixel),.data_out(data));


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
  logic [7:0] ballx;
  logic [6:0] bally;
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
  assign ballx = ballx_16[15:8];
  assign bally = bally_16[14:8];

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
    com_sprite_m (
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst),
    .ballx(ballx),
    .bally(bally),
    .angle(angle),
    .hcount_in(hcount),   //TODO: needs to use pipelined signal (PS1)
    .vcount_in(vcount),   //TODO: needs to use pipelined signal (PS1)
    .red_out(img_red),
    .green_out(img_green),
    .blue_out(img_blue));

  logic [7:0] red, green, blue;

  assign red = img_red;
  assign green = img_green;
  assign blue = img_blue;

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
    .ve_in(active_draw),
    .tmds_out(tmds_10b[2]));

  tmds_encoder tmds_green(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .data_in(green),
    .control_in(2'b0),
    .ve_in(active_draw),
    .tmds_out(tmds_10b[1]));

  tmds_encoder tmds_blue(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .data_in(blue),
    .control_in({vert_sync,hor_sync}),
    .ve_in(active_draw),
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

    .ball_position_x(ballx_16),
    .ball_position_y(bally_16),
    .ball_speed(ball_speed_16),
    .ball_direction(angle_16),
    .cam_angle(cam_angle_16),
    .state_out(state_out),
    .debug_out(debug_var)
  );


endmodule // top_level



`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 

