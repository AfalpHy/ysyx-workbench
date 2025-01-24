import "DPI-C" function void set_pc(input [31:0] ptr[]);
import "DPI-C" function void set_write_back(input logic write_back[]);

module ysyx_25010008_IFU (
    input clock,
    input reset,

    input write_back,
    input [31:0] npc,
    output reg [31:0] pc,

    output reg [31:0] inst,
    output reg ivalid,

    output reg pvalid,
    input pready,

    output reg rready,
    input [31:0] rdata,
    input [1:0] rresp,
    input rvalid
);

  parameter IDLE = 0;
  parameter HANDLE_PC = 1;
  parameter HANDLE_INST = 2;

  reg [1:0] state;

  // set pointer of pc for cpp
  initial begin
    set_pc(pc);
    set_write_back(write_back);
  end

  always @(posedge clock) begin
    if (reset) begin
      pc <= 32'h2000_0000;
      pvalid <= 1;
      rready <= 1;
      ivalid <= 0;
      state <= HANDLE_PC;
    end else begin
      if (state == IDLE) begin
        if (write_back) begin
          pc <= npc;
          pvalid <= 1;
          ivalid <= 0;
          state <= HANDLE_PC;
        end
      end else if (state == HANDLE_PC) begin
        if (pready) begin
          pvalid <= 0;
          rready <= 1;
          state  <= HANDLE_INST;
          $display("%h",rdata);
        end
      end else begin
        if (rvalid) begin
          rready <= 0;
          inst   <= rdata;
          ivalid <= 1;
          state  <= IDLE;
          $display("%h",rdata);
        end
      end
    end
  end

endmodule
