module brute_force(input logic clk,
						 input logic start,
						 input logic [255:0] decoded_data,
						 output logic [23:0] tester_key,
						 output logic [23:0] secret_key,
						 output logic finish);

logic [5:0] lim = 0;
logic [3:0] state;
logic [22:0] intermediate_key = 0;
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
					lim <= 0; // keeps track of when the end of the 256 bit data has been completely read; up to a value of 31 ([31:0])
					dd <= decoded_data; // assign input to logic so it can be modified later
					//if(intermediate_key == {22{1'b1}})  // should apply safety check for infinite loop
					if(start == 1) state <= INCREMENT_KEY;
				end
		INCREMENT_KEY: begin
								intermediate_key <= intermediate_key + 1; // brute-force, trying everythign in the key space; starts at 1
								state <= SEND_KEY;
							end
		SEND_KEY: begin
						tester_key <= {2'b0, intermediate_key[21:0] - 1}; // -1 because we want to start at index 0, [21:0] because 22 is overflow protection
						if(start == 1) state <= VALIDATOR; // waiting for other state machine to say "yes, received key and fecthed data"
					 end
		VALIDATOR: begin
						if((dd[7:0] >= 8'd97 && dd[7:0] <= 8'd122) || dd[7:0] == 8'd32) begin // check each char to know if real value *[a:z] and space*
							state <= SHIFTER;
						end
						else begin
							state <= IDLE;
						end
					  end
		SHIFTER: begin
						dd <= dd >> 8; // shift data down 8 bits so VALIDATOR can read the next 8 bits (the next character)
						if(lim == 8'd31) state <= OUTPUT; // once 32 iterations have occured successfully, go to OUTPUT state
						else state <= VALIDATOR;
						
						lim <= lim + 1;
					end
		OUTPUT: begin
					secret_key = {2'b0, intermediate_key[21:0] - 1}; // -1 because we want to start at index 0, [21:0] because 22 is overflow protection
					state <= IDLE;
				  end
		default: state <= IDLE;
	endcase
end

always_comb begin
finish = state[3];
end

endmodule