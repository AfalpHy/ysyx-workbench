import "DPI-C" function void set_pc(input [31:0] ptr[]);
import "DPI-C" function void ifu_record0();
import "DPI-C" function void ifu_record1(
  int inst,
  int npc
);
import "DPI-C" function void ifu_record2(int delay);

`define M 3 
`define N 4
`define DATA_WIDTH (2 ** `M) * 8
`define TAG_WIDTH 32 - (`M + `N) 
`define CACHE_WIDTH `TAG_WIDTH + `DATA_WIDTH + 1
`define CACHE_SIZE 2 ** `N

// in cache
`define VALID_POS `TAG_WIDTH + `DATA_WIDTH
`define CACHE_TAG_RANGE `TAG_WIDTH + `DATA_WIDTH - 1 : `DATA_WIDTH

// in pc
`define PC_TAG_RANGE 31 : `M + `N
`define PC_INDEX_RANGE `M + `N -1 : `M

module ysyx_25010008_IFU (
    input clock,
    input reset,

    input write_back,
    input [31:0] npc,
    output reg [31:0] pc,

    output reg [31:0] inst,
    output reg ivalid,
    input iready,

    output reg [31:0] araddr,
    output reg arvalid,
    input arready,

    output reg rready,
    input [31:0] rdata,
    input [1:0] rresp,
    input rvalid,
    input rlast,
    input clear_cache
);

  // set pointer of pc for cpp
  initial begin
    set_pc(pc);
  end

  reg [`TAG_WIDTH + `DATA_WIDTH : 0] cache[0:`CACHE_SIZE-1];

  integer i, delay;

  parameter READ_CACHE = 0;
  parameter READ_MEMORY = 1;
  parameter IDLE = 2;

  reg [1:0] state;
  wire [`N-1:0] index = pc[`PC_INDEX_RANGE];
  wire [`TAG_WIDTH-1:0] pc_tag = pc[`PC_TAG_RANGE];
  wire [`CACHE_WIDTH-1:0] cache_block = cache[index];
  wire valid = cache_block[`VALID_POS];
  wire [`TAG_WIDTH-1:0] cache_tag = cache_block[`CACHE_TAG_RANGE];

  assign araddr = {pc[31:`M], 1'b0, pc[`M-2:0]};

  always @(posedge clock) begin
    if (reset) begin
      for (i = 0; i < 16; i = i + 1) begin
        cache[i][`VALID_POS] <= 0;
      end
      pc <= 32'h3000_0000;
      arvalid <= 0;
      rready <= 0;
      ivalid <= 0;
      delay = 0;
      state <= READ_CACHE;
    end else begin
      if (state == READ_CACHE) begin
        // sram don't need cache
        if (pc[31:24] != 8'h0f && valid && cache_tag == pc_tag) begin
          inst   <= pc[2] ? cache_block[63:32] : cache_block[31:0];
          ivalid <= 1;
          state  <= IDLE;
          ifu_record0();
        end else begin
          state   <= READ_MEMORY;
          arvalid <= 1;
        end
      end else if (state == READ_MEMORY) begin
        delay = delay + 1;
        if (arvalid & arready) begin
          arvalid <= 0;
          rready  <= 1;
        end else if (rready & rvalid) begin
          if (rlast) begin
            rready <= 0;
            // updata inst if pc[2] is high
            if (pc[2]) inst <= rdata;
            if (pc[31:24] != 8'h0f) cache[index] <= {1'b1, pc_tag, rdata, inst};
            ivalid <= 1;
            state  <= IDLE;
            ifu_record2(delay);
            delay = 0;
          end else begin
            // use inst to save data for write cache if needed
            inst <= rdata;
          end
        end
      end else begin
        if (ivalid & iready) begin
          ivalid <= 0;
        end else if (write_back) begin
          if (clear_cache) begin
            for (i = 0; i < 16; i = i + 1) begin
              cache[i][`VALID_POS] <= 0;
            end
          end
          pc <= npc;
          ifu_record1(inst, npc);
          state <= READ_CACHE;
        end
      end
    end
  end

endmodule
