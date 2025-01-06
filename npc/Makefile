TOPNAME = NPC
VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc --trace\
				 --x-assign fast --x-initial fast --noassert

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

$(shell mkdir -p $(BUILD_DIR))

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -g

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
	@gdb -args $(BIN) $(IMG)	

# GDB: CFLAGS += -g
# GDB: VERILATOR_CFLAGS := $(filter-out -O3,$(VERILATOR_CFLAGS))
# GDB: $(BIN)
# 	$(call git_commit, "sim RTL")
# 	gdb -args $^ $(NPCFLAGS) 


.PHONY: all clean sim

include ../Makefile