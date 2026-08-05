SOURCES = \
	../src/jb16_alu.v \
	../src/jb16_rom.v \
	../src/jb16_cpu.v \
	../src/tt_um_jonathanb_jb16.v \
	test.v

SIM = jb16_sim

all:
	iverilog -g2012 -s test -o $(SIM) $(SOURCES)
	vvp $(SIM)

wave:
	gtkwave jb16.vcd

clean:
	rm -f $(SIM) jb16.vcd
