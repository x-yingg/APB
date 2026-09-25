module arbiter (
    input  logic read_i,
    input logic write_i,

    output logic valid_o,
    output logic  rnw_o
);

    assign rnw_o = read_i & ~write_i;
    assign valid_o = read_i | write_i;

endmodule