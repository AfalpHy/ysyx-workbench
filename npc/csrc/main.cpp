#include "device.h"
#include "difftest.h"
#include "disasm.h"
#include "exec.h"
#include "expr.h"
#include "ftrace.h"
#include "isa.h"
#include "pmem.h"
#include "sdb.h"
#include "watchpoint.h"
#include <VysyxSoCFull.h>
#include <fstream>
#include <iostream>
#include <signal.h>
#include <sys/time.h>
#include <vector>
#include <verilated_vcd_c.h>

using namespace std;

VerilatedContext *contextp = nullptr;
TOP_NAME top;

int status = 0;
bool diff_test_on = false;
uint64_t begin_us;

FILE *log_fp = nullptr;
extern FILE *ftrace_log;

void fflush_trace() {
  if (log_fp) {
    fflush(log_fp);
  }
  if (ftrace_log) {
    fflush(ftrace_log);
  }
}
bool interrupt = false;
void sigint_handler(int sig) {
  interrupt = true;
  printf("receive SIGINT\n");
}
void sigsegv_handler(int sig) {
  fflush_trace();
  printf("receive SIGSEGV\n");
  exit(1);
}

int load_img(const string &filepath) {
  ifstream file(filepath, ios::binary);
  Assert(file.is_open(), "load img failed");
  file.seekg(0, ios::end);
  size_t size = file.tellg();
  file.seekg(0, ios::beg);
  file.read((char *)pmem, size);
  file.close();
  return size;
}

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Verilated::mkdir("logs");
  contextp = new VerilatedContext;
  contextp->traceEverOn(true);
  contextp->timeInc(1);
  contextp->timeInc(1);
  signal(SIGINT, sigint_handler);
  signal(SIGSEGV, sigsegv_handler);
  struct timeval now;
  gettimeofday(&now, NULL);
  begin_us = now.tv_sec * 1000000 + now.tv_usec;
  // initial
  top.eval();

  string img;
  string ref_so;
  vector<string> elf_files;
  int size;
  for (int i = 0; i < argc; i++) {
    string tmp = argv[i];
    string option;
    int pos = 0;
    if (tmp[pos] != '-') {
      continue;
    }
    for (pos++; pos < tmp.length() && tmp[pos] != '='; pos++) {
      option.push_back(tmp[pos]);
    }
    if (option == "log") {
      log_fp = fopen(tmp.substr(pos + 1).c_str(), "w");
      Assert(log_fp, "open log file failed");
    } else if (option == "img") {
      img = tmp.substr(pos + 1);
      size = load_img(img);
    } else if (option == "diff_so") {
      ref_so = tmp.substr(pos + 1);
    } else if (option == "b") {
      sdb_set_batch_mode();
    } else if (option == "elf") {
      elf_files.push_back(tmp.substr(pos + 1));
    } else if (option == "ftrace-log") {
      ftrace_log = fopen(tmp.substr(pos + 1).c_str(), "w");
      Assert(ftrace_log, "open log file failed");
    }
  }
  // expr
  init_regex();
  // disasm
  init_disasm("riscv64-pc-linux-gnu");
  // init watchpoint
  init_wp_pool();
  // init sdl
  // init_vga();
  reset();
  if (!ref_so.empty()) {
    init_difftest(ref_so.c_str(), size);
    diff_test_on = true;
  }
#ifdef FTRACE
  init_elf(elf_files);
#endif

  sdb_mainloop();
  if (status != 0 || isa_reg_str2val("a0") != 0) {
    status = -1;
    cout << img << "\033[31m\tBAD TRAP\033[0m" << endl;
  } else {
    cout << img << "\033[32m\tGOOD TRAP\033[0m" << endl;
  }
  return status;
}