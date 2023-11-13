module lfsr_16 ( input wire clk_in, input wire rst_in,
                    input wire [15:0] seed_in,
                    output logic [15:0] q_out);
  logic [15:0] temp;
  always_ff @(posedge clk_in)begin
    if(rst_in) begin
      temp <= seed_in;
      q_out <= seed_in;
    end else begin
      temp <= {temp[15]^temp[14],temp[13:2],temp[15]^temp[1],temp[0],temp[15]};
      q_out <= {temp[15]^temp[14],temp[13:2],temp[15]^temp[1],temp[0],temp[15]};
    end
  end

endmodule




