import "DPI-C" function void set_pc(input [31:0] ptr[]);
import "DPI-C" function void set_write_back(input logic write_back[]);

module ysyx_25010008_IFU (
    input clk,
    input rst,

    input write_back,
    input [31:0] npc,
    output reg [31:0] pc,

    output reg [31:0] inst,
    output reg valid
);

  parameter IDLE = 0;
  parameter HANDLE_PC = 1;
  parameter HANDLE_INST = 2;

  reg [1:0] state;

  reg pvalid;
  wire pready;

  reg rready;
  wire [31:0] rdata;
  wire rresp;
  wire rvalid;

  wire [7:0] delay;
  // set pointer of pc for cpp
  initial begin
    set_pc(pc);
    set_write_back(write_back);
  end

  always @(posedge clk) begin
    if (rst) begin
      pc <= 32'h8000_0000;
      pvalid <= 1;
      rready <= 1;
      valid <= 0;
      state <= HANDLE_PC;
    end else begin
      if (state == IDLE) begin
        if (write_back) begin
          pc <= npc;
          #delay pvalid <= 1;
          valid <= 0;
          state <= HANDLE_PC;
        end
      end else if (state == HANDLE_PC) begin
        if (pready) begin
          pvalid <= 0;
          #delay rready <= 1;
          state <= HANDLE_INST;
        end
      end else begin
        if (rvalid & !rresp) begin
          rready <= 0;
          inst   <= rdata;
          valid  <= 1;
          state  <= IDLE;
        end
      end
    end
  end

  ysyx_25010008_SRAM sram (
      .clk(clk),
      .rst(rst),

      .araddr (pc),
      .arvalid(pvalid),
      .arready(pready),

      .rready(rready),
      .rdata (rdata),
      .rresp (rresp),
      .rvalid(rvalid),

      .awaddr (0),
      .awvalid(0),
      .awready(),

      .wdata (0),
      .wstrb (0),
      .wvalid(0),
      .wready(),

      .bready(0),
      .bresp (),
      .bvalid()
  );

  ysyx_25010008_LFSR lfsr (
      .clk (clk),
      .rst (rst),
      .dout(delay)
  );
endmodule
