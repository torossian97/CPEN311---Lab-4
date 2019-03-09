module second_loop_tb();

    logic clk, start; //input
    logic [7:0] s_ram_data_out = 0;
    logic [23:0] secret_key = 24'b000000000000001001001001;
    logic wren, finish; //output
    logic [7:0] data, address;

second_loop inst_1(
                   .clk(clk), //input
                   .start(start),
                   .s_ram_data_out(s_ram_data_out),
                   .secret_key(secret_key),
                   .wren(wren), //output
                   .finish(finish),
                   .data(data),
                   .address(address)
                  );

task clk_cycle();
    #5 clk = ~clk; #5 clk = ~clk;
endtask

task increment_out();
    s_ram_data_out = s_ram_data_out + 1;
endtask

initial begin
    clk = 0;
end

initial begin
    clk_cycle();
    start = 1;
    clk_cycle();
    clk_cycle();
    start = 0;
        clk_cycle();
    clk_cycle();
        clk_cycle();
    increment_out();
    clk_cycle();
    repeat (16) clk_cycle();

end

endmodule