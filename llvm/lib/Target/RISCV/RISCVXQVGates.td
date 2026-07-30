//===-- RISCVXQVGates.td - HiSEP-Q QV Gate Encoding Table -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Encoding table for the HiSEP-Q QV extension: the funct3 of each instruction
// class and the funct7 (GateID) of each gate. RISCVInstrFormatsXQV.td and
// RISCVInstrInfoXQV.td derive the formats, instructions, pseudos and selection
// patterns from these records.
//
//===----------------------------------------------------------------------===//

// Instruction class. funct3 selects the class within the custom-0 opcode.
class QVClass<string name, bits<3> funct3> {
  string Name    = name;
  bits<3> Funct3 = funct3;
}

// `suffix` names the records generated for this gate (QV_<suffix>,
// PseudoQV_<suffix>); everything else is derived from the mnemonic.
class QVGate<string suffix, string mnemonic, bits<7> gateID, QVClass instClass> {
  string Suffix          = suffix;
  string Mnemonic        = mnemonic;
  string IntrinsicRecord = "int_riscv_" # !subst(".", "_", mnemonic);
  bits<7> GateID         = gateID;
  string InstClass       = instClass.Name;
}

// Gate classes for the QV extension.
def QVSingle : QVClass<"Single", 0b000>;
def QVPair   : QVClass<"Pair",   0b001>;
def QVRotG   : QVClass<"RotG",   0b010>;
def QVRotV   : QVClass<"RotV",   0b011>;

// GateIDs match the HiSEP-Q hardware (H = 7'h64, CX = 7'h66, MEASURE = 7'h68).
// X has no fixed GateID in HiSEP-Q yet; its value here is a placeholder.
def Gate_H  : QVGate<"H",  "qv.h",  0b1100100, QVSingle>;
def Gate_X  : QVGate<"X",  "qv.x",  0b0000010, QVSingle>;
def Gate_MZ : QVGate<"MZ", "qv.mz", 0b1101000, QVSingle>;
def Gate_CX : QVGate<"CX", "qv.cx", 0b1100110, QVPair>;

// RISCVInstrInfoXQV.td iterates these to build the instructions, pseudos and
// selection patterns. A new gate must be listed here as well as defined above.
defvar QVSingleGates = [Gate_H, Gate_X, Gate_MZ];
defvar QVPairGates   = [Gate_CX];
