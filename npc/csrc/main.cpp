#include "VNPC.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

static TOP_NAME* top = nullptr;

int main(int argc, char **argv) {
  VerilatedContext *contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  top = new TOP_NAME{contextp};
  while (!contextp->gotFinish()) {
  }
  delete top;
  delete contextp;
  return 0;
}
