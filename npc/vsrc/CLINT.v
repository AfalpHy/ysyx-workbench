module ysyx_25010008_CLINT (
    input clk,
    input rst,

    input [31:0] araddr,
    input arvalid,
    output reg arready,

    input rready,
    output reg [31:0] rdata,
    output reg rresp,
    output reg rvalid
);

  parameter HANDLE_RADDR = 0;
  parameter READING = 1;
  parameter HANDLE_RDATA = 2;

  reg [ 1:0] rstate;

  reg [31:0] _araddr;

  always @(posedge clk) begin
    if (rst) begin
      arready <= 1;
      rresp   <= 0;
      rvalid  <= 0;
      rstate  <= HANDLE_RADDR;
    end else begin
      if (rstate == HANDLE_RADDR) begin
        if (arvalid) begin
          _araddr <= araddr;
          arready <= 0;
          rstate  <= READING;
        end
      end else if (rstate == READING) begin
        rdata  <= pmem_read(_araddr);
        rvalid <= 1;
        rstate <= HANDLE_RDATA;
      end else begin
        if (rready) begin
          rvalid  <= 0;
          arready <= 1;
          rstate  <= HANDLE_RADDR;
        end
      end
    end
  end

endmodule

