import "DPI-C" function void set_regs_ptr(input logic [31:0] ptr[]);

module ysyx_25010008_RegFile (
    input clock,
    input reset,

    input block,

    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,

    input wen,
    input [31:0] wdata,

    input [11:0] csr_s,
    input [11:0] csr_d,

    input csr_wen,
    input [31:0] csr_wdata,

    output [31:0] src1,
    output [31:0] src2,
    output reg [31:0] csr_src,

    input inst_addr_misaligned,
    input ecall,
    output reg exception,

    input [31:0] lsu_pc,
    output reg [31:0] exception_pc
);

  reg [31:0] regs[15:0];
  reg [31:0] mstatus, mtvec, mepc, mcause;
  reg [31:0] mvendorid;
  reg [31:0] marchid;

  assign src1 = regs[rs1[3:0]];
  assign src2 = regs[rs2[3:0]];

  initial begin
    set_regs_ptr(regs);
  end

  integer i;

  always @(posedge clock) begin
    if (reset) begin
      for (i = 0; i < 16; i = i + 1) regs[i] <= 0;
      mstatus   <= 32'h1800;
      mvendorid <= 32'h7973_7978;
      marchid   <= 32'h17D_9F58;
    end else begin
      if (!block) begin
        if (wen && rd[3:0] != 0) begin
          regs[rd[3:0]] <= wdata;
        end
        if (csr_wen) begin
          case (csr_d)
            12'h300: mstatus <= csr_wdata;
            12'h305: mtvec <= csr_wdata;
            12'h341: mepc <= csr_wdata;
            default: ;
          endcase
        end
        if (exception) exception <= 0;
        else exception <= inst_addr_misaligned;
        exception_pc <= lsu_pc;
      end
    end
  end

  always @(csr_s) begin
    case (csr_s)
      12'h300: csr_src = mstatus;
      12'h305: csr_src = mtvec;
      12'h341: csr_src = mepc;
      12'h342: csr_src = mcause;
      12'hF11: csr_src = mvendorid;
      12'hF12: csr_src = marchid;
      default: csr_src = 0;
    endcase
  end

endmodule
