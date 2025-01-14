import "DPI-C" function void set_regs_ptr(input logic [31:0] ptr[]);

module RegHeap (
    input clk,
    input rst,

    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,

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

  always @(negedge clk) begin
    if (rst) begin
      for (int i = 0; i < 32; i = i + 1) regs[i] <= 0;
      mstatus <= 32'h1800;
    end else begin
      if (wen && rd[3:0] != 0) regs[rd[3:0]] <= wdata;
      if (csr_wen1) begin
        case (csr_d1)
          12'h300: begin
             mstatus <= csr_wdata1;
            $display("%h %h %h",csr_src, src1,csr_wdata1);
          end
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

  MuxKeyWithDefault #(4, 12, 32) mux_csr_src (
      .out(csr_src),
      .key(csr_s),
      .default_out(32'b0),
      .lut({12'h300, mstatus, 12'h305, mtvec, 12'h341, mepc, 12'h342, mcause})
  );

endmodule
