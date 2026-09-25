module APB_Slave (
    // System Signals
    input  logic       clk,
    input  logic       rst_n,

    // APB Interface (Connected to Master)
    input  logic        psel_i,
    input  logic        penable_i,
    input  logic [31:0] paddr_i,
    input  logic        pwrite_i,
    input  logic [31:0] pwdata_i,

    output logic        pready_o,
    output logic [31:0] prdata_o
);

    // Internal wires to connect to the Day 17 Memory
    logic        mem_req;
    logic        mem_rnw;
    logic [3:0]  mem_addr;
    logic [31:0] mem_wdata;
    logic        mem_ready;
    logic [31:0] mem_rdata;

    // --- PROTOCOL TRANSLATION (The Bridge) ---
    
    // Only send the request pulse during APB SETUP phase (psel=1, penable=0)
    assign mem_req   = psel_i & ~penable_i; 
    
    // Invert pwrite (APB write=1, Memory write=0)
    assign mem_rnw   = ~pwrite_i;           
    
    // Day 17 memory only has 16 slots, so we only need the bottom 4 bits of the APB address
    assign mem_addr  = paddr_i[3:0];        
    
    // Pass data directly
    assign mem_wdata = pwdata_i;
    assign pready_o  = mem_ready;
    assign prdata_o  = mem_rdata;

    // --- DAY 17 INSTANTIATION ---
    
    MemoryInterfaceSlave day17_memory (
        .clk         (clk),
        .rst_n       (rst_n),
        .req_i       (mem_req),
        .req_rnw_i   (mem_rnw),
        .req_addr_i  (mem_addr),
        .req_wdata_i (mem_wdata),
        .req_ready_o (mem_ready),
        .req_rdata_o (mem_rdata)
    );

endmodule