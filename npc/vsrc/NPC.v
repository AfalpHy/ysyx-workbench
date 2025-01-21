module ysyx_25010008_NPC (
    input  clk,
    input  rst,
    output halt
);
  // pc
  wire [31:0] pc;
  wire [31:0] npc;
  wire [2:0] npc_sel;

  // instruction
  wire [31:0] inst;
  wire [31:0] imm;
  wire suffix_b;
  wire suffix_h;
  wire sext;
  wire ivalid;

  // alu
  wire [7:0] alu_opcode;
  wire [1:0] alu_operand2_sel;
  wire [31:0] alu_result;

  // lsu
  wire mem_ren, mem_wen;
  wire [31:0] mem_rdata;
  wire read_done, write_done;

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

  wire write_back = mem_ren ? read_done : (mem_wen ? write_done : ivalid);

  always @(posedge clk) begin
    $display(mem_ren, read_done,mem_wen,write_done,ivalid);
  end

  wire [31:0] araddr_0 = pc;
  wire arvalid_0;
  wire arready_0;

  wire rready_0;
  wire [31:0] rdata_0;
  wire rresp_0;
  wire rvalid_0;

  wire [31:0] araddr_1 = alu_result;
  wire arvalid_1;
  wire arready_1;

  wire rready_1;
  wire [31:0] rdata_1;
  wire rresp_1;
  wire rvalid_1;

  wire [31:0] awaddr_1 = alu_result;
  wire awvalid_1;
  wire awready_1;

  wire [31:0] wdata_1 = src2;
  wire [31:0] wstrb_1;
  wire wvalid_1;
  wire wready_1;

  wire bready_1;
  wire bresp_1;
  wire bvalid_1;

  ysyx_25010008_IFU ifu (
      .clk(clk),
      .rst(rst),

      .write_back(write_back),
      .npc(npc),
      .pc(pc),

      .inst  (inst),
      .ivalid(ivalid),

      .pvalid(arvalid_0),
      .pready(arready_0),

      .rready(rready_0),
      .rdata (rdata_0),
      .rresp (rresp_0),
      .rvalid(rvalid_0)
  );

  ysyx_25010008_IDU idu (
      .inst  (inst),
      .ivalid(ivalid),

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


  ysyx_25010008_LSU lsu (
      .clk(clk),
      .rst(rst),

      .suffix_b(suffix_b),
      .suffix_h(suffix_h),
      .sext(sext),

      .ren(mem_ren),

      .wen(mem_wen),

      .rdata(mem_rdata),
      .read_done(read_done),
      .write_done(write_done),

      .arvalid(arvalid_1),
      .arready(arready_1),

      .rready(rready_1),
      .tmp(rdata_1),
      .rresp(rresp_1),
      .rvalid(rvalid_1),

      .awvalid(awvalid_1),
      .awready(awready_1),

      .wstrb (wstrb_1),
      .wvalid(wvalid_1),
      .wready(wready_1),

      .bready(bready_1),
      .bresp (bresp_1),
      .bvalid(bvalid_1)
  );

  ysyx_25010008_RegHeap reg_heap (
      .clk(clk),
      .rst(rst),

      .rs1(rs1),
      .rs2(rs2),
      .rd (rd),

      .write_back(write_back),
      .wen(r_wen),
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

  ysyx_25010008_Xbar xbar (
      .clk(clk),
      .rst(rst),

      .araddr_0 (araddr_0),
      .arvalid_0(arvalid_0),
      .arready_0(arready_0),

      .rready_0(rready_0),
      .rdata_0 (rdata_0),
      .rresp_0 (rresp_0),
      .rvalid_0(rvalid_0),

      .awaddr_0 (0),
      .awvalid_0(0),
      .awready_0(),

      .wdata_0 (0),
      .wstrb_0 (0),
      .wvalid_0(0),
      .wready_0(),

      .bready_0(0),
      .bresp_0 (),
      .bvalid_0(),

      .araddr_1 (araddr_1),
      .arvalid_1(arvalid_1),
      .arready_1(arready_1),

      .rready_1(rready_1),
      .rdata_1 (rdata_1),
      .rresp_1 (rresp_1),
      .rvalid_1(rvalid_1),

      .awaddr_1 (awaddr_1),
      .awvalid_1(awvalid_1),
      .awready_1(awready_1),

      .wdata_1 (wdata_1),
      .wstrb_1 (wstrb_1),
      .wvalid_1(wvalid_1),
      .wready_1(wready_1),

      .bready_1(bready_1),
      .bresp_1 (bresp_1),
      .bvalid_1(bvalid_1)
  );

endmodule
