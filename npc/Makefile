all:
	@echo "Write this Makefile by your self."

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	verilator --cc --exe --build --trace -j 0 -Wall csrc/*.cpp vsrc/*.v
	obj_dir/Vexample

include ../Makefile
