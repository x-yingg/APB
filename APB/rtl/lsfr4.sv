// --- 1. The LFSR Module (Generates the random sequence) ---
module LFSR4 (
    input  logic       clk,
    input  logic       rst_n,
    output logic [3:0] lfsr_o
);
    logic [3:0] lfsr_q;
    logic       feedback;

    // XOR taps at bit 3 and 2
    assign feedback = lfsr_q[3] ^ lfsr_q[2];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_q <= 4'b0001; // Never initialize to 0
        end 
        else begin
            lfsr_q <= {lfsr_q[2:0], feedback}; // Shift left and append feedback
        end
    end

    assign lfsr_o = lfsr_q;
endmodule

