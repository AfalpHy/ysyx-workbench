#include "VNPC.h"
#include "verilated.h"
#include "verilated_dpi.h"
#include "verilated_vcd_c.h"
#include <assert.h>
#include <fstream>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>

using namespace std;

static VNPC *top = nullptr;

uint32_t *pc = nullptr;
uint32_t *regs = nullptr;
uint32_t *pmem = nullptr;

extern "C" void set_pc(const svOpenArrayHandle r) {
  pc = (uint32_t *)(((VerilatedDpiOpenVar *)r)->datap());
}

extern "C" void set_regs_ptr(const svOpenArrayHandle r) {
  regs = (uint32_t *)(((VerilatedDpiOpenVar *)r)->datap());
}

extern "C" void set_memory_ptr(const svOpenArrayHandle r) {
  pmem = (uint32_t *)(((VerilatedDpiOpenVar *)r)->datap());
}

extern "C" uint32_t pmem_read(uint32_t addr, int len) {
  auto pmem_addr = addr - 0x80000000;
  switch (len) {
  case 1:
    return pmem[pmem_addr];
  case 2:
    return pmem[pmem_addr + 1] << 8 | pmem[pmem_addr];
  case 4:
    return pmem_read(addr + 2, 2) << 16 | pmem_read(addr, 2);
  default:
    assert(0);
    break;
  }
}

int load_img(const string &filepath) {
  cout << filepath << endl;
  ifstream file(filepath, ios::binary);
  assert(file.is_open());
  file.seekg(0, ios::end);
  size_t size = file.tellg();
  file.seekg(0, ios::beg);
  file.read((char *)pmem, size);
  file.close();
  return size;
}

void reset() {
  top->rst = 1;
  top->clk = 1;
  top->eval();
  top->clk = 0;
  top->eval();
  top->rst = 0;
  cout<<*pc<<endl;
}

int main(int argc, char **argv) {
  VerilatedContext *contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  top = new VNPC{contextp};
  top->eval();
  vector<string> imgs;
  imgs.push_back(argv[1]);
  for (const auto &img : imgs) {
    load_img(img);
    reset();

  }
  while (!contextp->gotFinish()) {
    top->clk = 1;
    top->eval();
    top->clk = 0;
    top->eval();
   cout<<hex<<pc<<" " <<*pc<<endl; 
    
    int c;
    cin>>c;
    if (top->halt) {
      break;
    }
  }
  delete top;
  delete contextp;
  return 0;
}
