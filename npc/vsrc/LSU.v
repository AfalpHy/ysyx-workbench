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

  reg enable;

  assign araddr  = addr;
  assign arsize  = suffix_b ? 0 : suffix_h ? 1 : 2;
  assign arvalid = ren & ~enable;

  assign awaddr  = addr;
  assign awsize  = suffix_b ? 0 : suffix_h ? 1 : 2;
  assign awvalid = wen & ~enable;

  assign wdata   = (suffix_b | suffix_h) ? (wsrc << {addr[1:0], 3'b0}) : wsrc;
  assign wstrb   = (suffix_b ? 4'b0001 : (suffix_h ? 4'b0011 : 4'b1111)) << addr[1:0];

  wire [31:0] real_rdata = (suffix_b | suffix_h) ? (rdata >> {addr[1:0], 3'b0}) : rdata;
  wire [31:0] sextb = {{24{real_rdata[7]}}, real_rdata[7:0]};
  wire [31:0] sexth = {{16{real_rdata[15]}}, real_rdata[15:0]};
  wire [31:0] sign_data = suffix_b ? sextb : sexth;
  wire [31:0] extb = {24'b0, real_rdata[7:0]};
  wire [31:0] exth = {16'b0, real_rdata[15:0]};
  wire [31:0] unsign_data = suffix_b ? extb : (suffix_h ? exth : real_rdata);

  always @(posedge clock) begin
    if (reset) begin
      enable <= 0;

      rready <= 0;

      wvalid <= 0;
      bready <= 0;

      done   <= 0;
    end else begin
      if (done) begin
        done   <= 0;
        enable <= 0;
      end else begin
        if (arvalid & arready) begin
          if (araddr[31:12] == 20'h1_0000 || araddr[31:24] == 8'h02)
            set_skip_ref_inst();  //uart or clint
          rready <= 1;
          enable <= 1;
        end else if (rready & rvalid) begin
          if (rresp != 0) begin
            $display("%h", addr);
            $finish;
          end
          rready <= 0;
          mem_rdata <= sext ? sign_data : unsign_data;
          done <= 1;
        end else if (awvalid & awready) begin
          if (awaddr[31:12] == 20'h1_0000) set_skip_ref_inst();  //uart
          wvalid <= 1;
          enable <= 1;
        end else if (wvalid & wready) begin
          wvalid <= 0;
          bready <= 1;
        end else if (bready & bvalid) begin
          if (rresp != 0) begin
            $display("%h", addr);
            $finish;
          end
          bready <= 0;
          done   <= 1;
        end
      end
    end
  end

endmodule
