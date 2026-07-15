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

def QVSingle : QVClass<"Single", 0b000>;
def QVPair   : QVClass<"Pair",   0b001>;
def QVRotG   : QVClass<"RotG",   0b010>;
def QVRotV   : QVClass<"RotV",   0b011>;

// `suffix` names the records generated for this gate (QV_<suffix>,
// PseudoQV_<suffix>); everything else is derived from the mnemonic.
class QVGate<string suffix, string mnemonic, bits<7> gateID, QVClass instClass> {
  string Suffix          = suffix;
  string Mnemonic        = mnemonic;
  string IntrinsicRecord = "int_riscv_" # !subst(".", "_", mnemonic);
  bits<7> GateID         = gateID;
  string InstClass       = instClass.Name;
}

// The GateIDs follow the allocation rules at the end of this file. 0x68 is
// fixed by the hardware.
def Gate_H  : QVGate<"H",  "qv.h",  0b0001000, QVSingle>;
def Gate_X  : QVGate<"X",  "qv.x",  0b0001001, QVSingle>;
def Gate_MZ : QVGate<"MZ", "qv.mz", 0b1101000, QVSingle>;
def Gate_CX : QVGate<"CX", "qv.cx", 0b0100000, QVPair>;

// RISCVInstrInfoXQV.td iterates these to build the instructions, pseudos and
// selection patterns. TableGen cannot enumerate the records of a class, so a new
// gate must be listed here as well as defined above.
defvar QVSingleGates = [Gate_H, Gate_X, Gate_MZ];
defvar QVPairGates   = [Gate_CX];

defvar QVAllGates = !listconcat(QVSingleGates, QVPairGates);

//===----------------------------------------------------------------------===//
// GateID allocation rules, checked by the assertions below.
//
// The 7-bit space is eight bands of 16, indexed by bits [6:4]. Each family and
// the system ops get one band; the rest stay free for gates added later:
//
//   0x01-0x0F  single-qubit Clifford / Pauli   (H, X, Y, Z, S, S+)
//   0x10-0x1F  single-qubit rotation           (RX, RY, RZ, T, T+)
//   0x20-0x2F  two-qubit                       (CX, CZ, SWAP)
//   0x30-0x5F  free
//   0x60-0x6F  measurement and system          (MEASURE, resume, ...)
//   0x70-0x7F  free
//
// 0x00 is not allocatable: non-Single classes emit it, so a 0x00 Single gate is
// ambiguous downstream.
//
// A new gate takes the next free value in its band.
//===----------------------------------------------------------------------===//

foreach g = QVAllGates in {
  assert !ne(!cast<int>(g.GateID), 0),
         "QV GateID 0x00 is reserved (non-Single classes emit it): " # g.Mnemonic;

  assert !eq(!size(!filter(h, QVAllGates,
                           !eq(!cast<int>(h.GateID), !cast<int>(g.GateID)))), 1),
         "QV GateID collision on " # g.Mnemonic #
         " -- GateIDs must be unique across all classes, not just within one";
}

foreach g = QVSingleGates in {
  assert !eq(g.InstClass, "Single"),
         g.Mnemonic # " is listed in QVSingleGates but declared " # g.InstClass;
}

foreach g = QVPairGates in {
  assert !eq(g.InstClass, "Pair"),
         g.Mnemonic # " is listed in QVPairGates but declared " # g.InstClass;

  assert !and(!ge(!cast<int>(g.GateID), 0x20), !le(!cast<int>(g.GateID), 0x2F)),
         "two-qubit gate " # g.Mnemonic # " must take a GateID in 0x20-0x2F";
}

// The vector core compares funct7 against 7'h68 to raise the measure
// pause/resume handshake.
assert !eq(!cast<int>(Gate_MZ.GateID), 0x68),
       "QV MEASURE must keep GateID 0x68: the hardware matches on it";
