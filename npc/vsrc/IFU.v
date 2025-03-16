import "DPI-C" function void set_pc(input [31:0] ptr[]);
import "DPI-C" function void ifu_record0();
import "DPI-C" function void ifu_record1(
  int inst,
  int npc
);

module ysyx_25010008_IFU (
    input clock,
    input reset,

    input write_back,
    input [31:0] npc,
    output reg [31:0] pc,

    output reg [31:0] inst,
    output reg ivalid,
    input iready,

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
        if (rresp != 0) begin
          $display("%h", pc);
          $finish;
        end
        rready <= 0;
        inst   <= rdata;
        ivalid <= 1;
        ifu_record0();
      end else if (ivalid & iready) begin
        ivalid <= 0;
      end else if (write_back) begin
        pc <= npc;
        arvalid <= 1;
        ifu_record1(inst, npc);
      end
    end
  end

endmodule
