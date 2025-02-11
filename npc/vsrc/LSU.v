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
    output reg read_done,
    output reg write_done,

    output reg [31:0] araddr,
    output reg arvalid,
    input arready,

    output reg rready,
    input [31:0] rdata,
    input [1:0] rresp,
    input rvalid,

    output reg [31:0] awaddr,
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
  parameter HANDLE_RADDR = 1;
  parameter HANDLE_RDATA = 2;
  parameter HANDLE_WADDR = 3;
  parameter HANDLE_WDATA = 4;
  parameter HANDLE_BRESP = 5;
  parameter WRITE_BACK = 6;

  reg [2:0] state;

  assign araddr = addr;
  assign awaddr = addr;

  assign wdata = suffix_b ? (wsrc << {addr[1:0], 3'b0}) : (suffix_h ? (wsrc << {addr[1:0], 3'b0}) : wsrc);
  assign wstrb = suffix_b ? (4'b0001 << addr[1:0]) : (suffix_h ? (4'b0011 << addr[1:0]) : 4'b1111);

  wire [31:0] real_rdata = suffix_b ? (rdata >> {addr[1:0], 3'b0}) : (suffix_h ? (rdata >> {addr[1:0], 3'b0}) : rdata);
  wire [31:0] sextb = {{24{rdata[7]}}, real_rdata[7:0]};
  wire [31:0] sexth = {{16{rdata[15]}}, real_rdata[15:0]};

  always @(posedge clock) begin
    if (reset) begin
      arvalid <= 0;
      rready  <= 1;

      awvalid <= 0;
      wvalid  <= 0;

      bready  <= 1;
      state   <= IDLE;
    end else begin
      if (state == IDLE) begin
        if (ren) begin
          arvalid <= 1;
          state   <= HANDLE_RADDR;
        end
        if (wen) begin
          awvalid <= 1;
          state   <= HANDLE_WADDR;
        end
      end else if (state == HANDLE_RADDR) begin
        if (arready) begin
          arvalid <= 0;
          rready  <= 1;
          state   <= HANDLE_RDATA;
        end
      end else if (state == HANDLE_RDATA) begin
        if (rvalid) begin
          rready <= 0;
          mem_rdata  <= sext ? (suffix_b ? sextb : sexth ) :
          (suffix_b ? {24'b0, real_rdata[7:0]} :
          (suffix_h ? {16'b0, real_rdata[15:0]} : real_rdata));
          read_done <= 1;
          state <= WRITE_BACK;
        end
      end else if (state == HANDLE_WADDR) begin
        if (awready) begin
          if (awaddr == 32'h10000000) $display("%c",wdata[7:0]);
          if (awaddr[31:12] == 20'h1_0000) set_skip_ref_inst();  //uart
          awvalid <= 0;
          wvalid  <= 1;
          state   <= HANDLE_WDATA;
        end
      end else if (state == HANDLE_WDATA) begin
        if (wready) begin
          wvalid <= 0;
          bready <= 1;
          state  <= HANDLE_BRESP;
        end
      end else if (state == HANDLE_BRESP) begin
        if (bvalid) begin
          bready <= 0;
          write_done <= 1;
          state <= WRITE_BACK;
        end
      end else begin
        if (read_done) read_done <= 0;
        if (write_done) write_done <= 0;
        state <= IDLE;
      end
    end
  end

endmodule
