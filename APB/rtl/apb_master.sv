module APB_Master(
    input logic        clk,
    input logic        rst_n,

    // Interface to the external world
    input logic        req_i,
    input logic [31:0] addr_i,
    input logic        rnw_i,
    input logic [31:0] wdata_i,

    output logic [31:0] rdata_o,
    output logic        valid_o,

    // Interface to the APB Slave
    input logic         pready_i,
    input logic [31:0]  prdata_i,

    output logic        psel_o,
    output logic        penable_o,
    output logic [31:0] paddr_o,
    output logic        pwrite_o,
    output logic [31:0] pwdata_o
);

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } state_t;

    state_t current_state, next_state;

    // Captured request
    logic [31:0] addr_reg;
    logic        rnw_reg;
    logic [31:0] wdata_reg;


    // ============================================================
    // Sequential Logic
    // ============================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;

            addr_reg      <= 32'b0;
            rnw_reg       <= 1'b0;
            wdata_reg     <= 32'b0;

            rdata_o       <= 32'b0;
            valid_o       <= 1'b0;
        end
        else begin
            current_state <= next_state;

            // valid_o is a one-cycle pulse
            valid_o <= 1'b0;

            // ----------------------------------------------------
            // Accept a new request
            // ----------------------------------------------------
            if (current_state == IDLE && req_i) begin
                addr_reg  <= addr_i;
                rnw_reg   <= rnw_i;
                wdata_reg <= wdata_i;
            end

            // ----------------------------------------------------
            // Complete a READ transaction
            // ----------------------------------------------------
            if (current_state == ACCESS &&
                pready_i &&
                rnw_reg) begin

                rdata_o <= prdata_i;
                valid_o <= 1'b1;
            end
        end
    end


    // ============================================================
    // Combinational Logic
    // ============================================================
    always_comb begin

        // Default outputs
        next_state = current_state;

        psel_o     = 1'b0;
        penable_o  = 1'b0;

        paddr_o    = addr_reg;
        pwrite_o   = ~rnw_reg;
        pwdata_o   = wdata_reg;

        case (current_state)

            // ----------------------------------------------------
            // IDLE
            // ----------------------------------------------------
            IDLE: begin

                if (req_i) begin
                    next_state = SETUP;
                end

            end


            // ----------------------------------------------------
            // SETUP
            // ----------------------------------------------------
            SETUP: begin

                psel_o    = 1'b1;
                penable_o = 1'b0;

                next_state = ACCESS;

            end


            // ----------------------------------------------------
            // ACCESS
            // ----------------------------------------------------
            ACCESS: begin

                psel_o    = 1'b1;
                penable_o = 1'b1;

                // Stay in ACCESS until the slave completes
                if (pready_i) begin
                    next_state = IDLE;
                end

            end


            default: begin
                next_state = IDLE;
            end

        endcase
    end

endmodule