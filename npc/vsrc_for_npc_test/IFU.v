`define ysyx_25010008_M 4 
`define ysyx_25010008_N 2
`define ysyx_25010008_DATA_WIDTH (2 ** `ysyx_25010008_M) * 8
`define ysyx_25010008_TAG_WIDTH 32 - (`ysyx_25010008_M + `ysyx_25010008_N) 
`define ysyx_25010008_CACHE_WIDTH `ysyx_25010008_TAG_WIDTH + `ysyx_25010008_DATA_WIDTH + 1
`define ysyx_25010008_CACHE_SIZE 2 ** `ysyx_25010008_N

// in cache
`define ysyx_25010008_VALID_POS `ysyx_25010008_TAG_WIDTH + `ysyx_25010008_DATA_WIDTH
`define ysyx_25010008_CACHE_TAG_RANGE `ysyx_25010008_TAG_WIDTH + `ysyx_25010008_DATA_WIDTH - 1 : `ysyx_25010008_DATA_WIDTH

// in pc
`define ysyx_25010008_PC_TAG_RANGE 31 : `ysyx_25010008_M + `ysyx_25010008_N
`define ysyx_25010008_PC_INDEX_RANGE `ysyx_25010008_M + `ysyx_25010008_N -1 : `ysyx_25010008_M

module ysyx_25010008_IFU (
    input clock,
    input reset,

    input [31:0] npc,
    input npc_valid,
    output reg [31:0] ifu_pc,

    output reg inst_valid,
    output reg [31:0] inst,
    input idu_ready,
    input block,

    output enable,
    output reg [31:0] araddr,
    output reg arvalid,
    output reg [7:0] arlen,
    input arready,

    output reg rready,
    input [31:0] rdata,
    input [1:0] rresp,
    input rvalid,
    input rlast,

    output inst_addr_misaligned,
    input  clear_cache,
    input  clear_pipeline
);

  reg [31:0] pc;

  reg [`ysyx_25010008_CACHE_WIDTH - 1 : 0] cache[0 : `ysyx_25010008_CACHE_SIZE - 1];

  integer i, delay;

  parameter READ_CACHE = 0;
  parameter READ_MEMORY = 1;

  reg state;
  wire [`ysyx_25010008_N-1:0] index = pc[`ysyx_25010008_PC_INDEX_RANGE];
  wire [`ysyx_25010008_CACHE_WIDTH-1:0] cache_block = cache[index];
  wire cache_valid = cache_block[`ysyx_25010008_VALID_POS];
  wire [`ysyx_25010008_TAG_WIDTH-1:0] cache_tag = cache_block[`ysyx_25010008_CACHE_TAG_RANGE];
  wire [`ysyx_25010008_TAG_WIDTH-1:0] pc_tag = pc[`ysyx_25010008_PC_TAG_RANGE];

  assign enable = state;

  reg pipeline_empty;
  reg [3:0] inst_addr_misaligned_buffer;

  assign inst_addr_misaligned = inst_addr_misaligned_buffer[3];
  always @(posedge clock) begin
    if (reset) begin
      for (i = 0; i < `ysyx_25010008_CACHE_SIZE; i = i + 1) begin
        cache[i][`ysyx_25010008_VALID_POS] <= 0;
      end
      pc <= 32'h8000_0000;
      arvalid <= 0;
      rready <= 0;
      inst_valid <= 0;
      delay = 0;
      state <= READ_CACHE;
      pipeline_empty <= 1;
    end else begin
      if (clear_cache) begin
        for (i = 0; i < `ysyx_25010008_CACHE_SIZE; i = i + 1) begin
          cache[i][`ysyx_25010008_VALID_POS] <= 0;
        end
      end

      if (clear_pipeline) begin
        // exception is prior
        pc <= npc;
        inst_valid <= 0;
        pipeline_empty <= 1;
      end else begin
        if (!block) inst_addr_misaligned_buffer[3:1] <= inst_addr_misaligned_buffer[2:0];

        if (state == READ_CACHE & !block & idu_ready) begin
          // sram don't need cache
          if (cache_valid && cache_tag == pc_tag) begin
            inst <= pc[3:2] == 2'b11 ? cache_block[127:96] : pc[3:2] == 2'b10 ? cache_block[95:64] : pc[3:2] == 2'b01 ? cache_block[63:32] : cache_block[31:0];
            inst_valid <= 1;
            ifu_pc <= pc;
            pc <= pc + 4;
            pipeline_empty <= 0;
          end else begin
            // avoid invalid memory access
            if (pipeline_empty || (npc_valid && pc == npc)) begin
              araddr <= {pc[31:4], 4'b0};
              arlen  <= 8'b11;
              if (pc[1:0] == 0) begin
                state   <= READ_MEMORY;
                arvalid <= 1;
              end else begin
                ifu_pc <= pc;
                inst_addr_misaligned_buffer[0] <= 1;
              end
            end
            inst_valid <= 0;
          end
        end
      end

      if (state == READ_MEMORY) begin
        delay = delay + 1;
        if (arvalid & arready) begin

          arvalid <= 0;
          rready  <= 1;
        end

        if (rready & rvalid) begin
          if (rlast) begin
            rready <= 0;

            state  <= READ_CACHE;

            delay = 0;
          end

          cache[index][`ysyx_25010008_VALID_POS-:`ysyx_25010008_TAG_WIDTH+1] <= {1'b1, pc_tag};
          cache[index][`ysyx_25010008_DATA_WIDTH-1:0] <= {
            rdata, cache[index][`ysyx_25010008_DATA_WIDTH-1:32]
          };
        end
      end
    end
  end

endmodule
