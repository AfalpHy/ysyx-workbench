all:
	@echo "Write this Makefile by your self."

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	verilator --cc --exe --build -j 0 -Wall csrc/*.cpp vsrc/*.v

include ../Makefile
