import "DPI-C" function void exu_record(int npc);

module ysyx_25010008_EXU (
    input clock,
    input reset,

    input block,

    input decode_valid,
    input FENCE_I,
    input [31:0] pc,
    input [2:0] npc_sel,

    input [31:0] imm,

    input [31:0] src1,
    input [31:0] src2,
    input [ 1:0] exu_r_wdata_sel,

    input [31:0] csr_src,
    input csr_wdata1_sel,

    input  [ 7:0] alu_opcode,
    input  [ 1:0] alu_operand1_sel,
    input  [ 3:0] alu_operand2_sel,
    output [31:0] alu_result,

    input [31:0] forward_data,
    output reg [31:0] wsrc,

    output reg npc_valid,
    output [31:0] npc,
    output reg [31:0] snpc,

    output [31:0] exu_r_wdata,
    output reg [31:0] csr_wdata1,
    output reg [31:0] csr_wdata2,

    output clear_pipeline,
    output reg clear_cache
);

  reg [ 7:0] opcode;
  reg [31:0] operand1;
  reg [31:0] operand2;

  reg [31:0] dnpc;

  ysyx_25010008_ALU alu (
      .opcode  (opcode),
      .operand1(operand1),
      .operand2(operand2),
      .result  (alu_result)
  );

  reg [2:0] npc_sel_buffer;

  reg [1:0] exu_r_wdata_sel_buffer;
  reg csr_wdata1_sel_buffer;

  reg [31:0] csr_wdata2_buffer;
  reg [31:0] csr_src_buffer;

  function [31:0] sel_npc(input [2:0] npc_sel, input [31:0] snpc, input [31:0] dnpc,
                          input [31:0] alu_result, input [31:0] csr_src);
    case (npc_sel)
      3'b000:  sel_npc = snpc;
      3'b001:  sel_npc = dnpc;  // jal
      3'b010:  sel_npc = alu_result & (~32'b1);  // jalr
      3'b011:  sel_npc = alu_result[0] ? dnpc : snpc;  // branch
      3'b100:  sel_npc = csr_src;  // ecall mret
      default: sel_npc = 0;
    endcase
  endfunction

  assign npc = sel_npc(npc_sel_buffer, snpc, dnpc, alu_result, csr_src_buffer);

  function [31:0] sel_exu_r_wdata(input [1:0] exu_r_wdata_sel, input [31:0] alu_result,
                                  input [31:0] snpc, input [31:0] dnpc, input [31:0] csr_src);
    case (exu_r_wdata_sel)
      2'b00: sel_exu_r_wdata = alu_result;
      2'b01: sel_exu_r_wdata = snpc;  // jal jalr
      2'b10: sel_exu_r_wdata = dnpc;  // auipc 
      2'b11: sel_exu_r_wdata = csr_src;  // csrrw csrrs csrrc
    endcase
  endfunction

  assign exu_r_wdata = sel_exu_r_wdata(
      exu_r_wdata_sel_buffer, alu_result, snpc, dnpc, csr_src_buffer
  );

  assign clear_pipeline = (npc_valid && npc_sel_buffer != 0) || clear_cache;

  always @(posedge clock) begin
    if (reset) begin
      npc_valid <= 0;
    end else if (!block) begin
      if (!clear_pipeline & decode_valid) begin
        npc_valid <= 1;
      end else begin
        npc_valid <= 0;
      end

      clear_cache <= FENCE_I;

      opcode <= alu_opcode;
      operand1 <= alu_operand1_sel[0] ? exu_r_wdata : alu_operand1_sel[1] ? forward_data : src1;

      operand2 <= alu_operand2_sel[0] ? imm :
                  alu_operand2_sel[1] ? csr_src :
                  alu_operand2_sel[2] ? exu_r_wdata :
                  alu_operand2_sel[3] ? forward_data : src2;

      snpc <= pc + 4;
      dnpc <= pc + imm;

      wsrc <= alu_operand2_sel[2] ? exu_r_wdata : alu_operand2_sel[3] ? forward_data : src2;

      npc_sel_buffer <= npc_sel;

      csr_src_buffer <= csr_src;
      exu_r_wdata_sel_buffer <= exu_r_wdata_sel;
      csr_wdata1_sel_buffer <= csr_wdata1_sel;
      csr_wdata1 <= csr_wdata1_sel_buffer ? 32'd11 : alu_result;
      csr_wdata2_buffer <= pc;
      csr_wdata2 <= csr_wdata2_buffer;

      exu_record(npc);
    end
  end

endmodule
