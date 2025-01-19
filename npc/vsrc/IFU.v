module ysyx_25010008_IFU (
    input clk,
    input rst,
    input [31:0] pc,
    input fetch,
    output reg [31:0] inst,
    output reg valid
);

  always @(posedge clk) begin
    if (!rst) begin
      if (fetch) valid = 0;
      else valid = 1;
    end else valid = 0;
  end

  ysyx_25010008_SRAM sram (
      .clk(clk),

      .ren  (fetch),
      .raddr(pc),

      .wen  (0),
      .waddr(0),
      .wdata(0),

      .len(3'b100),

      .rdata(inst)
  );

endmodule
