TOPNAME = ysyxSoCFull
INC_PATH ?= $(NPC_HOME)/include
NXDC_FILES = constr/$(TOPNAME).nxdc
YSYX_SOC = $(abspath ../ysyxSoC)
PERIP = $(abspath $(YSYX_SOC)/perip)
VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc -O3 -j $(shell nproc) --timescale "1ns/1ns" --no-timing --trace\
				-I$(PERIP)/uart16550/rtl -I$(PERIP)/spi/rtl\
				--x-assign fast --x-initial fast --noassert --autoflush

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

$(shell mkdir -p $(BUILD_DIR))

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
VSRCS += $(shell find $(PERIP) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME=V$(TOPNAME)
LDFLAGS += -lSDL2 -lSDL2_image -lreadline -lLLVM-14

ifdef RV32IM
override CXXFLAGS += -DRV32IM=1
else ifdef RV64IM
override CXXFLAGS += -DRV64IM=1
else
override CXXFLAGS += -DRV32E=1
endif

ifdef TRACE
override CXXFLAGS += -DITRACE -DMTRACE -DFTRACE -DTRACE_WAVE
endif

ifdef ITRACE
override CXXFLAGS += -DITRACE
endif

ifdef MTRACE
override CXXFLAGS += -DMTRACE
endif

ifdef FTRACE
override CXXFLAGS += -DFTRACE
endif

ifdef TRACE_WAVE
override CXXFLAGS += -DTRACE_WAVE
endif

ifdef IMG
ARGS = -log=$(shell dirname $(IMG))/npc-log.txt -img=$(IMG) -elf=$(basename $(IMG)).elf -ftrace-log=$(shell dirname $(IMG))/npc-ftrace-log.txt
else
ARGS = -log=$(BUILD_DIR)/npc-log.txt -ftrace-log=$(BUILD_DIR)/npc-ftrace-log.txt
endif

ifdef DIFF_TEST
override ARGS += -diff_so=$(NEMU_HOME)/build/riscv32-nemu-interpreter-so
endif

ifdef BATCH
override ARGS += -b 
endif

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

all: $(BIN)

clean:
	rm -rf $(BUILD_DIR)

sim: all
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@$(BIN) $(ARGS)	

gdb: CXXFLAGS += -g
gdb: VERILATOR_CFLAGS := $(filter-out -O3,$(VERILATOR_CFLAGS))
gdb: all 
	$(call git_commit, "sim RTL")
	gdb -args $(BIN) $(ARGS)


.PHONY: all clean sim gdb

include ../Makefile