import "DPI-C" function void set_memory_ptr(input logic [31:0] ptr[]);

module ysyx_25010008_LSU (
    input clock,
    input reset,

    input suffix_b,
    input suffix_h,
    input sext,

    input ren,

    input wen,

    output reg [31:0] rdata,
    output reg read_done,
    output reg write_done,

    output reg arvalid,
    input arready,

    output reg rready,
    input [31:0] tmp,
    input [1:0] rresp,
    input rvalid,

    output reg awvalid,
    input awready,

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

  reg [ 2:0] state;

  reg [31:0] memory['h1000_0000-1:0];

  initial begin
    set_memory_ptr(memory);
  end

  assign wstrb = suffix_b ? 4'b0001 : (suffix_h ? 4'b0011 : 4'b1111);

  wire [31:0] sextb = {{24{tmp[7]}}, tmp[7:0]};
  wire [31:0] sexth = {{16{tmp[15]}}, tmp[15:0]};

  always @(posedge clock) begin
    if (reset) begin
      arvalid <= 0;
      rready  <= 1;

      awvalid <= 0;
      wvalid  <= 0;

      bready  <= 1;
      state   <= IDLE;
    end else begin
      $display("state",,state);
      if (state == IDLE) begin
        if (ren) begin
          arvalid <= 1;
          state   <= HANDLE_RADDR;
        end
        if (wen) begin
          $display("wen");
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
          rdata  <= sext ? (suffix_b ? sextb : sexth ) :
          (suffix_b ? {24'b0, tmp[7:0]} :
          (suffix_h ? {16'b0, tmp[15:0]} : tmp));
          read_done <= 1;
          state <= WRITE_BACK;
        end
      end else if (state == HANDLE_WADDR) begin
        if (awready) begin
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
