import "DPI-C" function void set_pc(input [31:0] ptr[]);

module NPC (
    input  clk,
    input  rst,
    output halt
);

  reg [31:0] pc;
  wire [31:0] snpc, dnpc;
  wire [1:0] npc_sel;

  //  instruct
  wire [31:0] inst;
  wire [31:0] imm;
  wire use_imm;
  wire sext_b;
  wire sext_h;

  // reg
  wire [4:0] rs1, rs2, rd;
  wire [31:0] src1, src2;
  wire reg_wen;

  // alu
  wire [4:0] opcode;
  wire [31:0] operan1, operand2, result;

  // memory
  wire mem_ren, mem_wen;

  assign snpc = pc + 4;
  assign dnpc = pc + imm;

  assign operan1 = src1;
  assign operand2 = use_imm ? imm : src2;

  initial begin
    set_pc(pc);
  end

  always @(posedge clk) begin
    if (rst) pc <= 32'h8000_0000;
    else begin
      case (npc_sel)
        2'b00: pc <= snpc;
        2'b01: pc <= dnpc;
        2'b10: pc <= result & (~32'b1);
        2'b11: pc <= result ? dnpc : snpc;
      endcase
    end
  end


endmodule
