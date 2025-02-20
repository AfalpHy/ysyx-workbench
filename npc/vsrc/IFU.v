import "DPI-C" function void set_pc(input [31:0] ptr[]);
import "DPI-C" function void set_write_back(input logic write_back[]);
import "DPI-C" function void set_inst(int inst);

module ysyx_25010008_IFU (
    input clock,
    input reset,

    input write_back,
    input [31:0] npc,
    output reg [31:0] pc,

    output reg [31:0] inst,
    output reg ivalid,

    output reg arvalid,
    input arready,

    output reg rready,
    input [31:0] rdata,
    input [1:0] rresp,
    input rvalid
);

  // set pointer of pc for cpp
  initial begin
    set_pc(pc);
    set_write_back(write_back);
  end

  always @(posedge clock) begin
    if (reset) begin
      pc <= 32'h3000_0000;
      arvalid <= 1;
      rready <= 0;
      ivalid <= 0;
    end else begin
      if (arvalid & arready) begin
        arvalid <= 0;
        rready  <= 1;
      end else if (rready & rvalid) begin
        if (rresp != 0) $finish;
        rready <= 0;
        inst   <= rdata;
        ivalid <= 1;
        set_inst(rdata);
      end else if (write_back) begin
        pc <= npc;
        arvalid <= 1;
        ivalid <= 0;
      end
    end
  end

endmodule
