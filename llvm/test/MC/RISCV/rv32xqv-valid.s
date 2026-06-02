# RUN: llvm-mc -triple=riscv32 -mattr=+experimental-xqv --show-encoding %s \
# RUN:     | FileCheck %s --check-prefixes=CHECK-ENCODING,CHECK-INST

# TODO: Add disassembler round-trip (llvm-mc -filetype=obj | llvm-objdump -d)
# once QV_H_FUNCT7 and QV_CX_FUNCT7 are corrected to spec values (0x64 and
# 0x66); current values overlap with standard V instructions.

# qv.h: single-qubit gate — qv.h vs1, rs2, block_imm
# gateid=0b0001000, funct3=0b000

# CHECK-INST:     qv.h v8, a0, 12
# CHECK-ENCODING: [0x57,0x06,0xa4,0x10]
qv.h v8, a0, 12

# qv.mz: measure-in-Z gate — qv.mz vs1, rs2, block_imm
# gateid=0b1101000, funct3=0b000

# CHECK-INST:     qv.mz v8, a0, 12
# CHECK-ENCODING: [0x57,0x06,0xa4,0xd0]
qv.mz v8, a0, 12

# qv.cx: two-qubit CNOT — qv.cx vs1(tgt), vs2(ctrl), block_imm
# gateid=0b0001101, funct3=0b001

# CHECK-INST:     qv.cx v8, v9, 12
# CHECK-ENCODING: [0x57,0x16,0x94,0x1a]
qv.cx v8, v9, 12
