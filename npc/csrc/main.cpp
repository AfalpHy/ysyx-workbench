#include "VNPC.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

static VNPC *top = nullptr;

int main(int argc, char **argv) {
  VerilatedContext *contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  top = new VNPC{contextp};
  while (!contextp->gotFinish()) {
    top->clk = ~top->clk;
  }
  delete top;
  delete contextp;
  return 0;
}
