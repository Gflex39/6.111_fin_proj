module tm_choice (
  input wire [7:0] data_in,
  output logic [8:0] qm_out
  );


  logic [3:0] digit_sum;
  logic [8:0] temp_q;
  assign digit_sum = data_in[0]+data_in[1]+data_in[2]+data_in[3]+data_in[4]+data_in[5]+data_in[6]+data_in[7];
  always_comb begin
    if((digit_sum > 4) | (digit_sum == 4 & data_in[0] == 0))begin
        temp_q[0] = data_in[0];
        temp_q[1] = ~(data_in[1] ^ temp_q[0]);
        temp_q[2] = ~(data_in[2] ^ temp_q[1]);
        temp_q[3] = ~(data_in[3] ^ temp_q[2]);
        temp_q[4] = ~(data_in[4] ^ temp_q[3]);
        temp_q[5] = ~(data_in[5] ^ temp_q[4]);
        temp_q[6] = ~(data_in[6] ^ temp_q[5]);
        temp_q[7] = ~(data_in[7] ^ temp_q[6]);
        temp_q[8] = 0;  
    end else begin
        temp_q[0] = data_in[0];
        temp_q[1] = data_in[1] ^ temp_q[0];
        temp_q[2] = data_in[2] ^ temp_q[1];
        temp_q[3] = data_in[3] ^ temp_q[2];
        temp_q[4] = data_in[4] ^ temp_q[3];
        temp_q[5] = data_in[5] ^ temp_q[4];
        temp_q[6] = data_in[6] ^ temp_q[5];
        temp_q[7] = data_in[7] ^ temp_q[6];
        temp_q[8] = 1;
    end
  end 
  assign qm_out = temp_q;


    
  



  


endmodule //end tm_choice
