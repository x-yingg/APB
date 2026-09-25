module FIFO #(
  parameter DEPTH  = 4,
  parameter DATA_W = 4
)(
  input  logic             clk,
  input  logic             rst_n,

  input  logic             push_i,
  input  logic [DATA_W-1:0] push_data_i,

  input  logic             pop_i,
  output logic [DATA_W-1:0] pop_data_o,

  output logic             full_o,
  output logic             empty_o
);

    // 1. Storage
    logic [DATA_W-1:0] mem [0:DEPTH-1]; // depth - how many room, data - how much space each room
    // 2. Pointers
    logic [$clog2(DEPTH)-1:0] write_ptr; 
    //ceiling of the base-2 logarith - eg. if Depth is 4, need 2 bits (0-3), log2(4) = 2, get [1:0]
    logic [$clog2(DEPTH)-1:0] read_ptr;

    // 3. Number of items
    logic [$clog2(DEPTH+1)-1:0] count; // 0=empty, 1, 2, 3, 4=full; need 3 bits (4 is 100), log2(5)=2.32

    // 4. Full / empty
    assign full_o  = (count == DEPTH);
    assign empty_o = (count == 0);

    // 5. Sequential logic
   always_ff @(posedge clk or negedge rst_n)

        if (!rst_n) begin
            write_ptr <= 0;
            read_ptr  <= 0;
            count     <= 0;
            pop_data_o <= 0;
        end

        else begin

            // PUSH
            if (push_i && !full_o) begin
                mem[write_ptr] <= push_data_i;

                if (write_ptr == DEPTH-1)
                    write_ptr <= 0;
                else
                    write_ptr <= write_ptr + 1;
            end

            // POP
            if (pop_i && !empty_o) begin
                pop_data_o <= mem[read_ptr];

                if (read_ptr == DEPTH-1)
                    read_ptr <= 0;
                else
                    read_ptr <= read_ptr + 1;
            end

            // COUNT
            case ({push_i && !full_o, pop_i && !empty_o})
                2'b10: count <= count + 1;
                2'b01: count <= count - 1;
                default: count <= count;
            endcase

        end
    end

endmodule