import "DPI-C" function int pmem_read(
  int addr,
  int len
);

module IFU (
    input clk,
    input rst,
    input [31:0] pc,
    output reg [31:0] inst
);

  always @(posedge clk) begin
    if (!rst) begin inst = pmem_read(pc, 4);
    $display("inst %h",inst);
    end
  end

endmodule
