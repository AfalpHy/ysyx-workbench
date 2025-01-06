import "DPI-C" function void set_memory_ptr(input logic [31:0] ptr[]);

// import "DPI-C" function void pmem_write(
//   int addr,
//   int data
// );

module Memory (
    input clk,

    input ren,
    input [31:0] raddr,

    input wen,
    input [31:0] waddr,
    input [31:0] wdata,

    output reg [31:0] rdata
);

  reg [31:0] memory['h100_0000-1:0];

  initial begin
    set_memory_ptr(memory);
  end

  always @(posedge ren) begin
    rdata = pmem_read(raddr, 4);
    // if (wen) memory[waddr-'h8000_0000] <= wdata;
  end
endmodule
