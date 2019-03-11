/* second_loop: FSM Used to compute second loop of algorithm.
 *
 * The FSM operates using START/FINISH protocol to implement the following logic
 * 
 * j = 0
 * for i = 0 to 255 {
 *    j = (j + s[i] + secret_key[i mod keylength] ) mod 256 //keylength is 3 in our impl.
 *    swap values of s[i] and s[j]
 * }
 *
 * Where s defines in-memory, and s[i]/s[j] is address i/j of memory
 */
module second_loop (
                   input logic clk,
                   input logic start,
                   input logic [7:0] s_ram_data_out,
                   input logic [23:0] secret_key,
                   output logic wren,
                   output logic finish,
                   output logic [7:0] data,
                   output logic [7:0] address
                  );

    parameter IDLE                = 7'b00000_10; // IDLE wait for start signal
    parameter REQUEST_SRAM_READ   = 7'b00001_00; // REQUEST_SRAM_READ state sets address to read from S-RAM
    parameter READ_SRAM           = 7'b00010_00; // READ_SRAM state stores value read from S-RAM data_read_i register
    parameter COMPUTE_MOD         = 7'b00011_00; // COMPUTE_MOD state computed modulus operation for line 2 of algorithm
    parameter COMPUTE_SECRET_ADDR = 7'b00100_00; // COMPUTE_SECRET_ADDR state selects 8 out of 24 bits from secret key depending on mod operation
    parameter COMPUTE_J           = 7'b00101_00; // COMPUTE_J states computes value of j 
    parameter REQUEST_SRAM_READ_J = 7'b00110_00; // REQUEST_SRAM_READ_J state sets address to read from S-RAM
    parameter READ_SRAM_J         = 7'b00111_00; // READ_SRAM_J state stores value read from S-RAM data_read_j register
    parameter PRE_WRITE_J         = 7'b01000_00; // PRE_WRITE_J state sets address and data to be written to S-RAM
    parameter WRITE_J             = 7'b01001_01; // WRITE_J sets wren flag to perform write operation to S-RAM
    parameter PRE_WRITE_I         = 7'b01010_00; // PRE_WRITE_I state sets address and data to be written to S-RAM
    parameter WRITE_I             = 7'b01011_01; // WRITE_I state sets wren flag to perform write operation to S-RAM
    parameter COMPARE_INDX        = 7'b01100_00; // COMPARE_INDX state compares the current loop count, to stop at 256
	 parameter WAIT_1              = 7'b01101_00; // WAIT_1 state waits for S-RAM reading operation 
	 parameter WAIT_2              = 7'b01110_00; // WAIT_2 state waits for S-RAM reading operation 
    parameter WAIT_1_J            = 7'b01111_00; // WAIT_1_J state waits for S-RAM reading operation 
	 parameter WAIT_2_J            = 7'b10000_00; // WAIT_2_J state waits for S-RAM reading operation 
    parameter FINISH              = 7'b11111_10; // Trigger finish signal and finish FSM


    logic [7:0] state;

    logic [7:0] data_read_i;
    logic [7:0] data_read_j;
    logic [7:0] secret_address;
    logic [7:0] i;
    logic [7:0] j;
    logic [7:0] mod_op;

    assign wren   = state[0];
    assign finish = state[1];

    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                    if (start == 1'b1) begin
                        state <= REQUEST_SRAM_READ;
                    end
                    else begin
                        state <= IDLE;
                        i <= 8'b0;
                        j <= 8'b0;
                    end
                  end
            REQUEST_SRAM_READ: begin
                                address <= i[7:0];
                                data    <= 1'b0;
                                state   <= READ_SRAM; 
                               end
            READ_SRAM: state <= WAIT_1;
				WAIT_1: state<= WAIT_2;
				WAIT_2: begin
						  state <= COMPUTE_MOD;
            		  data_read_i <= s_ram_data_out;
						  end           
            COMPUTE_MOD: begin
                           mod_op <= i % 8'b00000011;
                           state <= COMPUTE_SECRET_ADDR; 
								 end
            COMPUTE_SECRET_ADDR: begin
                                    if (mod_op == 8'b00000000)
                                       secret_address <= secret_key[23:16];
                                    else if(mod_op == 8'b00000001)
                                       secret_address <= secret_key[15:8];
                                    else 
                                       secret_address <= secret_key[7:0];
                                    state <= COMPUTE_J;
                                 end
            COMPUTE_J: begin
                            j <= j + data_read_i + secret_address;
                            state <= REQUEST_SRAM_READ_J;
                       end
            REQUEST_SRAM_READ_J: begin
                                    address <= j;
                                    data    <= 1'b0;
                                    state   <= READ_SRAM_J; 
                                 end
            READ_SRAM_J: state <= WAIT_1_J;
				WAIT_1_J: state <= WAIT_2_J;
				WAIT_2_J: begin
						  state <= PRE_WRITE_J;
                    data_read_j <= s_ram_data_out;
						  end  
            PRE_WRITE_J: begin
                            address <= j;
                            data    <= data_read_i;
                            state   <= WRITE_J;
                         end
            WRITE_J: begin
                        state <= PRE_WRITE_I;
                     end
            PRE_WRITE_I: begin
                            address <= i;
                            data    <= data_read_j;
                            state   <= WRITE_I;
                         end
            WRITE_I: begin
                            state <= COMPARE_INDX;
                            i     <= i + 1'b1;  
                     end
            COMPARE_INDX: begin
                          if (i == 0)
                            state <= FINISH;
                        else
                            state <= REQUEST_SRAM_READ;
                          end
            FINISH: begin
                        state <= IDLE;
                    end
            default: state <= IDLE;
        endcase
    end
endmodule