//===-- RISCVInstrFormatsQV.td - RISC-V QV Instruction Formats -*- tablegen -*-=//
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

defvar QV_SINGLE_FUNCT3 = 0b000;
defvar QV_PAIR_FUNCT3   = 0b001;
defvar QV_GR_FUNCT3     = 0b010;
defvar QV_VR_FUNCT3     = 0b011;

// Custom list of supported VTypeInfo records for QV instructions.
defvar SupportedQVVTypes = [VI8M1, VI8M2, VI8M4, VI8M8];

// QV.SINGLE — Single-Qubit Gate
// Applies a single-qubit gate to the qubits listed in vs1. The 32-bit 
// scalar payload from rs2 is forwarded to the quantum backend on the 
// elem2 channel (e.g., as a software tag or timestamp).
// 31       25   24    20   19    15   14  12   11     7   6     0
// +---------+----------+----------+--------+----------+---------+
// |  GateID |   rs2    |  vs1 (S) | 000(S) | Block_imm| 1010111 |
// +---------+----------+----------+--------+----------+---------+

class RVInstSQ<bits<7> gateid, string opcodestr>
    : RVInst<(outs), 
             (ins VR:$vs1, GPR:$rs2, uimm5:$block_imm), 
             opcodestr, 
             "$vs1, $rs2, $block_imm", 
             [], 
             InstFormatR> {
  bits<5> vs1;
  bits<5> rs2;
  bits<5> block_imm;

  let Inst{6-0}   = OPC_OP_V.Value; // def OPC_OP_V : RISCVOpcode<"OP_V", 0b1010111>;
  let Inst{11-7}  = block_imm;
  let Inst{14-12} = QV_SINGLE_FUNCT3; // 0b000 for single-qubit gates
  let Inst{19-15} = vs1;
  let Inst{24-20} = rs2;
  let Inst{31-25} = gateid;

  let hasSideEffects = 1;
  let mayLoad = 0;
  let mayStore = 0;

  let Uses = [VL, VTYPE];
  let RVVConstraint = VMConstraint;
}

// QV.PAIR — Two-Qubit Gate
// Applies a two-qubit gate to element-wise pairs from vs2 (source/control) 
// and vs1 (target).
// 31       25   24    20   19    15   14  12   11     7   6     0
// +---------+----------+----------+--------+----------+---------+
// |  GateID | vs2(src) | vs1(tgt) | 001(P) | Block_imm| 1010111 |
// +---------+----------+----------+--------+----------+---------+

class RVInstPQ<bits<7> gateid, string opcodestr>
    : RVInst<(outs), 
             (ins VR:$vs1, VR:$vs2, uimm5:$block_imm), 
             opcodestr, 
             "$vs1, $vs2, $block_imm", 
             [], 
             InstFormatR> {
  bits<5> vs1;
  bits<5> vs2;
  bits<5> block_imm;

  let Inst{6-0}   = OPC_OP_V.Value; // def OPC_OP_V : RISCVOpcode<"OP_V", 0b1010111>;
  let Inst{11-7}  = block_imm;
  let Inst{14-12} = QV_PAIR_FUNCT3; // 0b001 for two-qubit gates
  let Inst{19-15} = vs1;
  let Inst{24-20} = vs2;
  let Inst{31-25} = gateid;

  let hasSideEffects = 1;
  let mayLoad = 0;
  let mayStore = 0;

  let Uses = [VL, VTYPE];
  let RVVConstraint = VMConstraint;
}

// QV.ROT.G — Global Rotation (Scalar Angle)
// Applies the same rotation angle to all target qubits listed in vs1.
// The angle is read from an integer scalar register rs2.
// 31      25   24    20   19    15   14  12   11      7   6     0
// +---------+----------+----------+--------+----------+---------+
// |   Res   | rs2(ang) | vs1(tgt) | 010(gr)| Block_imm| 1010111 |
// +---------+----------+----------+--------+----------+---------+
class RVInstGRQ<bits<7> res, dag outs, dag ins, string opcodestr,
                string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> vs1;
  bits<5> rs2;
  bits<5> block_imm;

  let Inst{6-0}   = OPC_OP_V.Value; // def OPC_OP_V : RISCVOpcode<"OP_V", 0b1010111>;
  let Inst{11-7}  = block_imm;
  let Inst{14-12} = QV_GR_FUNCT3; // 0b010 for global rotation gates
  let Inst{19-15} = vs1;
  let Inst{24-20} = rs2;
  let Inst{31-25} = res;

  let hasSideEffects = 1;
  let mayLoad = 0;
  let mayStore = 0;

  let Uses = [VL, VTYPE];
  let RVVConstraint = VMConstraint;
}

// QV.ROT.V — Variable Rotation (Per-Element Angle)
// Applies a per-qubit rotation angle to each target in vs1, with angles 
// sourced from vs2. This is a mixed-width instruction: vs1 uses SEW=8 
// (qubit indices) and vs2 uses SEW=32 (rotation angles).
// 31       25   24    20   19    15   14  12   11     7   6     0
// +---------+----------+----------+--------+----------+---------+
// |   Res   | vs2(ang) | vs1(tgt) | 011(vr)| Block_imm| 1010111 |
// +---------+----------+----------+--------+----------+---------+

class RVInstVRQ<bits<7> res, dag outs, dag ins, string opcodestr,
                string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> vs1;
  bits<5> vs2;
  bits<5> block_imm;

  let Inst{6-0}   = OPC_OP_V.Value; // def OPC_OP_V : RISCVOpcode<"OP_V", 0b1010111>;
  let Inst{11-7}  = block_imm;
  let Inst{14-12} = QV_VR_FUNCT3; // 0b011 for variable rotation gates
  let Inst{19-15} = vs1;
  let Inst{24-20} = vs2;
  let Inst{31-25} = res;
  
  let hasSideEffects = 1;
  let mayLoad = 0;
  let mayStore = 0;

  let Uses = [VL, VTYPE];
  let RVVConstraint = VMConstraint;
}
