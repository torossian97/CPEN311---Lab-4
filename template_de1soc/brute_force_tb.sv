module brute_force_tb();

    logic clk, start; //input
    logic [255:0] decoded_data = 256'b01101001_00100000_01101100_01101001_01101011_01100101_00100000_01100111_01110010_01100101_01100101_01101110_00100000_01100101_01100111_01100111_01110011_00100000_01100001_01101110_01100100_00100000_01101000_01100001_01101101_00100000_01111001_01100101_01110011_01110011_01110011_01110011;
	logic [255:0] decoded_data_bad = 256'b01101001_00100000_01101100_01101001_01101011_01100101_00100000_01100111_01110010_01100101_01100101_01101110_00100000_01110000_01100111_01100111_01110011_00100000_01100001_01101110_01100100_00100000_01101000_01100001_01101101_00100000_01111001_01100101_01110011_01110011_01110011_01110011;
    logic [23:0] secret_key = 24'b000000000000001001001001;
    logic finish; //output
    logic [7:0] state;

brute_force inst_1(
                 .clk(clk),
				 .start(start),
				 .decoded_data(decoded_data),
				 .secret_key(secret_key),
				 .finish(finish)
                  );

task clk_cycle();
    #5 clk = ~clk; #5 clk = ~clk;
endtask

initial begin
    clk = 0;
end

initial begin
    clk_cycle();
    start = 1;
    clk_cycle();
	start = 0;
    clk_cycle();
    clk_cycle();
    clk_cycle();
    clk_cycle();
	start = 1;
	clk_cycle();
	start = 0;
    repeat (66) clk_cycle();
	decoded_data = decoded_data_bad;
	clk_cycle();
    start = 1;
    clk_cycle();
	start = 0;
    clk_cycle();
    clk_cycle();
    clk_cycle();
    clk_cycle();
	start = 1;
	clk_cycle();
	start = 0;
    repeat (66) clk_cycle();
	

end

endmodule