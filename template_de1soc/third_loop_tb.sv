module third_loop_tb();

    logic clk;
    logic start;
    logic [7:0] s_ram_q;
    logic [7:0] e_rom_q;
    logic s_wren;
    logic d_wren;
    logic [7:0] s_address;    
    logic [7:0] d_address;
    logic [7:0] e_address;
    logic [7:0] d_data;
    logic [7:0] s_data;    
    logic valid;
    logic finish;

    third_loop l3(.*);

    initial begin
        clk = 0;
        start = 0;
        s_ram_q = 0;
        e_rom_q = 0;
    end

    task clk_cycle();
        #5 clk = ~clk; #5 clk = ~clk;
    endtask

    initial begin
        repeat (2) clk_cycle();
        start = 1;
        repeat (5) clk_cycle();
        s_ram_q = 8'b00000001;
        repeat (3) clk_cycle();
        start = 0;
        repeat (8) clk_cycle(); //180
        s_ram_q = 8'b01101111;
        repeat (7) clk_cycle(); //225
        repeat (6) clk_cycle();
        s_ram_q = 2;
        repeat(25) clk_cycle();
        $stop;
    end

endmodule