# JB16 CPU Instruction Set

## CPU overview

| Feature | Specification |
|---|---|
| CPU name | `JB16` |
| Architecture | 16-bit accumulator CPU |
| Data width | 16 bits |
| Instruction width | 16 bits |
| Opcode width | 4 bits |
| Operand width | 12 bits |
| Program counter width | 6 bits |
| Program memory | 64 instructions |
| Data RAM | 8 words of 16 bits |
| External input | 8 bits |
| External output | 16 bits |
| Flags | Zero, carry and negative |
| Number of opcodes | 16 |
| Execution style | One instruction per clock cycle |
| Target platform | Tiny Tapeout |

---

## Instruction format

Every instruction is exactly 16 bits wide:

```text
Bit:  15              12 11                              0
      ┌─────────────────┬─────────────────────────────────┐
      │  4-bit opcode   │         12-bit operand          │
      └─────────────────┴─────────────────────────────────┘
```

The instruction is divided into:

| Field | Width | Purpose |
|---|---:|---|
| Opcode | 4 bits | Selects one of 16 instructions |
| Operand | 12 bits | Contains a constant, RAM address or jump address |

Because one hexadecimal digit represents four bits, every instruction can be written using four hexadecimal digits:

```text
Opcode    Operand
   1        ABC

Full instruction: 1ABC
```

---

# Opcode table

| Hex opcode | Binary opcode | Instruction | Operand use | Operation | Flags updated |
|:---:|:---:|---|---|---|:---:|
| `0` | `0000` | `NOP` | Ignored | Do nothing and continue to the next instruction | None |
| `1` | `0001` | `LDI` | Full 12-bit operand | Load the zero-extended operand into the accumulator | `Z`, `N` |
| `2` | `0010` | `LUI` | Lowest 8 operand bits | Replace the upper byte of the accumulator | `Z`, `N` |
| `3` | `0011` | `ADDI` | Full 12-bit operand | Add the zero-extended operand to the accumulator | `Z`, `C`, `N` |
| `4` | `0100` | `SUBI` | Full 12-bit operand | Subtract the zero-extended operand from the accumulator | `Z`, `C`, `N` |
| `5` | `0101` | `ANDI` | Full 12-bit operand | AND the lowest 12 accumulator bits with the operand | `Z`, `N` |
| `6` | `0110` | `ORI` | Full 12-bit operand | OR the lowest 12 accumulator bits with the operand | `Z`, `N` |
| `7` | `0111` | `XORI` | Full 12-bit operand | XOR the lowest 12 accumulator bits with the operand | `Z`, `N` |
| `8` | `1000` | `LOAD` | Lowest 3 operand bits | Load a 16-bit value from RAM | `Z`, `N` |
| `9` | `1001` | `STORE` | Lowest 3 operand bits | Store the accumulator in RAM | None |
| `A` | `1010` | `JMP` | Lowest 6 operand bits | Jump unconditionally to another instruction address | None |
| `B` | `1011` | `JZ` | Lowest 6 operand bits | Jump when the zero flag is `1` | None |
| `C` | `1100` | `JNZ` | Lowest 6 operand bits | Jump when the zero flag is `0` | None |
| `D` | `1101` | `IN` | Ignored | Read the 8-bit external input into the accumulator | `Z`, `N` |
| `E` | `1110` | `OUT` | Ignored | Copy the accumulator into the output register | None |
| `F` | `1111` | `HALT` | Ignored | Stop the CPU until reset | None |

---

# Detailed instruction behaviour

## `NOP` — No operation

```text
Opcode: 0000
```

The CPU does nothing except continue to the next instruction.

```text
PC = PC + 1
```

Example:

```text
Assembly:    NOP
Machine code: 0000
```

---

## `LDI` — Load immediate

```text
Opcode: 0001
```

`LDI` loads the full 12-bit operand into the accumulator.

Four zero bits are added to the front to make a 16-bit value:

```text
ACC = {4'b0000, operand[11:0]}
```

The possible immediate range is:

```text
Hexadecimal: 000 to FFF
Decimal:     0 to 4095
```

Example:

```text
Assembly:     LDI ABC
Machine code: 1ABC
```

Result:

```text
ACC = 0ABC
```

`LDI` updates:

```text
Z = 1 if ACC becomes 0000
N = ACC[15]
```

Because `LDI` always puts four zeroes at the front, its result cannot be negative.

---

## `LUI` — Load upper immediate

```text
Opcode: 0010
```

`LUI` replaces the upper eight bits of the accumulator while keeping the lower eight bits unchanged.

```text
ACC = {operand[7:0], ACC[7:0]}
```

Only the lowest eight operand bits are used.

Example:

```text
Before:
ACC = 0BCD
```

Instruction:

```text
Assembly:     LUI AB
Machine code: 20AB
```

After:

```text
ACC = ABCD
```

This allows any 16-bit constant to be created using two instructions:

```text
LDI BCD
LUI AB
```

Result:

```text
ACC = ABCD
```

---

## `ADDI` — Add immediate

```text
Opcode: 0011
```

`ADDI` adds the full 12-bit operand to the accumulator.

```text
ACC = ACC + {4'b0000, operand[11:0]}
```

Example:

```text
Before:
ACC = 0010
```

Instruction:

```text
Assembly:     ADDI 005
Machine code: 3005
```

After:

```text
ACC = 0015
```

The carry flag stores the extra addition bit.

Example:

```text
FFFF + 0001 = 1_0000
              ↑
              Carry
```

Result:

```text
ACC = 0000
C   = 1
Z   = 1
N   = 0
```

---

## `SUBI` — Subtract immediate

```text
Opcode: 0100
```

`SUBI` subtracts the full 12-bit operand from the accumulator.

```text
ACC = ACC - {4'b0000, operand[11:0]}
```

Example:

```text
Before:
ACC = 000A
```

Instruction:

```text
Assembly:     SUBI 003
Machine code: 4003
```

After:

```text
ACC = 0007
```

For subtraction, the carry flag means:

```text
C = 1 when no borrow was required
C = 0 when a borrow was required
```

Example:

```text
0003 - 0005 = FFFE
```

The 16-bit pattern `FFFE` represents `-2` when interpreted as a signed two's-complement number.

---

## `ANDI` — Bitwise AND immediate

```text
Opcode: 0101
```

`ANDI` performs bitwise AND on the lowest 12 accumulator bits.

The upper four accumulator bits stay unchanged:

```text
ACC = {
    ACC[15:12],
    ACC[11:0] & operand[11:0]
}
```

Example:

```text
ACC     = A5F3
Operand = 00FF
```

Calculation:

```text
Lower 12 accumulator bits: 0101 1111 0011
Operand:                    0000 1111 1111
Result:                     0000 1111 0011
```

Final result:

```text
ACC = A0F3
```

Example instruction:

```text
Assembly:     ANDI 0FF
Machine code: 50FF
```

---

## `ORI` — Bitwise OR immediate

```text
Opcode: 0110
```

`ORI` performs bitwise OR on the lowest 12 accumulator bits.

The upper four bits stay unchanged:

```text
ACC = {
    ACC[15:12],
    ACC[11:0] | operand[11:0]
}
```

Example:

```text
ACC     = A003
Operand = 0F00
```

Result:

```text
ACC = AF03
```

Example instruction:

```text
Assembly:     ORI 080
Machine code: 6080
```

---

## `XORI` — Bitwise XOR immediate

```text
Opcode: 0111
```

`XORI` performs bitwise XOR on the lowest 12 accumulator bits.

The upper four bits stay unchanged:

```text
ACC = {
    ACC[15:12],
    ACC[11:0] ^ operand[11:0]
}
```

Example:

```text
ACC     = A0FF
Operand = 00FF
```

Result:

```text
ACC = A000
```

Example instruction:

```text
Assembly:     XORI FFF
Machine code: 7FFF
```

---

## `LOAD` — Load from RAM

```text
Opcode: 1000
```

JB16 has eight RAM locations:

```text
RAM[0]
RAM[1]
RAM[2]
RAM[3]
RAM[4]
RAM[5]
RAM[6]
RAM[7]
```

Only the lowest three operand bits select the RAM address:

```text
ACC = RAM[operand[2:0]]
```

Example:

```text
Assembly:     LOAD 3
Machine code: 8003
```

Operation:

```text
ACC = RAM[3]
```

The loaded value updates the zero and negative flags.

---

## `STORE` — Store in RAM

```text
Opcode: 1001
```

`STORE` copies the accumulator into one of the eight RAM locations.

```text
RAM[operand[2:0]] = ACC
```

Example:

```text
Assembly:     STORE 3
Machine code: 9003
```

Operation:

```text
RAM[3] = ACC
```

The accumulator and flags are not changed.

---

## `JMP` — Unconditional jump

```text
Opcode: 1010
```

`JMP` replaces the program counter with the lowest six operand bits:

```text
PC = operand[5:0]
```

A six-bit address can select:

```text
0 to 63
```

Example:

```text
Assembly:     JMP 10
Machine code: A00A
```

The next instruction will be read from program address decimal `10`.

---

## `JZ` — Jump if zero

```text
Opcode: 1011
```

`JZ` checks the zero flag.

```text
If Z = 1:
    PC = operand[5:0]

Otherwise:
    PC = PC + 1
```

Example:

```text
Assembly:     JZ 4
Machine code: B004
```

The jump happens only when the previous result was zero.

---

## `JNZ` — Jump if not zero

```text
Opcode: 1100
```

`JNZ` jumps when the zero flag is clear.

```text
If Z = 0:
    PC = operand[5:0]

Otherwise:
    PC = PC + 1
```

Example:

```text
Assembly:     JNZ 1
Machine code: C001
```

This instruction is useful for loops.

---

## `IN` — Read external input

```text
Opcode: 1101
```

`IN` reads the eight Tiny Tapeout input pins.

The input is zero-extended to 16 bits:

```text
ACC = {8'h00, input_pins[7:0]}
```

Example:

```text
input_pins = A5
```

After `IN`:

```text
ACC = 00A5
```

Machine code:

```text
D000
```

The operand is ignored.

---

## `OUT` — Update external output

```text
Opcode: 1110
```

`OUT` copies the accumulator into the 16-bit output register:

```text
output_register = ACC
```

Example:

```text
ACC = ABCD
```

After `OUT`:

```text
output_register = ABCD
```

For Tiny Tapeout:

```text
uio_out = AB
uo_out  = CD
```

The complete output is:

```text
{uio_out, uo_out} = ABCD
```

Machine code:

```text
E000
```

---

## `HALT` — Stop the CPU

```text
Opcode: 1111
```

`HALT` stops instruction execution:

```text
halted = 1
```

The program counter stops changing.

The accumulator, RAM, flags and output keep their existing values.

The CPU remains halted until reset.

Machine code:

```text
F000
```

---

# CPU flags

| Flag | Full name | Meaning |
|:---:|---|---|
| `Z` | Zero flag | Set when the new accumulator value equals `16'h0000` |
| `C` | Carry flag | Stores carry-out from addition or indicates no borrow during subtraction |
| `N` | Negative flag | Copies bit `15` of the new accumulator value |

## Zero flag

```text
ACC = 0000 → Z = 1
ACC ≠ 0000 → Z = 0
```

## Carry flag during addition

```text
FFFF + 0001 = 1_0000
              ↑
              C = 1
```

## Carry flag during subtraction

```text
C = 1 → no borrow
C = 0 → borrow occurred
```

## Negative flag

```text
N = ACC[15]
```

Examples:

```text
ACC = 0005 → N = 0
ACC = FFFE → N = 1
```

---

# Machine-code examples

| Assembly instruction | Machine code | Explanation |
|---|:---:|---|
| `NOP` | `16'h0000` | Do nothing |
| `LDI 005` | `16'h1005` | Load decimal `5` |
| `LDI ABC` | `16'h1ABC` | Load hexadecimal `0ABC` |
| `LDI FFF` | `16'h1FFF` | Load decimal `4095` |
| `LUI AB` | `16'h20AB` | Replace the accumulator's upper byte with `AB` |
| `ADDI 003` | `16'h3003` | Add decimal `3` |
| `ADDI FFF` | `16'h3FFF` | Add decimal `4095` |
| `SUBI 001` | `16'h4001` | Subtract decimal `1` |
| `ANDI 0FF` | `16'h50FF` | AND the lowest 12 bits with `0FF` |
| `ORI 080` | `16'h6080` | Set bit `7` |
| `XORI FFF` | `16'h7FFF` | Toggle the lowest 12 bits |
| `LOAD 2` | `16'h8002` | Load RAM location `2` |
| `STORE 2` | `16'h9002` | Store in RAM location `2` |
| `JMP 10` | `16'hA00A` | Jump to decimal address `10` |
| `JZ 4` | `16'hB004` | Jump to address `4` when zero |
| `JNZ 1` | `16'hC001` | Jump to address `1` when not zero |
| `IN` | `16'hD000` | Read the external input |
| `OUT` | `16'hE000` | Update the external output |
| `HALT` | `16'hF000` | Stop the CPU |

---

# Example program: create and output `ABCD`

| Address | Assembly | Machine code | Purpose |
|:---:|---|:---:|---|
| `0` | `LDI BCD` | `16'h1BCD` | Load the lower part of the value |
| `1` | `LUI AB` | `16'h20AB` | Replace the upper byte with `AB` |
| `2` | `OUT` | `16'hE000` | Output `ABCD` |
| `3` | `HALT` | `16'hF000` | Stop the CPU |

Accumulator values:

```text
After LDI BCD: ACC = 0BCD
After LUI AB:  ACC = ABCD
After OUT:     output_register = ABCD
```

---

# Example program: countdown from five

| Address | Assembly | Machine code | Purpose |
|:---:|---|:---:|---|
| `0` | `LDI 005` | `16'h1005` | Start at `5` |
| `1` | `OUT` | `16'hE000` | Display the current value |
| `2` | `SUBI 001` | `16'h4001` | Subtract `1` |
| `3` | `JNZ 1` | `16'hC001` | Repeat while the result is not zero |
| `4` | `OUT` | `16'hE000` | Display the final zero |
| `5` | `HALT` | `16'hF000` | Stop the CPU |

Expected output sequence:

```text
0005
0004
0003
0002
0001
0000
```

---

# Example program: input plus one

| Address | Assembly | Machine code | Purpose |
|:---:|---|:---:|---|
| `0` | `IN` | `16'hD000` | Read the 8-bit input |
| `1` | `ADDI 001` | `16'h3001` | Add one |
| `2` | `OUT` | `16'hE000` | Update the output |
| `3` | `JMP 0` | `16'hA000` | Repeat forever |

Example:

```text
Input:  FF
ACC after IN:    00FF
ACC after ADDI:  0100
Output:          0100
```

---

# Operand usage summary

| Instruction group | Operand bits used | Maximum value |
|---|---|---:|
| `LDI` | `operand[11:0]` | `FFF` |
| `LUI` | `operand[7:0]` | `FF` |
| `ADDI` | `operand[11:0]` | `FFF` |
| `SUBI` | `operand[11:0]` | `FFF` |
| `ANDI` | `operand[11:0]` | `FFF` |
| `ORI` | `operand[11:0]` | `FFF` |
| `XORI` | `operand[11:0]` | `FFF` |
| `LOAD` | `operand[2:0]` | RAM address `7` |
| `STORE` | `operand[2:0]` | RAM address `7` |
| `JMP` | `operand[5:0]` | Program address `63` |
| `JZ` | `operand[5:0]` | Program address `63` |
| `JNZ` | `operand[5:0]` | Program address `63` |
| `NOP`, `IN`, `OUT`, `HALT` | Operand ignored | — |
