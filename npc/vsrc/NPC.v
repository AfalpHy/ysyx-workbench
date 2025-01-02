module NPC (
    input clk,
    input rst
);

  reg [31:0] pc;

  wire [31:0] snpc = pc + 4;

  always @(posedge clk) begin
    if (rst) begin
      pc <= 32'h8000_0000;
    end
  end
endmodule
