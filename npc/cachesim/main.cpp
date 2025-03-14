#include <fstream>
#include <iostream>
using namespace std;

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

int get = 0;
void vaddr_ifetch(vaddr_t addr) {
  if (BITS(addr, 31, 24) == 0x0f) {
    return;
  }
  word_t tag = BITS(addr, 31, 6);
  word_t index = BITS(addr, 5, 2);
  if (icache[index].valid && icache[index].tag == tag) {
    get++;
    return;
  }
  icache[index].tag = tag;
  icache[index].valid = 1;
}
int main() {
  ifstream file("../pc_trace.bin", ios::binary);
  if (!file.is_open()) {
    return -1;
  }
  while (!file.eof()) {
    vaddr_t pc;
    int follow;
    file.read((char *)&pc, 4);
    file.read((char *)&follow, 4);
    while (follow-- >= 0) {
      vaddr_ifetch(pc);
      pc += 4;
    }
  }
  std::cout << "get:" << get << std::endl;
  return 0;
}