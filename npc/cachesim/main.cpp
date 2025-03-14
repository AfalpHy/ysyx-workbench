#include <fstream>
#include <iostream>

#define BITMASK(bits) ((1ull << (bits)) - 1)
#define BITS(x, hi, lo)                                                        \
  (((x) >> (lo)) & BITMASK((hi) - (lo) + 1)) // similar to x[hi:lo] in verilog

typedef unsigned word_t;
typedef unsigned vaddr_t;

typedef struct {
  bool valid;
  word_t tag;
} cache_block;

cache_block icache[16];

bool vaddr_ifetch(vaddr_t addr) {
  word_t tag = BITS(addr, 31, 6);
  word_t index = BITS(addr, 5, 2);
  if (icache[index].valid && icache[index].tag == tag) {
    return true;
  }
  icache[index].tag = tag;
  icache[index].valid = 1;
  return false;
}

int main() { return 0; }