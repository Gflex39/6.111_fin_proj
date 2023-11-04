module alu(input wire [7:0] d0_in,
          input wire [7:0] d1_in,
          input wire [2:0] sel_in,
          output logic [15:0] res_out,
          output logic  gt_out,
          output logic eq_out);
    always_comb begin
      if (sel_in==3'b000)begin
        res_out = d0_in+d1_in;
      end else if(sel_in==3'b001)begin
        res_out = d1_in-d0_in;
      end else if(sel_in==3'b010)begin
        res_out = d0_in*d1_in;
      end else if(sel_in==3'b011)begin
        res_out = d1_in/d0_in;
      end else if(sel_in==3'b100)begin
        res_out = d1_in%d0_in;
      end else if(sel_in==3'b101)begin
        res_out = d0_in&d1_in;
      end else if(sel_in==3'b110)begin
        res_out = d0_in|d1_in;
      end else begin
        res_out = d0_in^d1_in;
      end  

    end
  assign eq_out = d0_in==d1_in? 1:0;
  assign gt_out = d0_in<d1_in? 1:0;
   //  YOUR CODE HERE
endmodule


