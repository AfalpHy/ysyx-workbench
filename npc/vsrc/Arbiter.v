module ysyx_25010008_Arbiter (
    input clock,
    input reset,

    input [31:0] araddr_0,
    input arvalid_0,
    output reg arready_0,

    input rready_0,
    output reg [31:0] rdata_0,
    output reg [1:0] rresp_0,
    output reg rvalid_0,

    input [31:0] awaddr_0,
    input awvalid_0,
    output reg awready_0,

    input [31:0] wdata_0,
    input [3:0] wstrb_0,
    input wvalid_0,
    output reg wready_0,

    input bready_0,
    output reg [1:0] bresp_0,
    output reg bvalid_0,

    input [31:0] araddr_1,
    input arvalid_1,
    output reg arready_1,

    input rready_1,
    output reg [31:0] rdata_1,
    output reg [1:0] rresp_1,
    output reg rvalid_1,

    input [31:0] awaddr_1,
    input awvalid_1,
    output reg awready_1,

    input [31:0] wdata_1,
    input [3:0] wstrb_1,
    input wvalid_1,
    output reg wready_1,

    input bready_1,
    output reg [1:0] bresp_1,
    output reg bvalid_1,

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

  parameter CHOSE_MASTER = 0;
  parameter TRANSFER = 1;

  reg state;

  parameter MASTER_0 = 0;
  parameter MASTER_1 = 1;
  parameter MASTER_NULL = 2;

  parameter SLAVE_CLINT = 0;
  parameter SLAVE_OTHERS = 1;
  parameter SLAVE_NULL = 2;

  reg [1:0] master, slave;

  reg [31:0] CLINT_araddr;
  reg CLINT_arvalid;
  wire CLINT_arready;

  reg CLINT_rready;
  wire [31:0] CLINT_rdata;
  wire [1:0] CLINT_rresp;
  wire CLINT_rvalid;

  assign io_master_araddr = (slave != SLAVE_OTHERS || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? araddr_1 : araddr_0);
  assign io_master_arvalid = (slave != SLAVE_OTHERS || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? arvalid_1 : arvalid_0);
  assign io_master_rready = (slave != SLAVE_OTHERS || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? rready_1 : rready_0);
  assign io_master_awaddr = (slave != SLAVE_OTHERS || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? awaddr_1 : awaddr_0);
  assign io_master_awvalid = (slave != SLAVE_OTHERS || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? awvalid_1 : awvalid_0);
  assign io_master_wdata = (slave != SLAVE_OTHERS || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? wdata_1 : wdata_0);
  assign io_master_wstrb = (slave != SLAVE_OTHERS || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? wstrb_1 : wstrb_0);
  assign io_master_wvalid = (slave != SLAVE_OTHERS || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? wvalid_1 : wvalid_0);
  assign io_master_bready = (slave != SLAVE_OTHERS || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? bready_1 : bready_0);

  assign CLINT_araddr = (slave != SLAVE_CLINT || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? araddr_1 : araddr_0);
  assign CLINT_arvalid = (slave != SLAVE_CLINT || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? arvalid_1 : arvalid_0);
  assign CLINT_rready = (slave != SLAVE_CLINT || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? rready_1 : rready_0);

  assign arready_0 = (master != MASTER_0 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_OTHERS ? io_master_arready : CLINT_arready);
  assign arready_1 = (master != MASTER_1 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_OTHERS ? io_master_arready : CLINT_arready);

  assign rdata_0 = (master != MASTER_0 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_OTHERS ? io_master_rdata : CLINT_rdata);
  assign rdata_1 = (master != MASTER_1 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_OTHERS ? io_master_rdata : CLINT_rdata);

  assign rresp_0 = (master != MASTER_0 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_OTHERS ? io_master_rresp : CLINT_rresp);
  assign rresp_1 = (master != MASTER_1 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_OTHERS ? io_master_rresp : CLINT_rresp);

  assign rvalid_0 = (master != MASTER_0 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_OTHERS ? io_master_rvalid: CLINT_rvalid);
  assign rvalid_1 = (master != MASTER_1 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_OTHERS ? io_master_rvalid: CLINT_rvalid);

  assign awready_0 = (master != MASTER_0 || slave != SLAVE_OTHERS) ? 0 : io_master_awready;
  assign awready_1 = (master != MASTER_1 || slave != SLAVE_OTHERS) ? 0 : io_master_awready;

  assign wready_0 = (master != MASTER_0 || slave != SLAVE_OTHERS) ? 0 : io_master_wready;
  assign wready_1 = (master != MASTER_1 || slave != SLAVE_OTHERS) ? 0 : io_master_wready;

  assign bresp_0 = (master != MASTER_0 || slave != SLAVE_OTHERS) ? 0 : io_master_bresp;
  assign bresp_1 = (master != MASTER_1 || slave != SLAVE_OTHERS) ? 0 : io_master_bresp;

  assign bvalid_0 = (master != MASTER_0 || slave != SLAVE_OTHERS) ? 0 : io_master_bvalid;
  assign bvalid_1 = (master != MASTER_1 || slave != SLAVE_OTHERS) ? 0 : io_master_bvalid;

  always @(posedge clock) begin
    if (reset) begin
      master <= MASTER_0;
      slave  <= SLAVE_NULL;
      state  <= CHOSE_MASTER;
    end else begin
      if (state == CHOSE_MASTER) begin
        if (arvalid_0) begin
          $display("here1");
          master <= MASTER_0;
          slave  <= SLAVE_OTHERS;
          state  <= TRANSFER;
        end else if (arvalid_1) begin
          master <= MASTER_1;
          if (araddr_1 == 32'ha000_0048 || araddr_1 == 32'ha000_004c) begin
            slave <= SLAVE_CLINT;
          end else begin
            slave <= SLAVE_OTHERS;
          end
          state <= TRANSFER;
        end else if (awvalid_1) begin
          master <= MASTER_1;
          slave  <= SLAVE_OTHERS;
          state  <= TRANSFER;
        end
      end else begin
        if (slave == SLAVE_CLINT) begin
          if (CLINT_rvalid) begin
            master <= MASTER_NULL;
            slave  <= SLAVE_NULL;
            state  <= CHOSE_MASTER;
          end
        end else begin
          if (io_master_rvalid | io_master_bvalid) begin
            master <= MASTER_NULL;
            slave  <= SLAVE_NULL;
            state  <= CHOSE_MASTER;
          end
        end
      end
      $display(io_master_arvalid, , io_master_rvalid,, io_master_bvalid);
    end
  end

  ysyx_25010008_CLINT clint (
      .clock(clock),
      .reset(reset),

      .araddr (CLINT_araddr),
      .arvalid(CLINT_arvalid),
      .arready(CLINT_arready),

      .rready(CLINT_rready),
      .rdata (CLINT_rdata),
      .rresp (CLINT_rresp),
      .rvalid(CLINT_rvalid)
  );

endmodule
