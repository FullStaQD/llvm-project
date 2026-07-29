//===-- RISCVInstrFormatsXQV.td - RISC-V QV Instruction Formats -*- tablegen -*-=//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
//  This file describes the RISC-V QV extension instruction formats.
//
//===----------------------------------------------------------------------===//

// Custom list of supported VTypeInfo records for QV instructions.
defvar SupportedQVVTypes = [VI8MF4, VI8MF2, VI8M1, VI8M2, VI8M4, VI8M8];

// QV.SINGLE — Single-Qubit Gate
// Applies a single-qubit gate to the qubits listed in vs1. The 32-bit
// scalar payload from rs2 is forwarded to the quantum backend on the
// elem2 channel (e.g., as a software tag or timestamp).
// 31       25   24    20   19    15   14  12   11     7   6     0
// +---------+----------+----------+--------+----------+---------+
// |  GateID |   rs2    |  vs1 (S) | 000(S) | Block_imm| 0001011 |
// +---------+----------+----------+--------+----------+---------+

class RVInstQVSingle<bits<7> gateid, string opcodestr>
    : RVInst<(outs), 
             (ins VR:$vs1, GPR:$rs2, uimm5:$block_imm), 
             opcodestr, 
             "$vs1, $rs2, $block_imm", 
             [], 
             InstFormatR> {
  bits<5> vs1;
  bits<5> rs2;
  bits<5> block_imm;

  let Inst{31-25} = gateid;
  let Inst{24-20} = rs2;
  let Inst{19-15} = vs1;
  let Inst{14-12} = QVSingle.Funct3;
  let Inst{11-7}  = block_imm;
  let Inst{6-0}   = OPC_CUSTOM_0.Value;

  let hasSideEffects = 1;
  let mayLoad = 0;
  let mayStore = 0;

  let Uses = [VL, VTYPE];
}

// QV.PAIR — Two-Qubit Gate
// Applies a two-qubit gate to element-wise pairs from vs2 (source/control)
// and vs1 (target).
// 31       25   24    20   19    15   14  12   11     7   6     0
// +---------+----------+----------+--------+----------+---------+
// |  GateID | vs2(src) | vs1(tgt) | 001(P) | Block_imm| 0001011 |
// +---------+----------+----------+--------+----------+---------+

class RVInstQVPair<bits<7> gateid, string opcodestr>
    : RVInst<(outs), 
             (ins VR:$vs1, VR:$vs2, uimm5:$block_imm), 
             opcodestr, 
             "$vs1, $vs2, $block_imm", 
             [], 
             InstFormatR> {
  bits<5> vs1;
  bits<5> vs2;
  bits<5> block_imm;


  let Inst{31-25} = gateid;
  let Inst{24-20} = vs2;
  let Inst{19-15} = vs1;
  let Inst{14-12} = QVPair.Funct3;
  let Inst{11-7}  = block_imm;
  let Inst{6-0}   = OPC_CUSTOM_0.Value;

  let hasSideEffects = 1;
  let mayLoad = 0;
  let mayStore = 0;

  let Uses = [VL, VTYPE];
}
