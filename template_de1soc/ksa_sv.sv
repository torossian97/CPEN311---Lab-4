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

    parameter IDLE           = 5'b000_00;
    parameter CHECK_SRAM     = 5'b110_00;
    parameter INIT_SRAM      = 5'b001_01;
    parameter WAIT_SRAM_DONE = 5'b010_00;
    parameter CHECK_LOOPER   = 5'b101_00;
    parameter INIT_LOOPER    = 5'b011_10;
    parameter WAIT_LOOPER    = 5'b111_00;
    parameter FINISH         = 5'b100_00;
   
    logic clk;
    logic reset_n;
    logic [6:0] ssOut;
    logic [3:0] nIn;
	logic is_mem_init = 1'b0;
	logic start_writter;
	logic finish_writter;
    logic start_second_loop;
    logic finish_second_loop;
    logic [23:0] secret_key = 24'b00000000_00000010_01001001; 
    
    assign clk = CLOCK_50;
    assign reset_n = KEY[3];

    
    logic [4:0] state;
   
    logic [7:0] writter_address;
    logic [7:0] writter_data;
    logic [7:0] looper_address;
    logic [7:0] looper_data;
    logic writter_wren;
    logic looper_wren;
    logic [7:0] address;
    logic [7:0] data;
    logic wren;
    logic [7:0] q;
	assign LEDR[7:0] = 8'b0;
    SevenSegmentDisplayDecoder mod (.nIn(nIn), .ssOut(ssOut));
	memory_write writter_1(.clk(clk), .start(start_writter), .finish(finish_writter), .address(writter_address), .wren(writter_wren), .data(writter_data));
    second_loop loop_1(.clk(clk), .start(start_second_loop), .finish(finish_second_loop), .secret_key(secret_key) ,.s_ram_data_out(q), .wren(looper_wren), .address(looper_address), .data(looper_data));

    s_memory memory_1(.clock(clk), .data(data), .address(address), .wren(wren), .q(q));


    // Link start writter trigger to state output index 0
    assign start_writter       = state[0];
    assign start_second_loop   = state[1];
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
                                    address <= writter_address;
                                    data    <= writter_data;
                                    wren    <= writter_wren;
                                    state   <= WAIT_SRAM_DONE;
                                end
                                else
                                    state <= CHECK_LOOPER;
                            end
            CHECK_LOOPER: begin
                            if(finish_second_loop)
                                state <= INIT_LOOPER;
                            else
                                state <= CHECK_LOOPER;
                         end
            INIT_LOOPER: begin
				                address <= looper_address;
                            data    <= looper_data;
                            wren    <= looper_wren;
                            state <= WAIT_LOOPER;
                         end
            WAIT_LOOPER: begin
                            if(!finish_second_loop) begin
                                address <= looper_address;
                                data    <= looper_data;
                                wren    <= looper_wren;
										  state <= WAIT_LOOPER;

                            end 
                            else 
                                state <= FINISH;
                         end
            FINISH: state <= FINISH;           
            default: state <= IDLE;
        endcase
	end
	 
endmodule