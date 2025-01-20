import "DPI-C" function int pmem_read(int addr);

import "DPI-C" function void pmem_write(
  int addr,
  int data,
  int mask
);

module ysyx_25010008_SRAM (
    input clk,
    input rst,

    input [31:0] araddr,
    input arvalid,
    output reg arready,

    input rready,
    output reg [31:0] rdata,
    output reg rresp,
    output reg rvalid,

    input [31:0] awaddr,
    input awvalid,
    output reg awready,

    input [31:0] wdata,
    input [31:0] wstrb,
    input wvalid,
    output reg wready,

    input bready,
    output reg bresp,
    output reg bvalid
);

  parameter HANDLE_RADDR = 0;
  parameter READING = 1;
  parameter HANDLE_RDATA = 2;

  parameter HANDLE_WADDR = 0;
  parameter HANDLE_WDATA = 1;
  parameter WRITING = 2;
  parameter HANDLE_BRESP = 3;

  reg [1:0] rstate, wstate;

  reg  [31:0] _araddr;
  reg  [31:0] _awaddr;
  reg  [31:0] _wdata;
  reg  [31:0] _wstrb;

  wire [ 7:0] delay;

  always @(posedge clk) begin
    if (rst) begin
      rstate  <= HANDLE_RADDR;
      wstate  <= HANDLE_WADDR;

      arready <= 1;
      rresp   <= 0;
      rvalid  <= 0;

      awready <= 1;
      wready  <= 1;

      bresp   <= 0;
      bvalid  <= 0;
    end else begin
      if (rstate == HANDLE_RADDR) begin
        if (arvalid) begin
          _araddr <= araddr;
          arready <= 0;
          rstate  <= READING;
        end
      end else if (rstate == READING) begin
        #delay rdata  <= pmem_read(_araddr);
        rvalid <= 1;
        rstate <= HANDLE_RDATA;
      end else begin
        if (rready) begin
          rvalid  <= 0;
          arready <= 1;
          rstate  <= HANDLE_RADDR;
        end
      end

      if (wstate == HANDLE_WADDR) begin
        if (awvalid) begin
          _awaddr <= awaddr;
          awready <= 0;
          wready  <= 1;
          wstate  <= HANDLE_WDATA;
        end
      end else if (wstate == HANDLE_WDATA) begin
        if (wvalid) begin
          _wdata <= wdata;
          _wstrb <= wstrb;
          wready <= 0;
          wstate <= WRITING;
        end
      end else if (wstate == WRITING) begin
        #delay pmem_write(_awaddr, _wdata, _wstrb);
        bvalid <= 1;
        wstate <= HANDLE_BRESP;
      end else begin
        if (bready) begin
          bvalid  <= 0;
          awready <= 1;
          wstate  <= HANDLE_WADDR;
        end
      end
    end
  end

  ysyx_25010008_LFSR lfsr (
      .clk (clk),
      .rst (rst),
      .dout(delay)
  );

endmodule
