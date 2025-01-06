import "DPI-C" function int pmem_read(
  int addr,
  int len
);

module IFU (
    input clk,
    input [31:0] pc,
    output reg [31:0] inst
);

  always @(posedge clk) begin
    inst = pmem_read(pc, 4);
  end

endmodule
