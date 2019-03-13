module memory_write_tb();

    logic clk;
    logic start;
    logic finish;
	logic wren;
	logic [7:0] address;
	logic [7:0] data;
	logic [7:0] counter;

    memory_write writter_1(.clk(clk),
							.start(start),
							.wren(),
							.address(address),
							.data(data),
							.finish(finish)
							);

    initial begin
        clk = 1'b0;
		counter = 8'b0;
        start = 1'b0;
    end


    task clk_cycle();
        #5 clk = ~clk; #5 clk = ~clk;
    endtask
	
	task RAM();
		if (counter == 255) begin end
		else begin
			assert (counter == data) $display ("Data is ok");
			else $error("Data is INCORRECT");
			assert (counter == address) $display ("Address is OK");
			else $error("Address is INCORRECT");
			counter = counter + 1;
		end
    endtask 

    initial begin
        clk_cycle();
        start = 1'b1;
        clk_cycle();
        start = 1'b0;
        repeat (257) begin
			RAM();
			clk_cycle();
		end
        $stop;
    end


endmodule