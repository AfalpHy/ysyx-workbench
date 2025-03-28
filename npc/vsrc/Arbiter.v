module ysyx_25010008_Arbiter (
    input clock,
    input reset,

    input [31:0] araddr_0,
    input arvalid_0,
    output arready_0,

    input rready_0,
    output [31:0] rdata_0,
    output [1:0] rresp_0,
    output rvalid_0,
    output rlast_0,

    input [31:0] araddr_1,
    input [2:0] arsize_1,
    input arvalid_1,
    output arready_1,

    input rready_1,
    output [31:0] rdata_1,
    output [1:0] rresp_1,
    output rvalid_1,

    input [31:0] awaddr_1,
    input [2:0] awsize_1,
    input awvalid_1,
    output awready_1,

    input [31:0] wdata_1,
    input [3:0] wstrb_1,
    input wvalid_1,
    output wready_1,

    input bready_1,
    output [1:0] bresp_1,
    output bvalid_1,

    input         io_master_awready,
    output        io_master_awvalid,
    output [ 3:0] io_master_awid,
    output [31:0] io_master_awaddr,
    output [ 7:0] io_master_awlen,
    output [ 2:0] io_master_awsize,
    output [ 1:0] io_master_awburst,
    input         io_master_wready,
    output        io_master_wvalid,
    output [31:0] io_master_wdata,
    output [ 3:0] io_master_wstrb,
    output        io_master_wlast,
    output        io_master_bready,
    input         io_master_bvalid,
    input  [ 3:0] io_master_bid,
    input  [ 1:0] io_master_bresp,
    input         io_master_arready,
    output        io_master_arvalid,
    output [ 3:0] io_master_arid,
    output [31:0] io_master_araddr,
    output [ 7:0] io_master_arlen,
    output [ 2:0] io_master_arsize,
    output [ 1:0] io_master_arburst,
    output        io_master_rready,
    input         io_master_rvalid,
    input  [ 3:0] io_master_rid,
    input  [31:0] io_master_rdata,
    input  [ 1:0] io_master_rresp,
    input         io_master_rlast
);

  wire CLINT_arready;
  wire [31:0] CLINT_rdata;
  wire [1:0] CLINT_rresp;
  wire CLINT_rvalid;

  reg enable;
  reg is_clint_addr;

  // only one master work at the same time, so its logic can be simplified
  assign io_master_araddr = arvalid_0 ? araddr_0 : (arvalid_1 & enable & ~is_clint_addr) ? araddr_1 : 0;
  assign io_master_arvalid = ~reset & (arvalid_0 | (arvalid_1 & enable & ~is_clint_addr));
  assign io_master_arlen = arvalid_0 ? 8'b01 : 8'b0;
  assign io_master_arsize = arvalid_0 ? 3'b010 : arsize_1;
  assign io_master_arburst = 2'b01;
  assign io_master_rready = rready_0 | rready_1;

  assign io_master_awaddr = awaddr_1;
  assign io_master_awvalid = awvalid_1;
  assign io_master_awsize = awsize_1;
  assign io_master_wdata = wdata_1;
  assign io_master_wstrb = wstrb_1;
  assign io_master_wvalid = wvalid_1;
  assign io_master_bready = bready_1;
  assign io_master_wlast = wvalid_1;

  assign arready_0 = io_master_arready;
  assign rdata_0 = io_master_rdata;
  assign rresp_0 = io_master_rresp;
  assign rvalid_0 = io_master_rvalid;
  assign rlast_0 = io_master_rlast;

  assign arready_1 = enable ? (is_clint_addr ? CLINT_arready : io_master_arready) : 0;
  assign rdata_1 = is_clint_addr ? CLINT_rdata : io_master_rdata;
  assign rresp_1 = is_clint_addr ? CLINT_rresp : io_master_rresp;
  assign rvalid_1 = is_clint_addr ? CLINT_rvalid : io_master_rvalid;
  assign awready_1 = io_master_awready;
  assign wready_1 = io_master_wready;
  assign bresp_1 = io_master_bresp;
  assign bvalid_1 = io_master_bvalid;

  always @(posedge clock) begin
    if (reset) begin
      enable <= 0;
      is_clint_addr <= 0;
    end else begin
      if (arvalid_1) begin
        enable <= 1;
        is_clint_addr <= araddr_1 == 32'h0200_0048 || araddr_1 == 32'h0200_004c;
      end else begin
        enable <= 0;
      end
    end
  end

  ysyx_25010008_CLINT clint (
      .clock(clock),
      .reset(reset),

      .araddr (araddr_1),
      .arvalid(arvalid_1 & enable & is_clint_addr),
      .arready(CLINT_arready),

      .rready(rready_1),
      .rdata (CLINT_rdata),
      .rresp (CLINT_rresp),
      .rvalid(CLINT_rvalid)
  );

endmodule
