# RUN: not llvm-mc -triple riscv32 -mattr=+experimental-xqv < %s 2>&1 \
# RUN:     | FileCheck -check-prefixes=CHECK,CHECK-PLUS %s
# RUN: not llvm-mc -triple riscv32 -mattr=-experimental-xqv < %s 2>&1 \
# RUN:     | FileCheck -check-prefixes=CHECK,CHECK-MINUS %s

# XQV - QV Quantum Extension (HiSEP-Q 2.0)

# CHECK-MINUS: :[[@LINE+1]]:1: error: instruction requires the following: 'XQV' (QV Quantum Extension)
qv.h v8, a0, 12

# CHECK-MINUS: :[[@LINE+1]]:1: error: instruction requires the following: 'XQV' (QV Quantum Extension)
qv.x v8, a0, 12

# CHECK-MINUS: :[[@LINE+1]]:1: error: instruction requires the following: 'XQV' (QV Quantum Extension)
qv.mz v8, a0, 12

# CHECK-MINUS: :[[@LINE+1]]:1: error: instruction requires the following: 'XQV' (QV Quantum Extension)
qv.cx v8, v9, 12

# CHECK-MINUS: :[[@LINE+1]]:10: error: system register 'qv.mres' requires 'experimental-xqv' to be enabled
csrr a0, qv.mres

# CHECK-PLUS: :[[@LINE+2]]:14: error: immediate must be an integer in the range [0, 31]
# CHECK-MINUS: :[[@LINE+1]]:1: error: invalid instruction
qv.h v8, a0, 32

# CHECK-PLUS: :[[@LINE+2]]:15: error: immediate must be an integer in the range [0, 31]
# CHECK-MINUS: :[[@LINE+1]]:1: error: invalid instruction
qv.cx v8, v9, -1

# CHECK-PLUS: :[[@LINE+2]]:6: error: invalid operand for instruction
# CHECK-MINUS: :[[@LINE+1]]:1: error: invalid instruction
qv.h a1, a0, 12

# CHECK-PLUS: :[[@LINE+2]]:10: error: invalid operand for instruction
# CHECK-MINUS: :[[@LINE+1]]:1: error: invalid instruction
qv.h v8, v9, 12

# CHECK-PLUS: :[[@LINE+2]]:11: error: invalid operand for instruction
# CHECK-MINUS: :[[@LINE+1]]:1: error: invalid instruction
qv.cx v8, a0, 12

# CHECK: :[[@LINE+1]]:{{12: error: too few operands for instruction|1: error: invalid instruction}}
qv.h v8, a0
