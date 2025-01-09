import "DPI-C" function void set_pc(input [31:0] ptr[]);

module NPC (
    input  clk,
    input  rst,
    output halt
);
  // pc
  reg [31:0] pc;
  wire [31:0] npc, snpc, dnpc;
  wire [1:0] npc_sel;

  // instruction
  wire [31:0] inst;
  wire [31:0] imm;
  wire imm_for_alu;
  wire suffix_b;
  wire suffix_h;
  wire sext;

  // reg
  wire [4:0] rs1, rs2, rd;
  wire [31:0] src1, src2;
  wire reg_wen;
  wire [31:0] reg_wdata;
  wire [1:0] reg_wdata_sel;

  // alu
  wire [6:0] alu_opcode;
  wire [31:0] alu_operand1, alu_operand2, alu_result;

  // memory
  wire mem_ren, mem_wen;
  wire [31:0] mem_rdata;

  assign snpc = pc + 4;
  assign dnpc = pc + imm;

  assign alu_operand1 = src1;
  assign alu_operand2 = imm_for_alu ? imm : src2;

  // set pointer of pc for cpp
  initial begin
    set_pc(pc);
  end

  always @(negedge clk) begin
    if (rst) pc <= 32'h8000_0000;
    else pc <= npc;
    $display("alu: %h",alu_result);
  end

  MuxKey #(4, 2, 32) mux_npc (
      npc,
      npc_sel,
      {2'b00, snpc, 2'b01, dnpc, 2'b10, alu_result & (~32'b1), 2'b11, alu_result[0] ? dnpc : snpc}
  );

  MuxKey #(4, 2, 32) mux_reg_wdata (
      reg_wdata,
      reg_wdata_sel,
      {2'b00, alu_result, 2'b01, snpc, 2'b10, dnpc, 2'b11, mem_rdata}
  );

  RegHeap reg_heap (
      .clk(clk),

      .rst(rst),
      .rs1(rs1),
      .rs2(rs2),
      .rd (rd),

      .wen  (reg_wen),
      .wdata(reg_wdata),

      .src1(src1),
      .src2(src2)
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
      .imm_for_alu(imm_for_alu),

      .suffix_b(suffix_b),
      .suffix_h(suffix_h),
      .sext(sext),

      .rs1(rs1),
      .rs2(rs2),
      .rd(rd),
      .reg_wen(reg_wen),
      .reg_wdata_sel(reg_wdata_sel),

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
