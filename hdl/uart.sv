module uart_rx #(parameter BAUD_COUNT = 867) (
input wire tx,
input wire clk,
input wire rst,
output logic[7:0] data_out,
output logic [3:0] state,
output logic [15:0] plo,
output logic valid_out
);


logic [$clog2(BAUD_COUNT)-1:0] count;
// logic [3:0] state;
logic [2:0] data_count;
logic last_tx;



initial last_tx=1;
initial state=1;
initial count=0;
initial valid_out=0;
initial plo=0;


always_ff @(posedge clk  ) begin 
    if(rst)begin
    count<=0;
    state<=1;
    valid_out<=0;
    data_out<=0;
    
    end else if(count==BAUD_COUNT)begin
        if(tx==0) plo<=plo+ 1;

        count<=1;
        case (state)
            1:begin
                data_count<=0;
                data_out<=8'b0;
                valid_out<=0;
                if(tx==0)state<=2;
            end
            2:begin
                data_out<={tx,data_out[7:1]};
                if (data_count==7) state<=3;
                data_count<=data_count+1;
            end
            3:begin
                valid_out<=1;
                // state<=1;

            end
        endcase

    end else begin
        count<=count+1;
    end

    
end







endmodule