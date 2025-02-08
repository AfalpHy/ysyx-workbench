module ysyx_25010008_ALU (
    input  [ 7:0] opcode,
    input  [31:0] operand1,
    input  [31:0] operand2,
    output [31:0] result
);
  wire carry;
  wire [31:0] add_opearnd2 = opcode[0] ? ~operand2 + 1 : operand2;
  wire [31:0] add_result;
  assign {carry, add_result} = operand1 + add_opearnd2;
  wire [31:0] xor_result = opcode[1] ? operand1 ^ operand2 : 0;
  wire [31:0] or_result = opcode[2] ? operand1 | operand2 : 0;
  wire [31:0] and_result = opcode[3] ? operand1 & operand2 : 0;
  wire [31:0] logic_left_shift_result = opcode[4] ? operand1 << operand2[4:0] : 0;
  wire [31:0] logic_right_shift_result = opcode[5] ? operand1 >> operand2[4:0] : 0;
  wire [31:0] arithmetic_right_shift_result = opcode[6] ? $signed(operand1) >>> operand2[4:0] : 0;
  wire [31:0] bitwise_not_and = opcode[7] ? ~operand1 & operand2 : 0;
  wire eq = operand1 == operand2;
  wire ne = operand1 != operand2;
  wire ltu = carry;
  wire geu = ~carry;
  // look sign of result if operand1 and operand2 have the same sign
  wire lt = operand1[31] == operand2[31] ? add_result[31] : operand1[31];
  // look sign of result if operand1 and operand2 have the same sign
  wire ge = operand1[31] == operand2[31] ? ~add_result[31] : ~operand1[31];

  wire cmp_result = (eq & opcode[1]) | (ne & opcode[2]) | (ltu & opcode[3]) | (geu & opcode[4]) | (lt & opcode[5]) |(ge & opcode[6]);

  assign result = opcode[7:1] == 0 ? add_result : (opcode[0]? {{31{1'b0}}, cmp_result} : (xor_result | or_result | and_result | logic_left_shift_result | logic_right_shift_result | arithmetic_right_shift_result | bitwise_not_and));

endmodule
