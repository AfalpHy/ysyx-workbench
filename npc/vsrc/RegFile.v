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
    output reg [31:0] csr_src
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
      if (write_back) begin
        if (wen && rd[3:0] != 0) regs[rd[3:0]] <= wdata;
        if (csr_wen1) begin
          case (csr_d1)
            12'h300: mstatus <= csr_wdata1;
            12'h305: mtvec <= csr_wdata1;
            12'h341: mepc <= csr_wdata1;
            12'h342: mcause <= csr_wdata1;
            default: ;
          endcase
        end
        if (csr_wen2) begin
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
