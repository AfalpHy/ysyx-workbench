module IDU (
    input [31:0] inst,

    output [1:0] npc_sel,

    output [31:0] imm,
    output imm_for_alu,

    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,
    output reg_wen,
    output [1:0] reg_wdata_sel,

    output mem_ren,
    output mem_wen,

    output [4:0] alu_opcode,
    output halt
);

  wire [6:0] opcode = inst[6:0];
  wire [2:0] funct3 = inst[14:12];
  wire [6:0] funct7 = inst[31:25];

  wire funct3_000 = funct3 == 3'b000;
  wire funct3_001 = funct3 == 3'b001;
  wire funct3_010 = funct3 == 3'b010;
  wire funct3_011 = funct3 == 3'b011;
  wire funct3_100 = funct3 == 3'b100;
  wire funct3_101 = funct3 == 3'b101;
  wire funct3_110 = funct3 == 3'b110;
  wire funct3_111 = funct3 == 3'b111;

  wire funct7_00000_00 = funct7 == 7'b00000_00;
  wire funct7_00000_01 = funct7 == 7'b00000_01;
  wire funct7_01000_00 = funct7 == 7'b01000_00;

  wire LUI   = opcode == 7'b01_101_11;

  wire AUIPC = opcode == 7'b00_101_11;

  wire JAL   = opcode == 7'b11_011_11;

  wire JALR  = opcode == 7'b11_001_11 & funct3_000;

  wire branch = opcode == 7'b11_000_11;
  wire BEQ    = branch & funct3_000;
  wire BNE    = branch & funct3_001;
  wire BLT    = branch & funct3_100;
  wire BGE    = branch & funct3_101;
  wire BLTU   = branch & funct3_110;
  wire BGEU   = branch & funct3_111;

  wire load = opcode == 7'b00_000_11;
  wire LB   = load & funct3_000;
  wire LH   = load & funct3_001;
  wire LW   = load & funct3_010;
  wire LBU  = load & funct3_100;
  wire LHU  = load & funct3_101;

  wire store = opcode == 7'b01_000_11;
  wire SB    = store & funct3_000;
  wire SH    = store & funct3_001;
  wire SW    = store & funct3_010;

  wire op_imm = opcode == 7'b00_100_11;
  wire ADDI   = op_imm & funct3_000;
  wire SLTI   = op_imm & funct3_010;
  wire SLTIU  = op_imm & funct3_011;
  wire XORI   = op_imm & funct3_100;
  wire ORI    = op_imm & funct3_110;
  wire ANDI   = op_imm & funct3_111;
  wire SLLI   = op_imm & funct3_001 & funct7_00000_00;
  wire SRLI   = op_imm & funct3_101 & funct7_00000_00;
  wire SRAI   = op_imm & funct3_101 & funct7_01000_00;

  wire op     = opcode == 7'b01_100_11;
  wire ADD    = op & funct3_000 & funct7_00000_00;
  wire SUB    = op & funct3_000 & funct7_01000_00;
  wire SLL    = op & funct3_001 & funct7_00000_00;
  wire SLT    = op & funct3_010 & funct7_00000_00;
  wire SLTU   = op & funct3_011 & funct7_00000_00;
  wire XOR    = op & funct3_100 & funct7_00000_00;
  wire SRL    = op & funct3_101 & funct7_00000_00;
  wire SRA    = op & funct3_101 & funct7_01000_00;
  wire OR     = op & funct3_110 & funct7_00000_00;
  wire AND    = op & funct3_111 & funct7_00000_00;
  // disable the RV32M temporarily
  // wire MUL    = op & funct3_000 & funct7_00000_01;
  // wire MULH   = op & funct3_001 & funct7_00000_01;
  // wire MULHSU = op & funct3_010 & funct7_00000_01;
  // wire MULHU  = op & funct3_011 & funct7_00000_01;
  // wire DIV    = op & funct3_100 & funct7_00000_01;
  // wire DIVU   = op & funct3_101 & funct7_00000_01;
  // wire REM    = op & funct3_110 & funct7_00000_01;
  // wire REMU   = op & funct3_111 & funct7_00000_01;
  
  wire EBREAK = inst[31:0] == 32'b0000000_00001_00000_000_00000_11100_11;

  assign npc_sel[0] = JAL | branch;
  assign npc_sel[1] = JALR;
  
  wire U_type = LUI | AUIPC;
  wire J_type = JAL;
  wire B_type = branch;
  wire I_type = JALR | load | op_imm;
  wire S_type = store;
  wire R_type = op;

  wire [31:0] U_imm = U_type ? {inst[31:12], {12{1'b0}}} : 0;
  wire [31:0] J_imm = J_type ? {{12{inst[31]}}, inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0} : 0;
  wire [31:0] B_imm = B_type ? {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0} : 0;
  wire [31:0] I_imm = I_type ? {{20{inst[31]}}, inst[31:20]} : 0;
  wire [31:0] S_imm = S_type ? {{20{inst[31]}}, inst[31:25], inst[11:7]} : 0;

  assign imm         = U_imm | J_imm | B_imm | I_imm | S_imm;
  assign imm_for_alu = I_type | S_type;

  assign rs1 = LUI ? 0 : inst[19:15]; // LUI always use x0 means 0 + imm
  assign rs2 = inst[24:20];
  assign rd  = inst[11:7];

  assign reg_wen          = U_type | J_type | I_type | R_type;
  assign reg_wdata_sel[0] = JAL | JALR | load;
  assign reg_wdata_sel[1] = AUIPC | load;

  assign mem_ren = load;
  assign mem_wen = store;

  assign halt = EBREAK;

endmodule

