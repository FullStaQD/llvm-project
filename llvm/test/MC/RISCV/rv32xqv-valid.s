# RUN: llvm-mc -triple=riscv32 -mattr=+experimental-xqv --show-encoding %s \
# RUN:     | FileCheck %s --check-prefixes=CHECK-ENCODING,CHECK-INST
# RUN: not llvm-mc -triple=riscv32 --show-encoding %s 2>&1 \
# RUN:     | FileCheck %s --check-prefix=CHECK-ERROR

# TODO: Add disassembler round-trip (llvm-mc -filetype=obj | llvm-objdump -d)
# once QV_H_FUNCT7 and QV_CX_FUNCT7 are corrected to spec values (0x64 and
# 0x66); current values overlap with standard V instructions.

# +experimental-xqv implies +v, so no explicit +v needed in the RUN line.

# qv.h: single-qubit gate — qv.h vs1, rs2, block_imm
# gateid=0b0001000, funct3=0b000

# CHECK-INST:     qv.h v0, a0, 0
# CHECK-ENCODING: [0x57,0x00,0xa0,0x10]
# CHECK-ERROR:    instruction requires the following: 'XQV' (QV Quantum Extension){{$}}
qv.h v0, a0, 0

# CHECK-INST:     qv.h v8, a0, 12
# CHECK-ENCODING: [0x57,0x06,0xa4,0x10]
# CHECK-ERROR:    instruction requires the following: 'XQV' (QV Quantum Extension){{$}}
qv.h v8, a0, 12

# qv.mz: measure-in-Z gate — qv.mz vs1, rs2, block_imm
# gateid=0b1101000, funct3=0b000

# CHECK-INST:     qv.mz v0, a0, 0
# CHECK-ENCODING: [0x57,0x00,0xa0,0xd0]
# CHECK-ERROR:    instruction requires the following: 'XQV' (QV Quantum Extension){{$}}
qv.mz v0, a0, 0

# CHECK-INST:     qv.mz v8, a0, 12
# CHECK-ENCODING: [0x57,0x06,0xa4,0xd0]
# CHECK-ERROR:    instruction requires the following: 'XQV' (QV Quantum Extension){{$}}
qv.mz v8, a0, 12

# qv.cx: two-qubit CNOT — qv.cx vs1(tgt), vs2(ctrl), block_imm
# gateid=0b0001101, funct3=0b001

# CHECK-INST:     qv.cx v0, v8, 0
# CHECK-ENCODING: [0x57,0x10,0x80,0x1a]
# CHECK-ERROR:    instruction requires the following: 'XQV' (QV Quantum Extension){{$}}
qv.cx v0, v8, 0

# CHECK-INST:     qv.cx v8, v9, 12
# CHECK-ENCODING: [0x57,0x16,0x94,0x1a]
# CHECK-ERROR:    instruction requires the following: 'XQV' (QV Quantum Extension){{$}}
qv.cx v8, v9, 12
