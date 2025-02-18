module ysyx_25010008_EXU (
    input [31:0] pc,
    input [ 2:0] npc_sel,

    input [31:0] imm,

    input [31:0] src1,
    input [31:0] src2,
    input [ 2:0] r_wdata_sel,

    input [31:0] csr_src,
    input csr_wdata1_sel,
    input csr_wdata2_sel,

    input [7:0] alu_opcode,
    input [1:0] alu_operand2_sel,

    input [31:0] mem_rdata,

    output [31:0] npc,

    output [31:0] alu_result,

    output [31:0] r_wdata,
    output [31:0] csr_wdata1,
    output [31:0] csr_wdata2
);

  function [31:0] sel_alu_operand2(input [1:0] alu_operand2_sel, input [31:0] src2,
                                   input [31:0] imm, input [31:0] csr_src);
    case (alu_operand2_sel)
      2'b00:   sel_alu_operand2 = src2;
      2'b01:   sel_alu_operand2 = imm;  // most I_type inst
      2'b10:   sel_alu_operand2 = csr_src;  // csrrs or csrrc
      default: sel_alu_operand2 = 0;
    endcase
  endfunction

  wire [31:0] alu_operand2 = sel_alu_operand2(alu_operand2_sel, src2, imm, csr_src);

  wire [31:0] snpc = pc + 4;
  wire [31:0] dnpc = pc + imm;

  ysyx_25010008_ALU alu (
      .opcode  (alu_opcode),
      .operand1(src1),
      .operand2(alu_operand2),
      .result  (alu_result)
  );

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

  assign npc = sel_npc(npc_sel, snpc, dnpc, alu_result, csr_src);

  function [31:0] sel_r_wdata(input [2:0] r_wdata_sel, input [31:0] alu_result, input [31:0] snpc,
                              input [31:0] dnpc, input [31:0] mem_rdata, input [31:0] csr_src);
    case (r_wdata_sel)
      3'b000:  sel_r_wdata = alu_result;
      3'b001:  sel_r_wdata = snpc;  // jal jalr
      3'b010:  sel_r_wdata = dnpc;  // auipc 
      3'b011:  sel_r_wdata = mem_rdata;  // load
      3'b100:  sel_r_wdata = csr_src;  // csrrw csrrs csrrc
      default: sel_r_wdata = 0;
    endcase
  endfunction

  assign r_wdata = sel_r_wdata(r_wdata_sel, alu_result, snpc, dnpc, mem_rdata, csr_src);

  assign csr_wdata1 = csr_wdata1_sel ? 32'd11 // csrrw csrrs csrrc 
                                     : alu_result; // ecall

  assign csr_wdata2 = csr_wdata2_sel ? pc // ecall 
                                     : 0; // not used

endmodule
