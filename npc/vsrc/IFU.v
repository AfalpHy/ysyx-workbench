import "DPI-C" function void set_pc(input [31:0] ptr[]);
import "DPI-C" function void ifu_record0();
import "DPI-C" function void ifu_record1(
  int inst,
  int npc
);

`define M 2
`define N 4
`define BLOCK_BYTE_SIZE 2 ** `M
`define BLOCK_WIDTH `BLOCK_BYTE_SIZE * 8
`define TAG_WIDTH 32 - (`M+`N) 
`define CACHE_SIZE 2 ** `N

// in cache
`define VALID_POS `TAG_WIDTH + `BLOCK_WIDTH
`define CACHE_TAG_RANGE `TAG_WIDTH + `BLOCK_WIDTH - 1 : `BLOCK_WIDTH
`define CACHE_BLOCK_RANGE `BLOCK_WIDTH - 1 : 0

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

    output reg arvalid,
    input arready,

    output reg rready,
    input [31:0] rdata,
    input [1:0] rresp,
    input rvalid
);

  // set pointer of pc for cpp
  initial begin
    set_pc(pc);
  end

  reg [`TAG_WIDTH + `BLOCK_WIDTH : 0] cache[0:`CACHE_SIZE-1];

  integer i;

  parameter READ_CACHE = 0;
  parameter READ_MEMORY = 1;
  parameter IDLE = 2;

  reg [1:0] state;

  always @(posedge clock) begin
    if (reset) begin
      for (i = 0; i < 16; i = i + 1) begin
        cache[i][`VALID_POS] <= 0;
      end
      pc <= 32'h3000_0000;
      arvalid <= 0;
      rready <= 0;
      ivalid <= 0;
      state <= READ_CACHE;
    end else begin
      if (state == READ_CACHE) begin
        if (cache[pc[`PC_INDEX_RANGE]][`VALID_POS] && cache[pc[`PC_INDEX_RANGE]][`CACHE_TAG_RANGE] == pc[`PC_TAG_RANGE]) begin
          ivalid <= 1;
          inst   <= cache[pc[`PC_INDEX_RANGE]][`CACHE_BLOCK_RANGE];
          ifu_record0();
          state <= IDLE;
        end else begin
          state   <= READ_MEMORY;
          arvalid <= 1;
        end
      end else if (state == READ_MEMORY) begin
        if (arvalid & arready) begin
          arvalid <= 0;
          rready  <= 1;
        end else if (rready & rvalid) begin
          if (rresp != 0) begin
            $display("%h", pc);
            $finish;
          end
          rready <= 0;
          inst <= rdata;
          cache[pc[`PC_INDEX_RANGE]][`CACHE_BLOCK_RANGE] <= rdata;
          cache[pc[`PC_INDEX_RANGE]][`CACHE_TAG_RANGE] <= pc[`PC_TAG_RANGE];
          cache[pc[`PC_INDEX_RANGE]][`VALID_POS] <= 1;
          ivalid <= 1;
          state <= IDLE;
        end
      end else begin
        if (ivalid & iready) begin
          ivalid <= 0;
        end else if (write_back) begin
          pc <= npc;
          ifu_record1(inst, npc);
          state <= READ_CACHE;
        end
      end
    end
  end

endmodule
