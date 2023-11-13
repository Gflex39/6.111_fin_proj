module video_sig_gen
#(
  parameter ACTIVE_H_PIXELS = 1280,
  parameter H_FRONT_PORCH = 110,
  parameter H_SYNC_WIDTH = 40,
  parameter H_BACK_PORCH = 220,
  parameter ACTIVE_LINES = 720,
  parameter V_FRONT_PORCH = 5,
  parameter V_SYNC_WIDTH = 5,
  parameter V_BACK_PORCH = 20)
(
  input wire clk_pixel_in,
  input wire rst_in,
  output logic [$clog2(TOTAL_PIXELS)-1:0] hcount_out,
  output logic [$clog2(TOTAL_LINES)-1:0] vcount_out,
  output logic vs_out,
  output logic hs_out,
  output logic ad_out,
  output logic nf_out,
  output logic [5:0] fc_out);
 
  localparam TOTAL_PIXELS = ACTIVE_H_PIXELS+H_BACK_PORCH+H_SYNC_WIDTH+H_FRONT_PORCH; 
  localparam TOTAL_LINES = ACTIVE_LINES+V_BACK_PORCH+V_FRONT_PORCH+V_SYNC_WIDTH; 
  logic [1:0] deassert;
  logic [$clog2(TOTAL_PIXELS)-1:0] nextx;
  logic [$clog2(TOTAL_LINES)-1:0] nexty;
  initial deassert = 0;
  always_ff @(posedge clk_pixel_in)begin
    if(rst_in)begin
        deassert <= 1;
        hcount_out<=0;
        vcount_out<=0;
        vs_out<=0;
        hs_out<=0;
        ad_out<=0;
        nf_out<=0;
        fc_out<=0;
        nextx <=1;
        nexty <=0;
    end else begin
        if(deassert == 0)begin
            deassert <= 0;
        end else if(deassert == 1)begin
            deassert <= 2;
            hcount_out<=0;
            vcount_out<=0;
            vs_out<=0;
            hs_out<=0;
            ad_out<=1;
            nf_out<=0;
            fc_out<=0;
            nextx <=1;
            nexty <=0;
        end else begin
            deassert<=2;
            ad_out <= (nextx < ACTIVE_H_PIXELS) & (nexty < ACTIVE_LINES);
            hs_out <= (nextx <ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH) & (nextx > ACTIVE_H_PIXELS + H_FRONT_PORCH - 1);
            vs_out <= (nexty <ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH) & (nexty > ACTIVE_LINES + V_FRONT_PORCH - 1);
            hcount_out <= nextx;
            vcount_out <= nexty;
            if(nextx == ACTIVE_H_PIXELS & nexty == ACTIVE_LINES)begin
                nf_out<=1;
                if(fc_out == 59)begin
                    fc_out <= 0;
                end else begin
                    fc_out <= fc_out + 1;
                end
            end else begin
                nf_out <= 0;
            end
            if(nextx == TOTAL_PIXELS-1) begin
                nextx <=0;
                if(nexty == TOTAL_LINES-1)begin
                    nexty <= 0;
                end else begin
                    nexty <= nexty+1;
                end
            end else begin
                nextx <= nextx+1;
            end
        end
    end
  end
                



            





 
endmodule