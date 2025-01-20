import "DPI-C" function void set_memory_ptr(input logic [31:0] ptr[]);

module ysyx_25010008_LSU (
    input clk,
    input rst,

    input suffix_b,
    input suffix_h,
    input sext,

    input ren,
    input [31:0] raddr,

    input wen,
    input [31:0] waddr,
    input [31:0] wdata,

    output reg [31:0] rdata,
    output reg read_done,
    output reg write_done
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

  reg arvalid;
  wire arready;

  reg rready;
  wire [31:0] tmp;
  wire rresp;
  wire rvalid;

  reg awvalid;
  wire awready;

  wire [31:0] wstrb = suffix_b ? {24'b0, 8'hFF} : (suffix_h ? {16'b0, 16'hFFFF} : 32'hFFFF_FFFF);
  reg wvalid;
  wire wready;

  reg bready;
  wire bresp;
  wire bvalid;

  always @(posedge clk) begin
    if (rst) begin
      arvalid <= 0;
      rready  <= 1;

      awvalid <= 0;
      wvalid  <= 0;

      bready  <= 1;
      state   <= IDLE;
    end else begin
      if (state == IDLE) begin
        if (ren) begin
          $display("read");
          arvalid <= 1;
          state   <= HANDLE_RADDR;
        end
        if (wen) begin
          $display("write");
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
        if (rvalid & !rresp) begin
          rready <= 0;
          rdata  <= sext ? (suffix_b ? (tmp | ({32{tmp[7]}} << 8)):(tmp | ({32{tmp[15]}} << 16))): tmp;
          $display(tmp);
          read_done <= 1;
          state <= WRITE_BACK;
        end
      end else if (state == HANDLE_WADDR) begin
        if (awready) begin
          $display("write1");
          awvalid <= 0;
          wvalid  <= 1;
          state   <= HANDLE_WDATA;
        end
      end else if (state == HANDLE_WDATA) begin
        if (wready) begin
          $display("write2");
          wvalid <= 0;
          bready <= 1;
          state  <= HANDLE_BRESP;
        end
      end else if (state == HANDLE_BRESP) begin
        if (bvalid & !bresp) begin
          $display("write3");
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

  ysyx_25010008_SRAM sram (
      .clk(clk),
      .rst(rst),

      .araddr (raddr),
      .arvalid(arvalid),
      .arready(arready),

      .rready(rready),
      .rdata (tmp),
      .rresp (rresp),
      .rvalid(rvalid),

      .awaddr (waddr),
      .awvalid(awvalid),
      .awready(awready),

      .wdata (wdata),
      .wstrb (wstrb),
      .wvalid(wvalid),
      .wready(wready),

      .bready(bready),
      .bresp (bresp),
      .bvalid(bvalid)
  );

endmodule
