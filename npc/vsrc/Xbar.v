module ysyx_25010008_Xbar (
    input clk,
    input rst,

    input [31:0] araddr_0,
    input arvalid_0,
    output reg arready_0,

    input rready_0,
    output reg [31:0] rdata_0,
    output reg rresp_0,
    output reg rvalid_0,

    input [31:0] awaddr_0,
    input awvalid_0,
    output reg awready_0,

    input [31:0] wdata_0,
    input [31:0] wstrb_0,
    input wvalid_0,
    output reg wready_0,

    input bready_0,
    output reg bresp_0,
    output reg bvalid_0,

    input [31:0] araddr_1,
    input arvalid_1,
    output reg arready_1,

    input rready_1,
    output reg [31:0] rdata_1,
    output reg rresp_1,
    output reg rvalid_1,

    input [31:0] awaddr_1,
    input awvalid_1,
    output reg awready_1,

    input [31:0] wdata_1,
    input [31:0] wstrb_1,
    input wvalid_1,
    output reg wready_1,

    input bready_1,
    output reg bresp_1,
    output reg bvalid_1
);

  parameter CHOSE_MASTER_AND_SLAVE = 0;
  parameter TRANSFER = 1;

  reg state;

  parameter MASTER_0 = 0;
  parameter MASTER_1 = 1;
  parameter MASTER_NULL = 2;

  parameter SLAVE_SRAM = 0;
  parameter SLAVE_UART = 1;
  parameter SLAVE_NULL = 2;

  reg [1:0] master, slave;

  reg [31:0] SRAM_araddr;
  reg SRAM_arvalid;
  wire SRAM_arready;

  reg SRAM_rready;
  wire [31:0] SRAM_rdata;
  wire SRAM_rresp;
  wire SRAM_rvalid;

  reg [31:0] SRAM_awaddr;
  reg SRAM_awvalid;
  wire SRAM_awready;

  reg [31:0] SRAM_wdata;
  reg [31:0] SRAM_wstrb;
  reg SRAM_wvalid;
  wire SRAM_wready;

  reg SRAM_bready;
  wire SRAM_bresp;
  wire SRAM_bvalid;

  reg [31:0] UART_araddr;
  reg UART_arvalid;
  wire UART_arready;

  reg UART_rready;
  wire [31:0] UART_rdata;
  wire UART_rresp;
  wire UART_rvalid;

  reg [31:0] UART_awaddr;
  reg UART_awvalid;
  wire UART_awready;

  reg [31:0] UART_wdata;
  reg [31:0] UART_wstrb;
  reg UART_wvalid;
  wire UART_wready;

  reg UART_bready;
  wire UART_bresp;
  wire UART_bvalid;

  assign SRAM_araddr = (slave != SLAVE_SRAM || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? araddr_1 : araddr_0);
  assign SRAM_arvalid = (slave != SLAVE_SRAM || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? arvalid_1 : arvalid_0);
  assign SRAM_rready = (slave != SLAVE_SRAM || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? rready_1 : rready_0);
  assign SRAM_awaddr = (slave != SLAVE_SRAM || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? awaddr_1 : awaddr_0);
  assign SRAM_awvalid = (slave != SLAVE_SRAM || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? awvalid_1 : awvalid_0);
  assign SRAM_wdata = (slave != SLAVE_SRAM || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? wdata_1 : wdata_0);
  assign SRAM_wstrb = (slave != SLAVE_SRAM || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? wstrb_1 : wstrb_0);
  assign SRAM_bready = (slave != SLAVE_SRAM || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? bresp_1 : bresp_0);

  assign UART_araddr = (slave != SLAVE_UART || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? araddr_1 : araddr_0);
  assign UART_arvalid = (slave != SLAVE_UART || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? arvalid_1 : arvalid_0);
  assign UART_rready = (slave != SLAVE_UART || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? rready_1 : rready_0);
  assign UART_awaddr = (slave != SLAVE_UART || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? awaddr_1 : awaddr_0);
  assign UART_awvalid = (slave != SLAVE_UART || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? awvalid_1 : awvalid_0);
  assign UART_wdata = (slave != SLAVE_UART || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? wdata_1 : wdata_0);
  assign UART_wstrb = (slave != SLAVE_UART || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? wstrb_1 : wstrb_0);
  assign UART_bready = (slave != SLAVE_UART || master == MASTER_NULL) ? 0 : (master == MASTER_1 ? bresp_1 : bresp_0);

  assign arready_0 = (master != MASTER_0 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_arready : UART_arready);
  assign arready_1 = (master != MASTER_1 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_arready : UART_arready);

  assign rdata_0 = (master != MASTER_0 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_rdata : UART_rdata);
  assign rdata_1 = (master != MASTER_1 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_rdata : UART_rdata);

  assign rresp_0 = (master != MASTER_0 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_rresp : UART_rresp);
  assign rresp_1 = (master != MASTER_1 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_rresp : UART_rresp);

  assign rvalid_0 = (master != MASTER_0 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_rvalid : UART_rvalid);
  assign rvalid_1 = (master != MASTER_1 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_rvalid : UART_rvalid);

  assign awready_0 = (master != MASTER_0 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_awready : UART_awready);
  assign awready_1 = (master != MASTER_1 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_awready : UART_awready);

  assign wready_0 = (master != MASTER_0 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_wready : UART_wready);
  assign wready_1 = (master != MASTER_1 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_wready : UART_wready);

  assign bresp_0 = (master != MASTER_0 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_bresp : UART_bresp);
  assign bresp_1 = (master != MASTER_1 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_bresp : UART_bresp);

  assign bvalid_0 = (master != MASTER_0 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_bvalid : UART_bvalid);
  assign bvalid_1 = (master != MASTER_1 || slave == SLAVE_NULL) ? 0 : (slave == SLAVE_SRAM ? SRAM_bvalid : UART_bvalid);

  always @(SRAM_awvalid or awready_1) begin
    $display(SRAM_awvalid,, awready_1);
  end
  always @(posedge clk) begin
    if (rst) begin
      master <= MASTER_0;
      slave  <= SLAVE_NULL;
      state  <= CHOSE_MASTER_AND_SLAVE;
    end else begin
      if (state == CHOSE_MASTER_AND_SLAVE) begin
        if (arvalid_0) begin
          master <= MASTER_0;
          if (araddr_0 >= 32'h8000_0000 && araddr_0 < 32'h8100_0000) begin
            slave <= SLAVE_SRAM;
          end else if (araddr_0 >= 32'h1000_0000 && araddr_0 < 32'h1000_0fff) begin
            slave <= SLAVE_UART;
          end else begin
            $display("error addr %h", araddr_0);
            $finish;
          end
          state <= TRANSFER;
        end else if (arvalid_1) begin
          master <= MASTER_1;
          if (araddr_1 >= 32'h8000_0000 && araddr_1 < 32'h8100_0000) begin
            slave <= SLAVE_SRAM;
          end else if (araddr_1 >= 32'h1000_0000 && araddr_1 < 32'h1000_0fff) begin
            slave <= SLAVE_UART;
          end else begin
            $display("error addr %h", araddr_1);
            $finish;
          end
          state <= TRANSFER;
        end else if (awvalid_1) begin
          $display("xbar");
          $display(SRAM_awvalid,, awready_1);
          master <= MASTER_1;
          if (awaddr_1 >= 32'h8000_0000 && awaddr_1 < 32'h8100_0000) begin
            slave <= SLAVE_SRAM;
          end else if (awaddr_1 >= 32'h1000_0000 && awaddr_1 < 32'h1000_0fff) begin
            slave <= SLAVE_UART;
          end else begin
            $display("error addr %h", awaddr_1);
            $finish;
          end
          state <= TRANSFER;
        end
      end else begin
        if (slave == SLAVE_SRAM) begin
          if (SRAM_rvalid || SRAM_bvalid) begin
            master <= MASTER_NULL;
            slave  <= SLAVE_NULL;
            state  <= CHOSE_MASTER_AND_SLAVE;
          end
        end else if (slave == SLAVE_UART) begin
          if (UART_rvalid || UART_bvalid) begin
            master <= MASTER_NULL;
            slave  <= SLAVE_NULL;
            state  <= CHOSE_MASTER_AND_SLAVE;
          end
        end
      end
    end
  end

  ysyx_25010008_SRAM sram (
      .clk(clk),
      .rst(rst),

      .araddr (SRAM_araddr),
      .arvalid(SRAM_arvalid),
      .arready(SRAM_arready),

      .rready(SRAM_rready),
      .rdata (SRAM_rdata),
      .rresp (SRAM_rresp),
      .rvalid(SRAM_rvalid),

      .awaddr (SRAM_awaddr),
      .awvalid(SRAM_awvalid),
      .awready(SRAM_awready),

      .wdata (SRAM_wdata),
      .wstrb (SRAM_wstrb),
      .wvalid(SRAM_wvalid),
      .wready(SRAM_wready),

      .bready(SRAM_bready),
      .bresp (SRAM_bresp),
      .bvalid(SRAM_bvalid)
  );

  ysyx_25010008_UART uart (
      .clk(clk),
      .rst(rst),

      .araddr (UART_araddr),
      .arvalid(UART_arvalid),
      .arready(UART_arready),

      .rready(UART_rready),
      .rdata (UART_rdata),
      .rresp (UART_rresp),
      .rvalid(UART_rvalid),

      .awaddr (UART_awaddr),
      .awvalid(UART_awvalid),
      .awready(UART_awready),

      .wdata (UART_wdata),
      .wstrb (UART_wstrb),
      .wvalid(UART_wvalid),
      .wready(UART_wready),

      .bready(UART_bready),
      .bresp (UART_bresp),
      .bvalid(UART_bvalid)
  );

endmodule
