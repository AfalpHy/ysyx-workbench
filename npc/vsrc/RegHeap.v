import "DPI-C" function void set_regs_ptr(input logic [31:0] ptr[]);

module RegHeap (
    input clk,
    input rst,

    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,

    input wen,
    input [31:0] wdata,

    output [31:0] src1,
    output [31:0] src2
);

  reg [31:0] regs[31:0];

  assign src1 = regs[rs1];
  assign src2 = regs[rs2];

  initial begin
    set_regs_ptr(regs);
  end

  // add or wen make imm of IDU right, which is weird, it's supposed to be figure out in future 
  always @(posedge clk or posedge wen) begin
    if (rst) for (int i = 0; i < 32; i = i + 1) regs[i] <= 0;
    else if (wen && rd != 0) regs[rd] <= wdata;
  end

endmodule
