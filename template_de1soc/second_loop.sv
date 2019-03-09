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

    parameter IDLE                = 7'b00000_10;
    parameter REQUEST_SRAM_READ   = 7'b00001_00; 
    parameter READ_SRAM           = 7'b00010_00;
    parameter COMPUTE_MOD         = 7'b00011_00;
    parameter COMPUTE_SECRET_ADDR = 7'b00100_00;
    parameter COMPUTE_J           = 7'b00101_00;
    parameter REQUEST_SRAM_READ_J = 7'b00110_00;
    parameter READ_SRAM_J         = 7'b00111_00;
    parameter PRE_WRITE_J         = 7'b01000_00;
    parameter WRITE_J             = 7'b01001_01;
    parameter PRE_WRITE_I         = 7'b01010_00;
    parameter WRITE_I             = 7'b01011_01;
    parameter COMPARE_INDX        = 7'b01100_00;
    parameter FINISH              = 7'b01101_10;
	 parameter WAIT_1              = 7'b01110_00;
	 parameter WAIT_2              = 7'b01111_00;
    parameter WAIT_1_J            = 7'b10000_00;
	 parameter WAIT_2_J            = 7'b10001_00;


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
                                address <= i;
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
                          if (i == 255)
                            state <= FINISH;
                        else
                            state <= REQUEST_SRAM_READ;
                          end
            FINISH: begin
                        state <= FINISH;
                    end
            default: state <= IDLE;
        endcase
    end
endmodule