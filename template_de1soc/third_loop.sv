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
 * TODO: write explanations about variables used
 * Where s defines in-memory, and s[i]/s[j] is address i/j of memory
 */



module third_loop(
                  input logic clk,
                  input logic start,
                  input logic [7:0] s_ram_q,
                  input logic [7:0] e_rom_q,
                  output logic s_wren,
                  output logic d_wren,
                  output logic [7:0] s_address,
                  output logic [7:0] d_address,
                  output logic [7:0] e_address,
                  output logic [7:0] d_data,
                  output logic [7:0] s_data,
					      	output logic valid,
                  output logic finish
                 );

parameter IDLE            = 9'b000000_001;
parameter COMPUTE_I       = 9'b000001_000; // COMPUTE_I state increments i every new loop cycle
parameter REQUEST_READ_I  = 9'b000010_000; // REQUEST_READ_I state sets address to read from S-RAM
parameter WAIT_I_DATA_1   = 9'b000011_000; // WAIT_I_DATA state waits for data requested to S-RAM to be delivered
parameter WAIT_I_DATA_2   = 9'b000100_000; // WAIT_I_DATA_2 state waits for data requested to S-RAM to be delivered
parameter READ_I_DATA     = 9'b000101_000; // READ_I_DATA state store data recieved from S-RAM
parameter COMPUTE_J       = 9'b000110_000; // COMPUTE_J state computes the value of j to be used as address
parameter REQUEST_READ_J  = 9'b000111_000; // REQUEST_READ_J state set read address of S-RAM to be equal to j
parameter WAIT_J_DATA_1   = 9'b001000_000; // WAIT_J_DATA_1 state waits for data requested to S-RAM to be delivered
parameter WAIT_J_DATA_2   = 9'b001001_000; // WAIT_J_DATA_2 state waits for data requested to S-RAM to be delivered
parameter READ_J_DATA     = 9'b001010_000; // READ_J_DATA state stores data recieved from S-RAM
parameter PRE_WRITE_I     = 9'b001011_000; // PRE_WRITE_I state sets address and data to be written in S-RAM
parameter WRITE_I         = 9'b001100_010; // WRITE_I state triggers S-RAM wren
parameter PRE_WRITE_J     = 9'b001101_000; // PRE_WRITE_J state sets address and data to be written in S-RAM
parameter WRITE_J         = 9'b001110_010; // WRITE_J state triggers S-RAM wren
parameter REQUEST_READ_JI = 9'b001111_000; // REQUEST_READ_JI state sets read address of S-RAM to be equal to [i]+[j]
parameter WAIT_JI_DATA_1  = 9'b010000_000; // WAIT_JI_DATA_1 state waits for data requested to S-RAM to be delivered
parameter WAIT_JI_DATA_2  = 9'b010001_000; // WAIT_JI_DATA_2 state waits for data requested to S-RAM to be delivered
parameter READ_JI         = 9'b010010_000; // READ_JI state stores data recived from S-RAM
parameter REQUEST_E_READ  = 9'b010011_000; // REQUEST_E_READ state sets the address to be read on E-ROM
parameter READ_E_DATA     = 9'b010100_000; // READ_E_DATA state stores data read from E-ROM
parameter PRE_WRITE_D     = 9'b010101_000; // PRE_WRITE_D state sets address and data to write to D-RAM
parameter WRITE_D         = 9'b010110_100; // WRITE_D stata triggers d_wren
parameter CHECK_INDX      = 9'b010111_000; // CHECK_INDX state checks of all values of key has been uses
parameter WAIT_E          = 9'b011000_000; // WAIT_E state waits for data requested from E-ROM to be ready
parameter WAIT_E_2        = 9'b011001_000; // WAIT_E_2 state waits for data requested from E-ROM to be ready
parameter FINISH          = 9'b111111_001; // FINISH    

logic [8:0] state;
logic [5:0] k;
logic [7:0] i;
logic [7:0] j;
logic [7:0] f;
logic [7:0] read_data_i;
logic [7:0] read_data_j;
logic [7:0] read_data_e;


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
                s_address = 0;                
                e_address = 0;
                d_address = 0;
                s_data = 0;
                d_data = 0;             
					 valid = 1'b1;
              end
        COMPUTE_I: begin                         // Increments i every time the loop rund 
                    i <= (i + 1);
                    state <= REQUEST_READ_I;
                   end
        REQUEST_READ_I: begin
                        s_address <= i;          // Reads memory at address i
                        state <= WAIT_I_DATA_1;
                        end
        WAIT_I_DATA_1: state <= WAIT_I_DATA_2;    
  		  WAIT_I_DATA_2: state <= READ_I_DATA;
  		  READ_I_DATA: begin 
  							read_data_i <= s_ram_q;          // Store memory data in register
  							state <= COMPUTE_J;
  						  end
  	  	COMPUTE_J: begin
  	  				     j <= j + read_data_i;         // Computes value of j
  	  				     state <= REQUEST_READ_J;
  	  				     end
  		  REQUEST_READ_J: begin
  			      					s_address <= j;          // Reads memory at addres j
  						      		state <= WAIT_J_DATA_1;
  							        end
  		 WAIT_J_DATA_1: state <= WAIT_J_DATA_2;    
  		 WAIT_J_DATA_2: state <= READ_J_DATA;
  		 READ_J_DATA: begin 
  							    read_data_j <= s_ram_q;      // Stores memory data in register
  							    state <= PRE_WRITE_I;
  						      end
        PRE_WRITE_I: begin
                     s_address <= i;             // Swap value of i and j by storing value of j in address i
                     s_data <= read_data_j;
                     state <= WRITE_I;
                     end
        WRITE_I: begin
                 state <= PRE_WRITE_J;
                 end
        PRE_WRITE_J: begin
                     s_address <= j;             // Finish the swap by writting value of i in address j
                     s_data <= read_data_i;
                     state <= WRITE_J;
                     end
        WRITE_J: begin
                 state <= REQUEST_READ_JI;
                 end
        REQUEST_READ_JI: begin
                         s_address <= read_data_i + read_data_j; // Read data located at memory address [i]+[j]
                            state <= WAIT_JI_DATA_1;
                         end
        WAIT_JI_DATA_1: state <= WAIT_JI_DATA_2;
  		  WAIT_JI_DATA_2: state <= READ_JI;
        READ_JI: begin
                 f <= s_ram_q;                                   // Stores data of memory inside internal registers
                 state <= REQUEST_E_READ;
                 end
        REQUEST_E_READ: begin
                        e_address <= k;                          // Reads data of encrypted message located at address e
                        state <= WAIT_E;
                        end
        WAIT_E: state <= WAIT_E_2;
        WAIT_E_2: state <= READ_E_DATA;
        READ_E_DATA: begin
                     read_data_e <= e_rom_q;                     // Stores data in internal register
                     count <= count + 1;
                     state <= PRE_WRITE_D;
                     end
        PRE_WRITE_D: begin
                     d_data <= f ^ read_data_e;                  // Computes f XOR encrypted_data[k]
                     d_address <= k;
                     state <= WRITE_D;
                     end
        WRITE_D: begin                                           // Validates if character is valid or not a-z and " "
					  if((d_data >= 8'd97 && d_data <= 8'd122) || d_data == 8'd32) begin
							state <= CHECK_INDX;
							k <= k + 1;          // If valid keep decoding
						end
						else begin
							valid <= 1'b0;       // If not valid abort process
							state <= FINISH;
						end
                 
                 end
        CHECK_INDX: begin
                    if(k == 32) // Check if length of key is reached.
                      state <= FINISH;
                    else
                     state <= COMPUTE_I;
                    end
       FINISH: state <= IDLE;
       default: state <= IDLE;
    endcase
end

endmodule