import "DPI-C" function void set_regs_ptr(input logic [31:0] ptr[]);

module ysyx_25010008_RegFile (
    input clock,
    input reset,

    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,

    input write_back,
    input wen,
    input [31:0] wdata,

    input [11:0] csr_s,
    input [11:0] csr_d1,
    input [11:0] csr_d2,

    input csr_wen1,
    input [31:0] csr_wdata1,

    input csr_wen2,  // only for ecall 
    input [31:0] csr_wdata2,

    output [31:0] src1,
    output [31:0] src2,
    output [31:0] csr_src
);

  reg [31:0] regs[15:0];
  reg [31:0] mstatus, mtvec, mepc, mcause;

  assign src1 = regs[rs1[3:0]];
  assign src2 = regs[rs2[3:0]];

  initial begin
    set_regs_ptr(regs);
  end

  integer i;

  always @(posedge clock) begin
    if (reset) begin
      for (i = 0; i < 32; i = i + 1) regs[i] <= 0;
      mstatus <= 32'h1800;
    end else begin
      if (write_back && wen && rd[3:0] != 0) regs[rd[3:0]] <= wdata;
      if (write_back & csr_wen1) begin
        case (csr_d1)
          12'h300: mstatus <= csr_wdata1;
          12'h305: mtvec <= csr_wdata1;
          12'h341: mepc <= csr_wdata1;
          12'h342: mcause <= csr_wdata1;
          default: ;
        endcase
      end
      if (write_back & csr_wen2) begin
        case (csr_d2)
          12'h300: mstatus <= csr_wdata2;
          12'h305: mtvec <= csr_wdata2;
          12'h341: mepc <= csr_wdata2;
          12'h342: mcause <= csr_wdata2;
          default: ;
        endcase
      end
    end
  end

  ysyx_25010008_MuxKeyWithDefault #(4, 12, 32) mux_csr_src (
      .out(csr_src),
      .key(csr_s),
      .default_out(32'b0),
      .lut({12'h300, mstatus, 12'h305, mtvec, 12'h341, mepc, 12'h342, mcause})
  );

endmodule
