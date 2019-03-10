module brute_force(input logic clk,
						 input logic start,
						 input logic [255:0] decoded_data,
						 output logic [23:0] secret_key,
						 output logic finish);

logic [5:0] lim = 0;
logic [3:0] state;
logic [21:0] intermediate_key = 0;
logic [255:0] dd;

parameter IDLE = 4'b1000;
parameter INCREMENT_KEY = 4'b0001;
parameter SEND_KEY = 4'b1010;
parameter VALIDATOR = 4'b0011;
parameter SHIFTER = 4'b0100;
parameter OUTPUT = 4'b1101;


always_ff @(posedge clk) begin

	case(state)
		IDLE: begin
					lim <= 0;
					dd <= decoded_data;
					//safety check
					if(intermediate_key == {22{1'b1}}) intermediate_key <= 0;
					//start
					if(start == 1) state <= INCREMENT_KEY;
				end
		INCREMENT_KEY: begin
								intermediate_key <= intermediate_key + 1;
								state <= SEND_KEY;
							end
		SEND_KEY: begin
						if(start == 1) state <= VALIDATOR;
					 end
		VALIDATOR: begin
						if((dd[7:0] >= 8'd97 && dd[7:0] <= 8'd122) || dd[7:0] == 8'd32) begin
							state <= SHIFTER;
						end
						else begin
							state <= IDLE;
						end
					  end
		SHIFTER: begin
						dd <= dd >> 8;
						if(lim == 8'd31) state <= OUTPUT;
						else state <= VALIDATOR;
						
						lim <= lim + 1;
					end
		OUTPUT: begin
					secret_key = {2'b0, intermediate_key};
					state <= IDLE;
				  end
		default: state <= IDLE;
	endcase
end

always_comb begin
finish = state[3];
end

endmodule