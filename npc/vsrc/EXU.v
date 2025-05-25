import "DPI-C" function void exu_record(
  int npc,
  int csr_src
);

module ysyx_25010008_EXU (
    input clock,
    input reset,

    input block,

    input decode_valid,
    input FENCE_I,
    input [31:0] idu_pc,
    output reg [31:0] exu_pc,
    input [1:0] npc_sel,

    input [31:0] imm,

    input [31:0] src1,
    input [31:0] src2,
    input [ 1:0] exu_r_wdata_sel,

    input [31:0] csr_src,
    input [ 1:0] csr_src_sel,

    input  [ 7:0] alu_opcode,
    input  [ 1:0] alu_operand1_sel,
    input  [ 3:0] alu_operand2_sel,
    output [31:0] alu_result,

    input [31:0] forward_data,
    output reg [31:0] wsrc,

    output reg npc_valid,
    output reg [31:0] npc,
    output reg [31:0] snpc,

    output reg [31:0] exu_r_wdata,
    output reg [31:0] csr_wdata,

    input exception,
    output clear_pipeline,
    output reg clear_cache
);

  reg [ 7:0] opcode;
  reg [31:0] operand1;
  reg [31:0] operand2;

  ysyx_25010008_ALU alu (
      .opcode  (opcode),
      .operand1(operand1),
      .operand2(operand2),
      .result  (alu_result)
  );

  reg [31:0] dnpc;
  reg [ 1:0] npc_sel_q;
  reg [ 1:0] exu_r_wdata_sel_q;
  reg [31:0] csr_src_q;

  always @(npc_sel_q or snpc or dnpc or alu_result or csr_src_q) begin
    case (npc_sel_q)
      2'b00: npc = snpc;
      2'b01: npc = dnpc;  // jal
      2'b10: npc = alu_result & (~32'b1);  // jalr
      2'b11: npc = alu_result[0] ? dnpc : snpc;  // branch
    endcase
  end

  always @(exu_r_wdata_sel_q or alu_result or snpc or dnpc or csr_src_q) begin
    case (exu_r_wdata_sel_q)
      2'b00: exu_r_wdata = alu_result;
      2'b01: exu_r_wdata = snpc;  // jal jalr
      2'b10: exu_r_wdata = dnpc;  // auipc 
      2'b11: exu_r_wdata = csr_src;  // csrrw csrrs csrrc
    endcase
  end

  wire [31:0] src2_tmp = alu_operand2_sel[2] ? exu_r_wdata : alu_operand2_sel[3] ? forward_data : src2;
  wire [31:0] csr_src_tmp = csr_src_sel[0] ? alu_result : csr_src_sel[1] ? csr_wdata : csr_src;

  assign clear_pipeline = (npc_valid && npc_sel_q != 0) || clear_cache;

  always @(posedge clock) begin
    if (reset) begin
      npc_valid <= 0;
    end else if (!block) begin
      if (!clear_pipeline & decode_valid & !exception) begin
        npc_valid   <= 1;
        clear_cache <= FENCE_I;
      end else begin
        npc_valid   <= 0;
        clear_cache <= 0;
      end

      opcode <= alu_opcode;
      operand1 <= alu_operand1_sel[0] ? exu_r_wdata : alu_operand1_sel[1] ? forward_data : src1;
      operand2 <= alu_operand2_sel[0] ? imm : alu_operand2_sel[1] ? csr_src_tmp : src2_tmp;

      snpc <= idu_pc + 4;
      dnpc <= idu_pc + imm;

      exu_pc <= idu_pc;

      wsrc <= src2_tmp;

      npc_sel_q <= npc_sel;

      csr_src_q <= csr_src_tmp;

      exu_r_wdata_sel_q <= exu_r_wdata_sel;

      csr_wdata <= alu_result;

      exu_record(npc, csr_src);
    end
  end

endmodule
