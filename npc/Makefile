TOPNAME = NPC
INC_PATH ?= $(NPC_HOME)/include
VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc --trace\
				-O3 --x-assign fast --x-initial fast --noassert

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

$(shell mkdir -p $(BUILD_DIR))

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS)
LDFLAGS += -lSDL2 -lSDL2_image -lreadline -lLLVM-14

ifdef RV32IM
override CXXFLAGS += -DRV32IM
else ifdef RV64IM
override CXXFLAGS += -DRV64IM
else
override CXXFLAGS += -DRV32E
endif

ARGS = -img=$(IMG) -elf=$(basename $(IMG)).elf

ifdef DIFF_TEST
override ARGS += -diff_so=$(NEMU_HOME)/build/riscv32-nemu-interpreter-so
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

sim: ARGS += -b
sim: all
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@$(BIN) $(ARGS)	

gdb: CXXFLAGS += -g -DITRACE -DMTRACE -DFTRACE
gdb: VERILATOR_CFLAGS := $(filter-out -O3,$(VERILATOR_CFLAGS))
gdb: all 
	$(call git_commit, "sim RTL")
	gdb -args $(BIN) $(ARGS)


.PHONY: all clean sim gdb

include ../Makefile