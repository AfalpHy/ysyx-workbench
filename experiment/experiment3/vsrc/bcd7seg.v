module bcd7seg (
    input [2:0] b,
    output reg [7:0] h
);

  always @(b) begin
    case (b)
      3'b000: h = 8'b0000_0011;
      3'b001: h = 8'b1001_1111;
      3'b010: h = 8'b0010_0101;
      3'b011: h = 8'b0000_1101;
      3'b100: h = 8'b1001_1001;
      3'b101: h = 8'b0100_1001;
      3'b110: h = 8'b0100_0001;
      3'b111: h = 8'b0001_1111;
    endcase
  end

endmodule