/* Memory_write: FSM Used to write to memory file
 *
 * The FSM operates using START/FINISH protocol to implement the following logic
 * 
 * for i = 0 to 255 {
 *  s[i] = i;   
 * }
 *
 * Where s defines in-memory, and s[i] is address i of memory
 */

 module memory_write #(parameter N = 255) 
                      (
                        input logic clk,
                        input logic start,
                        output logic wren,
                        output logic [7:0] address,
                        output logic [7:0] data,
                        output logic finish
                      );
   
    parameter IDLE = 2'b10;
    parameter WRITTING = 2'b01;

    logic [1:0] state;
    logic [7:0] count = 1'b0;
    logic [7:0] q;
    assign wren = state[0];
    assign finish = state[1];
    assign address = count;
    assign data = count;

    always_ff @(posedge clk) begin
        case(state)
            IDLE:     begin
                        if(start)
                            state <= WRITTING;
                        count <= 1'b0;        
                      end
            WRITTING: begin
                        if (count == N)
                            state <= IDLE;
                        else begin
                            count = count + 1'b1;
                        end
                      end
            default: state <= IDLE;
        endcase            
    end

 endmodule