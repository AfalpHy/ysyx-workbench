import "DPI-C" function void set_pc(input [31:0] ptr[]);

module NPC (
    input  clk,
    input  rst,
    output halt
);
  // pc
  reg [31:0] pc;
  wire [31:0] npc, snpc, dnpc;
  wire [2:0] npc_sel;

  // instruction
  wire [31:0] inst;
  wire [31:0] imm;
  wire [1:0] alu_operand2_sel;
  wire suffix_b;
  wire suffix_h;
  wire sext;

  // gpr
  wire [4:0] rs1, rs2, rd;
  wire [31:0] src1, src2;
  wire r_wen;
  wire [2:0] r_wdata_sel;
  wire [31:0] r_wdata;
  // csr
  wire [11:0] csr_s, csr_d1, csr_d2;
  wire [1:0] csr_s_sel;
  wire csr_d1_sel, csr_d2_sel;
  wire [31:0] csr_src;
  wire csr_wen1, csr_wen2;
  wire csr_wdata1_sel, csr_wdata2_sel;
  wire [31:0] csr_wdata1, csr_wdata2;

  // alu
  wire [7:0] alu_opcode;
  wire [31:0] alu_operand1, alu_operand2, alu_result;

  // memory
  wire mem_ren, mem_wen;
  wire [31:0] mem_rdata;

  assign snpc = pc + 4;
  assign dnpc = pc + imm;

  assign csr_d1 = csr_d1_sel ? 12'h342 : imm[11:0];  // mcause or other assigned one
  assign csr_d2 = csr_d2_sel ? 12'h341 : 0;  // mpec or null
  assign csr_wdata1 = csr_wdata1_sel ? 32'd11 : alu_result;  // 11 for ecall
  assign csr_wdata2 = csr_wdata2_sel ? pc : 0;  // pc for ecall

  assign alu_operand1 = src1;

  // set pointer of pc for cpp
  initial begin
    set_pc(pc);
  end

  always @(negedge clk) begin
    if (rst) pc <= 32'h8000_0000;
    else pc <= npc;
    if(inst[6:0] == 7'b11_100_11)
    $display("%h %h %h",alu_operand1,alu_operand2, alu_result);
  end

  MuxKey #(3, 2, 12) mux_csr_s (
      csr_s,
      csr_s_sel,
      {2'b00, imm[11:0], 2'b01, 12'h305, 2'b10, 12'h341}
  );

  MuxKey #(3, 2, 32) mux_alu_operand2 (
      alu_operand2,
      alu_operand2_sel,
      {2'b00, src2, 2'b01, imm, 2'b10, csr_src}
  );

  MuxKey #(5, 3, 32) mux_npc (
      npc,
      npc_sel,
      {
        3'b000,
        snpc,
        3'b001,
        dnpc,
        3'b010,
        alu_result & (~32'b1),
        3'b011,
        alu_result[0] ? dnpc : snpc,
        3'b100,
        csr_src
      }
  );

  MuxKey #(5, 3, 32) mux_reg_wdata (
      r_wdata,
      r_wdata_sel,
      {3'b000, alu_result, 3'b001, snpc, 3'b010, dnpc, 3'b011, mem_rdata, 3'b100, csr_src}
  );

  RegHeap reg_heap (
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

  Memory memory (
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

  IFU ifu (
      .clk (clk),
      .rst (rst),
      .pc  (pc),
      .inst(inst)
  );

  IDU idu (
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

      .csr_s_sel(csr_s_sel),
      .csr_d1_sel(csr_d1_sel),
      .csr_d2_sel(csr_d2_sel),
      .csr_wen1(csr_wen1),
      .csr_wen2(csr_wen2),
      .csr_wdata1_sel(csr_wdata1_sel),
      .csr_wdata2_sel(csr_wdata2_sel),

      .mem_ren(mem_ren),
      .mem_wen(mem_wen),

      .alu_opcode(alu_opcode),
      .halt(halt)
  );

  ALU alu (
      .opcode  (alu_opcode),
      .operand1(alu_operand1),
      .operand2(alu_operand2),
      .result  (alu_result)
  );


endmodule
