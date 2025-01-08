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

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(BUILD_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

all: $(BIN)

clean:
	rm -rf $(BUILD_DIR)

sim: all
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@$(BIN) -img=$(IMG)	

gdb: CXXFLAGS += -g
gdb: VERILATOR_CFLAGS := $(filter-out -O3,$(VERILATOR_CFLAGS))
gdb: all 
	$(call git_commit, "sim RTL")
	gdb -args $(BIN) -img=$(IMG) 


.PHONY: all clean sim gdb

include ../Makefile