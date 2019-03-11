/* third_loop: FSM Used to compute third loop of algorithm.
 *
 * The FSM operates using START/FINISH protocol to implement the following logic
 * 
 * i = 0, j=0
 * for k = 0 to message_length-1 { // message_length is 32 in our implementation
 *   i = i+1
 *   j = j+s[i]
 *   swap values of s[i] and s[j]
 *   f = s[ (s[i]+s[j]) ]
 *   decrypted_output[k] = f xor encrypted_input[k] // 8 bit wide XOR function
 * }
 * TODO: write explenations about variables used
 * Where s defines in-memory, and s[i]/s[j] is address i/j of memory
 */



module third_loop(
                  input logic clk,
                  input logic start,
                  input logic [7:0] s_ram_q,
                  input logic [7:0] e_rom_q,
                  output logic [7:0] s_wren,
                  output logic d_wren,
                  output logic [7:0] s_address,
                  output logic [7:0] d_address,
                  output logic [7:0] e_address,
                  output logic [7:0] d_data,
                  output logic [7:0] s_data,
                  output logic [7:0] read_data_e,
                  output logic [7:0] f,
                  output logic finish
                 );

parameter IDLE            = 9'b000000_001;
parameter COMPUTE_I       = 9'b000001_000; // COMPUTE_I state increments i every new loop cycle
parameter REQUEST_READ_I  = 9'b000010_000; // REQUEST_READ_I state sets address to read from S-RAM
parameter WAIT_I_DATA_1   = 9'b000011_000; // WAIT_I_DATA state waits for data requested to S-RAM to be delivered
parameter WAIT_I_DATA_2   = 9'b000100_000;
parameter READ_I_DATA     = 9'b000101_000;
parameter COMPUTE_J       = 9'b000110_000;
parameter REQUEST_READ_J  = 9'b000111_000;
parameter WAIT_J_DATA_1   = 9'b001000_000;
parameter WAIT_J_DATA_2   = 9'b001001_000;
parameter READ_J_DATA     = 9'b001010_000;
parameter PRE_WRITE_I     = 9'b001011_000;
parameter WRITE_I         = 9'b001100_010;
parameter PRE_WRITE_J     = 9'b001101_000;
parameter WRITE_J         = 9'b001110_010;
parameter REQUEST_READ_JI = 9'b001111_000; 
parameter WAIT_JI_DATA_1  = 9'b010000_000; 
parameter WAIT_JI_DATA_2  = 9'b010001_000; 
parameter READ_JI         = 9'b010010_000; 
parameter REQUEST_E_READ  = 9'b010011_000; 
parameter READ_E_DATA     = 9'b010100_000; 
parameter PRE_WRITE_D     = 9'b010101_000;
parameter WRITE_D         = 9'b010110_100;
parameter CHECK_INDX      = 9'b010111_000;
parameter WAIT_E          = 9'b011000_000;
parameter WAIT_E_2        = 9'b011001_000;
parameter FINISH          = 9'b111111_001; //     

logic [8:0] state;
logic [5:0] k;
logic [7:0] i;
logic [7:0] j;
//logic [7:0] f;
logic [7:0] read_data_i;
logic [7:0] read_data_j;


assign finish = state[0];
assign s_wren = state[1];
assign d_wren = state[2];
logic [2:0] count;

always_ff @(posedge clk) begin
    case(state)
        IDLE: if(start)
                state <= COMPUTE_I;
              else begin
                state <= IDLE;
                k = 8'b0;
                i = 8'b0;
                count = 8'b0;
                j = 8'b0;
              end
        COMPUTE_I: begin
                    i <= (i + 1);
                    state <= REQUEST_READ_I;
                   end
        REQUEST_READ_I: begin
                        s_address <= i;
                        state <= WAIT_I_DATA_1;
                        end
        WAIT_I_DATA_1: state <= WAIT_I_DATA_2;    
  		  WAIT_I_DATA_2: state <= READ_I_DATA;
  		  READ_I_DATA: begin 
  							read_data_i <= s_ram_q;
  							state <= COMPUTE_J;
  						  end
  	  	COMPUTE_J: begin
  	  				     j <= j + read_data_i;
  	  				     state <= REQUEST_READ_J;
  	  				     end
  		  REQUEST_READ_J: begin
  			      					s_address <= j;
  						      		state <= WAIT_J_DATA_1;
  							        end
  		 WAIT_J_DATA_1: state <= WAIT_J_DATA_2;    
  		 WAIT_J_DATA_2: state <= READ_J_DATA;
  		 READ_J_DATA: begin 
  							    read_data_j <= s_ram_q;
  							    state <= PRE_WRITE_I;
  						      end
        PRE_WRITE_I: begin
                     s_address <= i;
                     s_data <= read_data_j;
                     state <= WRITE_I;
                     end
        WRITE_I: begin
                 state <= PRE_WRITE_J;
                 end
        PRE_WRITE_J: begin
                     s_address <= j;
                     s_data <= read_data_i;
                     state <= WRITE_J;
                     end
        WRITE_J: begin
                 state <= REQUEST_READ_JI;
                 end
        REQUEST_READ_JI: begin
                         s_address <= read_data_i + read_data_j;
                            state <= WAIT_JI_DATA_1;
                         end
        WAIT_JI_DATA_1: state <= WAIT_JI_DATA_2;
  		  WAIT_JI_DATA_2: state <= READ_JI;
        READ_JI: begin
                 f <= s_ram_q;
                 state <= REQUEST_E_READ;
                 end
        REQUEST_E_READ: begin
                        e_address <= k;
                        state <= WAIT_E;
                        end
        WAIT_E: state <= WAIT_E_2;
        WAIT_E_2: state <= READ_E_DATA;
        READ_E_DATA: begin
                     read_data_e <= e_rom_q;
                     count <= count + 1;
                     state <= PRE_WRITE_D;
                     end
        PRE_WRITE_D: begin
                     d_data <= f ^ read_data_e;
                     d_address <= k;
                     state <= WRITE_D;
                     end
        WRITE_D: begin
                 state <= CHECK_INDX;
                 k <= k + 1;
                 end
        CHECK_INDX: begin
                    if(k == 32)
                      state <= FINISH;
                    else
                     state <= COMPUTE_I;
                    end
       FINISH: state <= FINISH;
       default: state <= IDLE;
    endcase
end

endmodule