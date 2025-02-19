import "DPI-C" function void set_skip_ref_inst();

module ysyx_25010008_LSU (
    input clock,
    input reset,

    input suffix_b,
    input suffix_h,
    input sext,

    input ren,

    input wen,

    input [31:0] addr,
    output reg [31:0] mem_rdata,
    output reg done,

    output reg [31:0] araddr,
    output reg [2:0] arsize,
    output reg arvalid,
    input arready,

    output reg rready,
    input [31:0] rdata,
    input [1:0] rresp,
    input rvalid,

    output reg [31:0] awaddr,
    output reg [2:0] awsize,
    output reg awvalid,
    input awready,

    input [31:0] wsrc,
    output reg [31:0] wdata,
    output reg [3:0] wstrb,
    output reg wvalid,
    input wready,

    output reg bready,
    input [1:0] bresp,
    input bvalid
);

  parameter IDLE = 0;
  parameter TRANSFER_RADDR = 1;
  parameter TRANSFER_RDATA = 2;
  parameter TRANSFER_WADDR = 3;
  parameter TRANSFER_WDATA = 4;
  parameter TRANSFER_BRESP = 5;
  parameter WRITE_BACK = 6;

  reg [2:0] state;

  assign araddr = addr;
  assign awaddr = addr;

  assign wdata  = (suffix_b | suffix_h) ? (wsrc << {addr[1:0], 3'b0}) : wsrc;
  assign wstrb  = (suffix_b ? 4'b0001 : (suffix_h ? 4'b0011 : 4'b1111)) << addr[1:0];

  wire [31:0] real_rdata = (suffix_b | suffix_h) ? (rdata >> {addr[1:0], 3'b0}) : rdata;
  wire [31:0] sextb = {{24{real_rdata[7]}}, real_rdata[7:0]};
  wire [31:0] sexth = {{16{real_rdata[15]}}, real_rdata[15:0]};
  wire [31:0] sign_data = suffix_b ? sextb : sexth;
  wire [31:0] extb = {24'b0, real_rdata[7:0]};
  wire [31:0] exth = {16'b0, real_rdata[15:0]};
  wire [31:0] unsign_data = suffix_b ? extb : (suffix_h ? exth : real_rdata);

  always @(posedge clock) begin
    if (reset) begin
      arvalid <= 0;
      rready  <= 0;

      awvalid <= 0;
      wvalid  <= 0;
      bready  <= 0;

      state   <= IDLE;
    end else begin
      if (state == IDLE) begin
        if (ren) begin
          arvalid <= 1;
          arsize  <= suffix_b ? 0 : suffix_h ? 1 : 2;
          state   <= TRANSFER_RADDR;
        end else if (wen) begin
          awvalid <= 1;
          awsize  <= suffix_b ? 0 : suffix_h ? 1 : 2;
          state   <= TRANSFER_WADDR;
        end
      end else if (state == TRANSFER_RADDR) begin
        if (arready) begin
          if (araddr[31:12] == 20'h1_0000 || araddr[31:24] == 8'h02)
            set_skip_ref_inst();  //uart or clint
          arvalid <= 0;
          rready  <= 1;
          state   <= TRANSFER_RDATA;
        end
      end else if (state == TRANSFER_RDATA) begin
        if (rvalid) begin
          rready <= 0;
          mem_rdata <= sext ? sign_data : unsign_data;
          done <= 1;
          state <= WRITE_BACK;
        end
      end else if (state == TRANSFER_WADDR) begin
        if (awready) begin
          if (awaddr[31:12] == 20'h1_0000) set_skip_ref_inst();  //uart
          awvalid <= 0;
          wvalid  <= 1;
          state   <= TRANSFER_WDATA;
        end
      end else if (state == TRANSFER_WDATA) begin
        if (wready) begin
          wvalid <= 0;
          bready <= 1;
          state  <= TRANSFER_BRESP;
        end
      end else if (state == TRANSFER_BRESP) begin
        if (bvalid) begin
          bready <= 0;
          done   <= 1;
          state  <= WRITE_BACK;
        end
      end else begin
        done  <= 0;
        state <= IDLE;
      end
    end
  end

endmodule
