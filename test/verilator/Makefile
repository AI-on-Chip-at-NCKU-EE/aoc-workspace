TB_SRC = testbench.cc
BIN = obj_dir/VCounter

VFLAGS = -Wall --cc --exe --build --trace
VC = verilator

.PHONY: all clean format run

all: $(BIN)
	./$<

obj_dir/V%: %.v $(TB_SRC)
	@mkdir -p obj_dir
	$(VC) $(VFLAGS) $^

format:
	clang-format -i testbench.cc tb/*.cpp

clean:
	$(RM) -rv obj_dir *.vcd
