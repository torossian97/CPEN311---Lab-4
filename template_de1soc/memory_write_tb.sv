module memory_write_tb();

    logic clk;
    logic start;
    logic finish;

    memory_write writter_1(.*);

    initial begin
        clk = 1'b0;
        start = 1'b0;
    end


    task clk_cycle();
        #5 clk = ~clk; #5 clk = ~clk;
    endtask 

    initial begin
        clk_cycle();
        start = 1'b1;
        clk_cycle();
        start = 1'b0;
        repeat (257) clk_cycle();
        $stop;
    end


endmodule