interface apb_if;

    // =========================
    // APB signals
    // =========================

    // Master → Slave
    logic        psel;
    logic        penable;
    logic        pwrite;
    logic [31:0] paddr;
    logic [31:0] pwdata;

    // Slave → Master
    logic [31:0] prdata;
    logic        pready;


    // =========================
    // Master view
    // =========================

    modport master (
        output psel,
        output penable,
        output pwrite,
        output paddr,
        output pwdata,

        input  prdata,
        input  pready
    );


    // =========================
    // Slave view
    // =========================

    modport slave (
        input  psel,
        input  penable,
        input  pwrite,
        input  paddr,
        input  pwdata,

        output prdata,
        output pready
    );

endinterface

