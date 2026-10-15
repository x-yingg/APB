
module APB_System (
    input logic clk,
    input logic rst_n,

    // Incoming requests
    input logic read_i,
    input logic write_i,
    input logic [31:0] addr_i,
    input logic [31:0] wdata_i,

    // Read response
    output logic [31:0] rdata_o,
    output logic valid_o,

    // APB interface to the slave
    output logic psel_o,
    output logic penable_o,
    output logic [31:0] paddr_o,
    output logic pwrite_o,
    output logic [31:0] pwdata_o
);

    // --------------------------------
    // 1. Internal signals
    // --------------------------------

    localparam int REQ_W = 65;

    logic [REQ_W-1:0] fifo_push_data;
    logic [REQ_W-1:0] fifo_pop_data;

    logic fifo_push;
    logic fifo_pop;
    logic fifo_full;
    logic fifo_empty;

    logic fifo_ready;
    logic master_req;

    logic [31:0] master_addr;
    logic master_rnw;
    logic [31:0] master_wdata;

    logic        slave_ready;
    logic [31:0] slave_rdata;

    // --------------------------------
    // 2. FIFO input
    // --------------------------------

    assign fifo_push_data = {addr_i, ~write_i, wdata_i}; // will perform write only if both high
    assign fifo_push = (read_i || write_i) && !fifo_full;
    

    // --------------------------------
    // 3. FIFO
    // --------------------------------

    FIFO #(
        .DEPTH  (4),
        .DATA_W (REQ_W)
    ) u_fifo (
        .clk         (clk),
        .rst_n       (rst_n),
        .push_i      (fifo_push),
        .push_data_i (fifo_push_data),
        .pop_i       (fifo_pop),
        .pop_data_o  (fifo_pop_data),
        .full_o      (fifo_full),
        .empty_o     (fifo_empty)
    );


    // --------------------------------
    // 4. FIFO output -> APB Master
    // --------------------------------

    assign {master_addr, master_rnw, master_wdata}
        = fifo_pop_data;

    assign fifo_pop = fifo_ready && !fifo_empty;
    assign master_req = fifo_pop;


    // --------------------------------
    // 5. APB Master
    // --------------------------------

    APB_Master u_master (
        .clk          (clk),
        .rst_n        (rst_n),

        .req_i        (master_req),
        .addr_i       (master_addr),
        .rnw_i        (master_rnw),
        .wdata_i      (master_wdata),

        .rdata_o      (rdata_o),
        .valid_o      (valid_o),

        .fifo_ready_o (fifo_ready),

        .pready_i (slave_ready),
        .prdata_i (slave_rdata),

        .psel_o       (psel_o),
        .penable_o    (penable_o),
        .paddr_o      (paddr_o),
        .pwrite_o     (pwrite_o),
        .pwdata_o     (pwdata_o)
    );

    APB_Slave u_slave (
        .clk      (clk),
        .rst_n    (rst_n),

        .psel_i   (psel_o),
        .penable_i(penable_o),
        .paddr_i  (paddr_o),
        .pwrite_i (pwrite_o),
        .pwdata_i (pwdata_o),

        .pready_o (slave_ready),
        .prdata_o (slave_rdata)
    );

endmodule
