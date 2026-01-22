# GPP16 - 16-bit General Purpose Processor

**GPP16** is a custom 16-bit RISC (Reduced Instruction Set Computer) microprocessor implementation in SystemVerilog. It features a simplified pipelined control unit, a versatile ALU, and a custom assembly language toolchain.

## Project Specifications

*   **Architecture:** RISC
*   **Word Size:** 16-bit
*   **Instruction Width:** 16-bit
*   **Register File:** 8 General Purpose Registers (16-bit)
*   **Addressing Modes:** Register-Direct, Immediate, Indirect (Memory)

## Registers

The processor contains 8 registers (`R0` through `R7`). While they are general-purpose, specific registers have designated hardware roles:

| Register | Name | Function |
| :---: | :---: | :--- |
| **R0 - R5** | GPR | General Purpose Registers for arithmetic and logic. |
| **R6** | SP | **Stack Pointer**: Used automatically by PUSH/POP instructions. |
| **R7** | RAF | **Return Address Function**: Stores return address during calls (CH). |

## Instruction Set Architecture (ISA)

The ISA is split into data movement, arithmetic/logic, branching, and system control. Most instructions use a prefix bit to distinguish between Register (`r`) and Immediate (`i`) modes.

## Instruction Encoding

The 16-bit instruction word is divided into the Opcode, Prefix, and Operands.

### Standard Format (Register/Immediate)
Used for arithmetic, logic, and data movement.
*   **Bits 15-10 (6 bits):** Opcode
*   **Bit 9 (1 bit):** Prefix (`0` = Register Mode, `1` = Immediate Mode)
*   **Bits 8-6 (3 bits):** Destination Register (`rd`)
*   **Bits 5-3 (3 bits):** Source Register 1 (`rs1`) or part of Immediate
*   **Bits 2-0 (3 bits):** Source Register 2 (`rs2`) or part of Immediate

| Opcode | Prefix | Dest Reg (rd) | Source 1 (rs) | Source 2 / Extra |
| :---: | :---: | :---: | :---: | :---: |
| Bits 15-10 | Bit 9 | Bits 8-6 | Bits 5-3 | Bits 2-0 |

### Conditional Jump Format
The address for conditional jumps is calculated using a signed 9-bit offset.
*   **Bits 15-10 (6 bits):** Opcode
*   **Bit 9 (1 bit):** Prefix (Typically `1` for immediate offsets in assembler)
*   **Bits 8-0 (9 bits):** Signed Address Offset / Immediate

| Opcode | Prefix | Address / Offset |
| :---: | :---: | :---: |
| Bits 15-10 | Bit 9 | Bits 8-0 |

## Instruction Set Architecture (ISA)

The table below lists all supported instructions. The **Prefix** determines if the last operand is a register (`r`) or an immediate value (`i`).


### Instruction Table

| Mnemonic | Description | Syntax (Example) | Opcode (Bin) |
| :--- | :--- | :--- | :--- |
| **Data Movement** | | | |
| `LDW` | Load Word from memory to register | `LDW rd` | `000000` |
| `STW` | Store Word from register to memory | `STW rs` | `000001` |
| `MOV` | Move value (Reg to Reg or Imm to Reg) | `MOV i R0 7` | `000010` |
| `MVN` | Move Not (Move inverted value) | `MVN r R1 R0` | `001110` |
| `PUSH` | Push register onto Stack (Dec R6, Store) | `PUSH r R1` | `101000` |
| `POP` | Pop from Stack to register (Load, Inc R6) | `POP r R1` | `101001` |
| **Arithmetic** | | | |
| `ADD` | Addition | `ADD r R1 R2` | `001010` |
| `SUB` | Subtraction | `SUB r R1 R2` | `001011` |
| `MUL` | Multiplication | `MUL r R1 R2` | `001100` |
| `DIV` | Division | `DIV r R1 R2` | `001101` |
| `MOD` | Modulo | `MOD r R1 R2` | `100111` |
| `CMP` | Compare (Updates Flags only) | `CMP r R1 R2` | `100110` |
| **Logic & Shift** | | | |
| `OR` | Bitwise OR | `OR r R1 R2` | `001111` |
| `AND` | Bitwise AND | `AND r R1 R2` | `010000` |
| `ORN` | Bitwise OR NOT | `ORN r R1 R2` | `010001` |
| `ANDN` | Bitwise AND NOT | `ANDN r R1 R2` | `010010` |
| `EOR` | Exclusive OR (XOR) | `EOR r R1 R2` | `010011` |
| `EON` | Exclusive OR NOT (XNOR) | `EON r R1 R2` | `010100` |
| `LSL` | Logical Shift Left | `LSL i R1 2` | `010101` |
| `LSR` | Logical Shift Right | `LSR i R1 2` | `010110` |
| `ASR` | Arithmetic Shift Right | `ASR i R1 2` | `010111` |
| `REV` | Reverse Bytes (Endian swap) | `REV r R1` | `011000` |
| **Control Flow** | | | |
| `J` | Unconditional Jump | `J i 7` | `011001` |
| `JZ` | Jump if Zero (ZF=1) | `JZ i 5` | `011010` |
| `JNZ` | Jump if Not Zero (ZF=0) | `JNZ i 5` | `011011` |
| `JC` | Jump if Carry | `JC i 5` | `011100` |
| `JNC` | Jump if No Carry | `JNC i 5` | `011101` |
| `JO` | Jump if Overflow | `JO i 5` | `011110` |
| `JNO` | Jump if No Overflow | `JNO i 5` | `011111` |
| `JP` | Jump if Parity (Even) | `JP i 5` | `100000` |
| `JNP` | Jump if No Parity (Odd) | `JNP i 5` | `100001` |
| `JG` | Jump if Greater | `JG i 5` | `100010` |
| `JL` | Jump if Less | `JL i 5` | `100011` |
| `CH` | Call Handler (Function Call) | `CH i 20` | `001000` |
| `RET` | Return from Function (Restores PC from RAF) | `RET` | `001001` |
| **System / IO** | | | |
| `HLT` | Halt Processor | `HLT` | `000011` |
| `RST` | Reset Processor | `RST` | `000100` |
| `INT` | Interrupt Request | `INT` | `000101` |
| `IN` | Input from I/O Port | `IN r R0` | `000110` |
| `OUT` | Output to I/O Port | `OUT i R0 4` | `000111` |

## Flags

The ALU updates the `flags` register (internal) after arithmetic/logic operations:
*   **ZF**: Zero Flag
*   **CF**: Carry Flag
*   **OF**: Overflow Flag
*   **GF**: Greater Flag
*   **LF**: Less Flag
*   **PF**: Parity Flag

## Usage

### 1. Assembler
The project includes a Python script (`decode.py`) to convert assembly code into machine code binary.

1.  Edit `RISC_input.txt` with your assembly code.
    ```asm
    MOV i R0 7
    MOV i R1 2
    ADD r R0 R1
    OUT i R0 4
    HLT
    ```
2.  Run the python script:
    ```bash
    python decode.py
    ```
3.  This generates `RISC_MC.txt`, which is loaded by the testbench during simulation.

### 2. Simulation (ModelSim/Questa)
The project is configured for ModelSim.

1.  Open ModelSim.
2.  Execute the TCL script:
    ```tcl
    do run_gpp16.txt
    ```
3.  This will:
    *   Create the work library.
    *   Compile all SystemVerilog files.
    *   Start the `GPP16_tb` simulation.
    *   Load instructions from `RISC_MC.txt`.
    *   Output the results of `OUT` instructions to the console.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
