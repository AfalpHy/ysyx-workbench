module ALU (
    input      [2:0] OP,
    input      [3:0] A,
    input      [3:0] B,
    output reg [3:0] result,
    output reg       carry,
    output reg       zero,
    output reg       overflow,
    output reg [7:0] seg0,
    output reg [7:0] seg1
);

  reg [2:0] num;

  wire [3:0] tmpB = ~B + 1;
  always @(OP or A or B) begin
    case (OP)
      3'b000:  {carry, result} = A + B;
      3'b001:  {carry, result} = A - B;
      3'b010:  result = ~A;
      3'b011:  result = A & B;
      3'b100:  result = A | B;
      3'b101:  result = A ^ B;
      3'b110:  result = {3'b000, A < B};
      default: result = {3'b000, A == B};
    endcase
    zero = result == 0;
    overflow = (OP == 3'b000) ? 
           ((result[3] & ~A[3] & ~B[3]) | (~result[3] & A[3] & B[3])) :
           (OP == 3'b001) ? 
           ((result[3] & ~A[3] & ~tmpB[3]) | (~result[3] & A[3] & tmpB[3])) : 
           0;

  end


  always @(result) begin
    if (result[3] == 0) begin
      seg1 = 8'b1111_1111;  // 正数符号为空 
      num  = result[2:0];
    end else begin
      seg1 = 8'b1111_1101;  // 负号
      num  = ~result[2:0] + 1;
    end
  end

  bcd7seg b1 (
      num,
      seg0
  );

endmodule
