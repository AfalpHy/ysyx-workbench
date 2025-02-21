module ysyx_25010008_EXU (
    input clock,
    input reset,

    input dvalid,
    output reg dready,

    output reg evalid,
    input eready,

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

    input read_done,
    input [31:0] mem_rdata,

    output reg [31:0] npc,

    output [31:0] alu_result,

    output reg [31:0] r_wdata,
    output [31:0] csr_wdata1,
    output [31:0] csr_wdata2
);

  reg wait_read;

  wire [31:0] snpc = pc + 4;
  wire [31:0] dnpc = pc + imm;

  wire [31:0] alu_operand2 = alu_operand2_sel == 0 ? src2    :
                             alu_operand2_sel == 1 ? imm     :
                             alu_operand2_sel == 2 ? csr_src : 0;

  ysyx_25010008_ALU alu (
      .opcode  (alu_opcode),
      .operand1(src1),
      .operand2(alu_operand2),
      .result  (alu_result)
  );

  always @(posedge clock) begin
    if (reset) begin
      dready <= 1;
      evalid <= 0;
      wait_read <= 0;
    end else begin
      if (dvalid & dready) begin
        dready <= 0;
        case (npc_sel)
          3'b000:  npc <= snpc;
          3'b001:  npc <= dnpc;  // jal
          3'b010:  npc <= alu_result & (~32'b1);  // jalr
          3'b011:  npc <= alu_result[0] ? dnpc : snpc;  // branch
          3'b100:  npc <= csr_src;  // ecall mret
          default: npc <= 0;
        endcase
        if (r_wdata_sel[2]) begin
          wait_read <= 1;
        end else begin
          case (r_wdata_sel)
            3'b00:   r_wdata <= alu_result;
            3'b01:   r_wdata <= snpc;  // jal jalr
            3'b10:   r_wdata <= csr_src;  // csrrw csrrs csrrc
            3'b11:   r_wdata <= dnpc;  // auipc 
            default: r_wdata <= 0;
          endcase
          evalid <= 1;
        end
      end else if (wait_read & read_done) begin
        r_wdata <= mem_rdata;  // load
        evalid <= 1;
        wait_read <= 0;
      end else if (evalid) begin
        evalid <= 0;
        dready <= 1;
      end
    end
  end

  assign csr_wdata1 = csr_wdata1_sel ? 32'd11 // csrrw csrrs csrrc 
                                     : alu_result; // ecall

  assign csr_wdata2 = csr_wdata2_sel ? pc // ecall 
                                     : 0; // not used

endmodule
