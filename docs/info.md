# JB16

JB16 is a small educational **16-bit accumulator CPU** written in synthesizable Verilog for Tiny Tapeout SKY130.

## CPU features

- 16-bit accumulator and ALU
- Addition, subtraction, AND, OR, XOR and NOT
- Left/right shifts, increment and decrement
- Zero, carry and negative flags
- 64-word program address space
- Eight 16-bit data-RAM words
- Conditional and unconditional jumps
- 8-bit external input, zero-extended to 16 bits
- Full 16-bit external output
- Halt and enable control

The complete output word is:

```text
{uio_out, uo_out}
```

`uo_out` is the lower byte and `uio_out` is the upper byte.

## Built-in demonstration program

After reset the program outputs:

```text
0003
0002
0001
AA55
```

It then repeatedly reads `ui_in`, adds one, and writes the 16-bit answer to the output.

For example:

```text
ui_in = 2A  -> output = 002B
ui_in = FF  -> output = 0100
```

See `PROGRAM.md` for the instruction encoding and `START_HERE.md` for build instructions.
