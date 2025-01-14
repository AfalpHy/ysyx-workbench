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

    output [31:0] r_wdata,
    output [31:0] csr_wdata1,
    output [31:0] csr_wdata2
);

  wire [31:0] alu_operand2;
  wire [31:0] alu_result;

  wire [31:0] snpc = pc + 4;
  wire [31:0] dnpc = pc + imm;

  ysyx_25010008_MuxKey #(3, 2, 32) mux_alu_operand2 (
      alu_operand2,
      alu_operand2_sel,
      {
        {2'b00, src2},
        {2'b01, imm},  // most I_type inst
        {2'b10, csr_src}  // csrrs or csrrc
      }
  );

  ysyx_25010008_ALU alu (
      .opcode  (alu_opcode),
      .operand1(src1),
      .operand2(alu_operand2),
      .result  (alu_result)
  );

  ysyx_25010008_MuxKey #(5, 3, 32) mux_npc (
      npc,
      npc_sel,
      {
        {3'b000, snpc},
        {3'b001, dnpc},  // jal
        {3'b010, alu_result & (~32'b1)},  // jalr
        {3'b011, alu_result[0] ? dnpc : snpc},  // branch
        {3'b100, csr_src}  // ecall mret
      }
  );

  ysyx_25010008_MuxKey #(5, 3, 32) mux_r_wdata (
      r_wdata,
      r_wdata_sel,
      {
        {3'b000, alu_result},
        {3'b001, snpc},  // jal jalr
        {3'b010, dnpc}, // auipc 
        {3'b011, mem_rdata}, // load
        {3'b100, csr_src} // csrrw csrrs csrrc
      }
  );

  ysyx_25010008_MuxKey #(2, 1, 32) mux_csr_wdata1 (
      csr_wdata1,
      csr_wdata1_sel,
      {
        {1'b0, alu_result},  // csrrw csrrs csrrc 
        {1'b1, 32'd11}  // ecall
      }
  );
  
  ysyx_25010008_MuxKey #(2, 1, 32) mux_csr_wdata2 (
      csr_wdata2,
      csr_wdata2_sel,
      {
        {1'b0, 32'b0},  // not used 
        {1'b1, pc}  // ecall
      }
  );

endmodule
