import "DPI-C" function void set_memory_ptr(input logic [31:0] ptr[]);

module ysyx_25010008_LSU (
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

  assign rdata = sext ? (suffix_b ? (tmp | ({32{tmp[7]}} << 8)):(tmp | ({32{tmp[15]}} << 16))): tmp;

  ysyx_25010008_SRAM sram (
      .clk(clk),

      .ren  (ren),
      .raddr(raddr),

      .wen  (wen),
      .waddr(waddr),
      .wdata(wdata),

      .len  (suffix_b ? 1 : (suffix_h ? 2 : 4)),
      .rdata(tmp)
  );

endmodule
