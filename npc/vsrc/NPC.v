import "DPI-C" function void set_pc(input [31:0] ptr[]);

module ysyx_25010008_NPC (
    input  clk,
    input  rst,
    output halt
);
  // pc
  reg [31:0] pc;
  wire [31:0] npc;
  wire [2:0] npc_sel;

  // instruction
  wire [31:0] inst;
  wire [31:0] imm;
  wire suffix_b;
  wire suffix_h;
  wire sext;

  // alu
  wire [7:0] alu_opcode;
  wire [1:0] alu_operand2_sel;
  wire [31:0] alu_result;

  // memory
  wire mem_ren, mem_wen;
  wire [31:0] mem_rdata;

  // gpr
  wire [4:0] rs1, rs2, rd;
  wire [31:0] src1, src2;
  wire r_wen;
  wire [2:0] r_wdata_sel;
  wire [31:0] r_wdata;
  // csr
  wire [11:0] csr_s, csr_d1, csr_d2;
  wire [31:0] csr_src;
  wire csr_wen1, csr_wen2;
  wire csr_wdata1_sel, csr_wdata2_sel;
  wire [31:0] csr_wdata1, csr_wdata2;

  // set pointer of pc for cpp
  initial begin
    set_pc(pc);
  end

  always @(negedge clk) begin
    if (rst) pc <= 32'h8000_0000;
    else pc <= npc;
  end

  ysyx_25010008_IFU ifu (
      .clk (clk),
      .rst (rst),
      .pc  (pc),
      .inst(inst)
  );

  ysyx_25010008_IDU idu (
      .inst(inst),

      .npc_sel(npc_sel),

      .imm(imm),
      .alu_operand2_sel(alu_operand2_sel),

      .suffix_b(suffix_b),
      .suffix_h(suffix_h),
      .sext(sext),

      .rs1(rs1),
      .rs2(rs2),
      .rd(rd),
      .r_wen(r_wen),
      .r_wdata_sel(r_wdata_sel),

      .csr_s(csr_s),
      .csr_d1(csr_d1),
      .csr_d2(csr_d2),
      .csr_wen1(csr_wen1),
      .csr_wen2(csr_wen2),
      .csr_wdata1_sel(csr_wdata1_sel),
      .csr_wdata2_sel(csr_wdata2_sel),

      .mem_ren(mem_ren),
      .mem_wen(mem_wen),

      .alu_opcode(alu_opcode),
      .halt(halt)
  );

  ysyx_25010008_EXU exu (
      .pc(pc),
      .npc_sel(npc_sel),

      .imm(imm),
      .src1(src1),
      .src2(src2),
      .r_wdata_sel(r_wdata_sel),

      .csr_src(csr_src),
      .csr_wdata1_sel(csr_wdata1_sel),
      .csr_wdata2_sel(csr_wdata2_sel),

      .alu_opcode(alu_opcode),
      .alu_operand2_sel(alu_operand2_sel),
      .alu_result(alu_result),

      .mem_rdata(mem_rdata),

      .npc(npc),

      .r_wdata(r_wdata),
      .csr_wdata1(csr_wdata1),
      .csr_wdata2(csr_wdata2)
  );


  ysyx_25010008_Memory memory (
      .clk(clk),

      .suffix_b(suffix_b),
      .suffix_h(suffix_h),
      .sext(sext),

      .ren  (mem_ren),
      .raddr(alu_result),

      .wen  (mem_wen),
      .waddr(alu_result),
      .wdata(src2),

      .rdata(mem_rdata)
  );

  ysyx_25010008_RegHeap reg_heap (
      .clk(clk),
      .rst(rst),

      .rs1(rs1),
      .rs2(rs2),
      .rd (rd),

      .wen  (r_wen),
      .wdata(r_wdata),

      .csr_s (csr_s),
      .csr_d1(csr_d1),
      .csr_d2(csr_d2),

      .csr_wen1  (csr_wen1),
      .csr_wdata1(csr_wdata1),

      .csr_wen2  (csr_wen2),
      .csr_wdata2(csr_wdata2),

      .src1(src1),
      .src2(src2),
      .csr_src(csr_src)
  );

endmodule
