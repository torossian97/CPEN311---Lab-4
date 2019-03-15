module ksa (
            input logic CLOCK_50,            
            input logic [3:0] KEY, 
            input logic [9:0] SW,
            output logic [9:0] LEDR,
            output logic [6:0] HEX0,
            output logic [6:0] HEX1,
            output logic [6:0] HEX2,
            output logic [6:0] HEX3,
            output logic [6:0] HEX4,
            output logic [6:0] HEX5
           );

    parameter IDLE           = 7'b0000_000;
    parameter CHECK_SRAM     = 7'b0110_000;
    parameter INIT_SRAM      = 7'b0001_001;
    parameter WAIT_SRAM_DONE = 7'b0010_000;
    parameter CHECK_LOOPER   = 7'b0101_000;
    parameter INIT_LOOPER    = 7'b0011_010;
    parameter WAIT_LOOPER    = 7'b0111_000;
    parameter CHECK_3_LOOP   = 7'b1000_000;
    parameter INIT_3_LOOP    = 7'b1001_100;
    parameter WAIT_3_LOOP    = 7'b1010_000;
	 parameter FAILED_FINISH  = 7'b1100_000;
    parameter FINISH         = 7'b1111_000;
   
    logic clk;
    logic reset_n;
    logic [6:0] ssOut;
    logic [3:0] nIn;
	logic is_mem_init = 1'b0;
    
    assign clk = CLOCK_50;
    assign reset_n = KEY[3];

    
    logic [6:0] state;
   

    // S-RAM init and signals
    s_memory memory_1(.clock(clk), .data(s_data), .address(s_address), .wren(s_wren), .q(s_q));
    logic [7:0] s_data;
    logic [7:0] s_address;
    logic s_wren;
    logic [7:0] s_q;

    // D-RAM init and signals
    d_memory memory_3(.address(d_address),.clock(clk),.data(d_data),.wren(d_wren),.q(d_q));
    logic [7:0] d_q;
    logic [7:0] d_address;
    logic d_wren;
    logic [7:0] d_data;

    // E-ROM init and signals
    e_memory memory_2(.address(e_address), .clock(clk), .q(e_q));
    logic [7:0] e_q;
    logic [7:0] e_address;
    
    // Writter init and signals
	memory_write writter_1(.clk(clk), .start(start_writter), .finish(finish_writter), .address(writter_address), .wren(writter_wren), .data(writter_data));
    logic [7:0] writter_address;
    logic [7:0] writter_data;
	logic start_writter;
	logic finish_writter;
    logic writter_wren;

    // Second Loop init and signals
    second_loop loop_2(.clk(clk), .start(start_second_loop), .finish(finish_second_loop), .secret_key(secret_key), .s_ram_data_out(s_q), .wren(looper_wren), .address(looper_address), .data(looper_data));
    logic [7:0] looper_address;
    logic [7:0] looper_data;
    logic looper_wren;
    logic start_second_loop;
    logic finish_second_loop;
    logic [23:0] secret_key = 24'b0;//24'b00000000_00000011_11111111; 

    // Third Loop debug signals
    logic [7:0] count;
    logic [7:0] count2;


    // Third Loop init and signals
    third_loop loop_3(.clk(clk), .start(start_third_loop), .finish(finish_third_loop), .s_ram_q(s_q), .e_rom_q(e_q), .d_wren(third_loop_d_wren), .s_address(third_loop_s_address), .d_address(third_loop_d_address), .e_address(third_loop_e_address), .d_data(third_loop_d_data), .s_data(third_loop_s_data), .s_wren(third_loop_s_wren), .valid(valid));
    logic start_third_loop;
    logic finish_third_loop;
    logic third_loop_d_wren;
    logic third_loop_s_wren;
	 logic valid;
    logic [7:0] third_loop_s_address;
    logic [7:0] third_loop_d_address;
    logic [7:0] third_loop_e_address;
    logic [7:0] third_loop_d_data;
    logic [7:0] third_loop_s_data;
	 
	 

    // TODO: Remove debuf signals and algorithms

	 logic [7:0] finishing_sign;
    assign LEDR[7:0] = finishing_sign;
	 //assign LEDR[7:0] = secret_key[12:5];
    
    SevenSegmentDisplayDecoder mod0 (.nIn(secret_key[3:0]), .ssOut(HEX0));
	 SevenSegmentDisplayDecoder mod1 (.nIn(secret_key[7:4]), .ssOut(HEX1));
	 SevenSegmentDisplayDecoder mod2 (.nIn(secret_key[11:8]), .ssOut(HEX2));
	 SevenSegmentDisplayDecoder mod3 (.nIn(secret_key[15:12]), .ssOut(HEX3));
	 SevenSegmentDisplayDecoder mod4 (.nIn(secret_key[19:16]), .ssOut(HEX4));
	 SevenSegmentDisplayDecoder mod5 (.nIn(secret_key[23:20]), .ssOut(HEX5));


    // Link start writter trigger to state output index 0
    assign start_writter       = state[0];
    assign start_second_loop   = state[1];
    assign start_third_loop    = state[2];
	 assign start_bf            = state[3];
    //TODO: Control SRAM init to only run one time
	always_ff @(posedge clk) begin
        case(state)
            IDLE: begin
                    state <= INIT_SRAM;
                  end
            CHECK_SRAM: begin
                        if(finish_writter)
                            state <= INIT_SRAM;
                        else 
                            state <= CHECK_SRAM;
                        end
            INIT_SRAM: begin
                        state <= WAIT_SRAM_DONE;
                      end
            WAIT_SRAM_DONE: begin
                                if(!finish_writter) begin
                                    s_address <= writter_address;
                                    s_data    <= writter_data;
                                    s_wren    <= writter_wren;
                                    state   <= WAIT_SRAM_DONE;
                                end
                                else
                                    state <= CHECK_LOOPER;
                            end
            CHECK_LOOPER: begin
									 if(secret_key == {{1'b0},{1'b1},{22{1'b0}}}) begin
										state <= FAILED_FINISH;
									 end
									 else begin
										 if(finish_second_loop)
											  state <= INIT_LOOPER;
										 else
											  state <= CHECK_LOOPER;
									 end
                         end
            INIT_LOOPER: begin
				                s_address <= looper_address;
                                s_data    <= looper_data;
                                s_wren    <= looper_wren;
                                state <= WAIT_LOOPER;
                         end
            WAIT_LOOPER: begin
                            if(!finish_second_loop) begin
                                s_address <= looper_address;
                                s_data    <= looper_data;
                                s_wren    <= looper_wren;
								state <= WAIT_LOOPER;
                            end 
                            else 
                                state <= CHECK_3_LOOP;
                         end
            CHECK_3_LOOP: begin
                            if(finish_third_loop)
                                state <= INIT_3_LOOP;
                            else
                                state <= CHECK_3_LOOP;
                          end
            INIT_3_LOOP: begin
                            s_address <= third_loop_s_address;
                            s_wren <= third_loop_s_wren;
                            s_data <= third_loop_s_data;
                            e_address <= third_loop_e_address;
                            d_address <= third_loop_d_address;
                            d_wren <= third_loop_d_wren;
                            d_data <= third_loop_d_data;
                            state <= WAIT_3_LOOP;
                         end
            WAIT_3_LOOP: begin
										 if(!finish_third_loop) begin
											  s_address <= third_loop_s_address;
											  s_wren <= third_loop_s_wren;
											  s_data <= third_loop_s_data;
											  e_address <= third_loop_e_address;
											  d_address <= third_loop_d_address;
											  d_wren <= third_loop_d_wren;
											  d_data <= third_loop_d_data;
											  state     <= WAIT_3_LOOP;
										 end
										 else begin
											if(!valid) begin
												secret_key <= secret_key + 1;
												state <= CHECK_SRAM;
											end
											else begin
											  state <= FINISH;
											end
										 end
                         end
				FAILED_FINISH: begin
										state <= FAILED_FINISH;
										finishing_sign = 8'b10000000;
									end
            FINISH: begin 
							state <= FINISH; finishing_sign = 8'b00000001;
						  end
            default: state <= IDLE;
        endcase
	end
	 
endmodule