#include "device.h"
#include "difftest.h"
#include "disasm.h"
#include "exec.h"
#include "expr.h"
#include "isa.h"
#include "memory.h"
#include "sdb.h"
#include "watchpoint.h"
#include <VNPC.h>
#include <fstream>
#include <iostream>
#include <sys/time.h>

using namespace std;

VNPC top;

int status = 0;
bool diff_test_on = false;
uint64_t begin_us;

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
  struct timeval now;
  gettimeofday(&now, NULL);
  begin_us = now.tv_sec * 1000000 + now.tv_usec;
  // initial
  top.eval();

  string img;
  string ref_so;
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
    if (option == "img") {
      img = tmp.substr(pos + 1);
    } else if (option == "diff_so") {
      ref_so = tmp.substr(pos + 1);
    } else if (option == "b") {
      sdb_set_batch_mode();
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
  int size = load_img(img);
  reset();
  if (!ref_so.empty()) {
    init_difftest(ref_so.c_str(), size);
    diff_test_on = true;
  }
  sdb_mainloop();
  if (status != 0 || isa_reg_str2val("a0") != 0) {
    status = -1;
    cout << img << "\033[31m\tBAD TRAP\033[0m" << endl;
  } else {
    cout << img << "\033[32m\tGOOD TRAP\033[0m" << endl;
  }
  return status;
}