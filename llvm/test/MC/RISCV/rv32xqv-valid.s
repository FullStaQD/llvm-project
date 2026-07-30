# RUN: llvm-mc -triple=riscv32 -mattr=+experimental-xqv --show-encoding %s \
# RUN:     | FileCheck %s --check-prefixes=CHECK-ENCODING,CHECK-INST

# TODO: Add disassembler round-trip (llvm-mc -filetype=obj | llvm-objdump -d).
# H, CX and MZ GateIDs match the HiSEP-Q hardware; X has no fixed GateID
# there yet and is a placeholder. See RISCVXQVGates.td.

# qv.h: single-qubit gate — qv.h vs1, rs2, block_imm
# gateid=0b1100100, funct3=0b000

# CHECK-INST:     qv.h v8, a0, 12
# CHECK-ENCODING: [0x0b,0x06,0xa4,0xc8]
qv.h v8, a0, 12

# qv.x: single-qubit gate — qv.x vs1, rs2, block_imm
# gateid=0b0000010, funct3=0b000

# CHECK-INST:     qv.x v8, a0, 12
# CHECK-ENCODING: [0x0b,0x06,0xa4,0x04]
qv.x v8, a0, 12

# qv.mz: measure-in-Z gate — qv.mz vs1, rs2, block_imm
# gateid=0b1101000, funct3=0b000

# CHECK-INST:     qv.mz v8, a0, 12
# CHECK-ENCODING: [0x0b,0x06,0xa4,0xd0]
qv.mz v8, a0, 12

# qv.cx: two-qubit CNOT — qv.cx vs1(tgt), vs2(ctrl), block_imm
# gateid=0b1100110, funct3=0b001

# CHECK-INST:     qv.cx v8, v9, 12
# CHECK-ENCODING: [0x0b,0x16,0x94,0xcc]
qv.cx v8, v9, 12
