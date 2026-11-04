# RV32I Single-Cycle RISC-V Core

A single-cycle processor implementing the RISC-V RV32I base integer instruction set, written in SystemVerilog and verified with self-checking testbenches in Icarus Verilog.

## Status

| Module | File | Description | Tests |
|---|---|---|---|
| ALU | `rtl/alu.sv` | Add, sub, AND/OR/XOR, logical and arithmetic shifts, signed and unsigned compare | ✅ 15/15 |
| Register file | `rtl/regfile.sv` | 32 × 32-bit, two read ports, one write port, x0 hardwired to zero | ✅ 36/36 |
| Immediate generator | `rtl/imm_gen.sv` | Extracts and sign-extends I, S, B, U, and J immediates | ✅ 11/11 |
| Control unit | `rtl/control.sv` | Main decoder and ALU decoder for all RV32I opcodes | ✅ 14/14 |
| Branch comparator | `rtl/branch_comp.sv` | beq, bne, blt, bge, bltu, bgeu | ✅ 13/13 |
| Instruction & data memory | `rtl/imem.sv`, `rtl/dmem.sv` | Word, halfword, and byte loads and stores | 🚧 In progress |
| Top-level datapath | `rtl/riscv_top.sv` | Connects all modules into a working CPU | 🚧 In progress |
| Full-CPU tests | `tests/` | RISC-V programs run on the complete core | 🚧 In progress |

## Verification approach

Every module has a **self-checking testbench**: each test compares the output against a hand-computed expected value and prints PASS or FAIL, followed by a summary. No waveform inspection is needed to confirm correctness.

Tests target the edge cases where RV32I implementations commonly break:

- **Arithmetic:** overflow wraparound, shifts using only the low 5 bits of the shift amount, arithmetic vs. logical right shift
- **Signed vs. unsigned:** the same inputs checked with `slt`/`sltu` and `blt`/`bltu`, including the most negative vs. most positive 32-bit values
- **Register file:** writes to x0 ignored, write enable respected, all 31 registers storing independently
- **Decoding:** the immediate generator and control unit are tested with real RV32I machine code, including negative immediates and an `addi` whose immediate sets bit 30 (which must not be decoded as `sub`)
- **Timing:** clocked testbenches drive inputs on the falling edge to avoid races with rising-edge writes

## Repository layout

```
rtl/     design modules
tb/      testbenches
tests/   test programs for the full CPU
```

## Running the tests

Requires [Icarus Verilog](https://steveicarus.github.io/iverilog/). [GTKWave](https://gtkwave.sourceforge.net/) is optional, for viewing waveforms.

```
mkdir build
iverilog -g2012 -o build/alu_tb rtl/alu.sv tb/alu_tb.sv
vvp build/alu_tb
```

Each module follows the same pattern: compile the module with its testbench, then run it with `vvp`. Waveforms are saved to `build/<module>_tb.vcd`.

## Tools

SystemVerilog · Icarus Verilog · GTKWave · Git