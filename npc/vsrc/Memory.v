import "DPI-C" function void set_memory_ptr(input logic [31:0] ptr[]);

import "DPI-C" function void pmem_write(
  int addr,
  int data,
  int len
);

module Memory (
    input clk,

    input suffix_b,
    input suffix_h,
    input sext,

    input ren,
    input [31:0] raddr,

    input wen,
    input [31:0] waddr,
    input [31:0] wdata,

    output reg [31:0] rdata
);

  reg [31:0] memory['h1000_0000-1:0];

  initial begin
    set_memory_ptr(memory);
  end

  integer tmp;

  always @(posedge clk or posedge ren) begin
    if (ren) begin
      if (suffix_b) begin
        tmp = pmem_read(raddr, 1);
        if (sext) tmp = tmp | ({32{tmp[7]}} << 8);
        rdata = tmp;
      end else if (suffix_h) begin
        tmp = pmem_read(raddr, 2);
        if (sext) tmp = tmp | ({32{tmp[15]}} << 16);
        rdata = tmp;
      end else rdata = pmem_read(raddr, 4);
    end
  end

  always @(negedge clk) begin
    if (wen) pmem_write(waddr, wdata, suffix_b ? 1 : (suffix_h ? 2 : 4));
  end
endmodule
