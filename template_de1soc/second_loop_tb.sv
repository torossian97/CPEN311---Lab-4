module second_loop_tb();

    logic clk, start; //input
    logic [7:0] s_ram_data_out = 0;
    logic [23:0] secret_key = 24'b000000000000000000000000;
    logic wren, finish; //output
    logic [7:0] data, address;
	logic [7:0] RAM [7:0];
	
	assign RAM [0] = 8'b00000000;
	assign RAM [1] = 8'b00000001;
	assign RAM [2] = 8'b00000010;
	assign RAM [3] = 8'b00000011;
	assign RAM [4] = 8'b00000100;
	assign RAM [5] = 8'b00000101;
	assign RAM [6] = 8'b00000110;
	assign RAM [7] = 8'b00000111;

second_loop inst_1(
                   .clk(clk), //input
                   .start(start),
                   .s_ram_data_out(RAM[address]),
                   .secret_key(secret_key),
                   .wren(wren), //output
                   .finish(finish),
                   .data(data),
                   .address(address)
                  );

task clk_cycle();
    #5 clk = ~clk; #5 clk = ~clk;
endtask

initial begin
    clk = 0;
end

initial begin
    clk_cycle();
	clk_cycle();
    start = 1;
    clk_cycle();
    clk_cycle();
    start = 0;
        clk_cycle();
    clk_cycle();
        clk_cycle();
    clk_cycle();
    repeat (128) begin
		clk_cycle();
	end

end

endmodule