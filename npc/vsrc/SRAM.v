import "DPI-C" function int pmem_read(
  int addr,
  int len
);

import "DPI-C" function void pmem_write(
  int addr,
  int data,
  int len
);

module ysyx_25010008_SRAM (
    input clk,

    input ren,
    input [31:0] raddr,

    input wen,
    input [31:0] waddr,
    input [31:0] wdata,

    input [2:0] len,
    output reg [31:0] rdata
);

  always @(posedge clk) begin
    if (ren) rdata <= pmem_read(raddr, {29'b0, len});
    if (wen) pmem_write(waddr, wdata, {29'b0, len});
  end

endmodule
