module ALU (
    input [4:0] opcode,
    input [31:0] opearnd1,
    input [31:0] operand2,
    output [31:0] result,
    output zero
);

  assign result = opearnd1 + operand2;

endmodule
