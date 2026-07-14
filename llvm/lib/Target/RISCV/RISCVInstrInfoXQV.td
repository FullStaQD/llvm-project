//===-- RISCVInstrInfoXQV.td - RISC-V QV Instruction Info -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
//
//===----------------------------------------------------------------------===//
//
//  This file describes the RISC-V QV extension instructions.
//
//===----------------------------------------------------------------------===//

// RISCVInstrFormatsXQV.td takes funct3 from the class records, so the gate table comes first.
include "RISCVXQVGates.td"
include "RISCVInstrFormatsXQV.td"

let Predicates = [HasVendorXQV] in {

foreach g = QVSingleGates in
  def "QV_" # g.Suffix : RVInstQVSingle<g.GateID, g.Mnemonic>;

foreach g = QVPairGates in
  def "QV_" # g.Suffix : RVInstQVPair<g.GateID, g.Mnemonic>;

// Pseudos for VSETVLI insertion and LMUL handling
multiclass RVPseudoQVSingle {
  foreach m = MxList in {
    let VLMul = m.value in {
      def "_" # m.MX : RISCVVPseudo<(outs),
                       (ins m.vrclass:$vs1, GPR:$rs2, uimm5:$block_imm, AVL:$vl, sew:$sew)> {
        let mayLoad = 0;
        let mayStore = 0;
        let hasSideEffects = 1;
        let HasVLOp = 1;
        let HasSEWOp = 1;
      }
    }
  }
}

multiclass RVPseudoQVPair {
  foreach m = MxList in {
    let VLMul = m.value in {
      def "_" # m.MX : RISCVVPseudo<(outs),
                       (ins m.vrclass:$vs1, m.vrclass:$vs2, uimm5:$block_imm, AVL:$vl, sew:$sew)> {
        let mayLoad = 0;
        let mayStore = 0;
        let hasSideEffects = 1;
        let HasVLOp = 1;
        let HasSEWOp = 1;
      }
    }
  }
}

foreach g = QVSingleGates in
  defm "PseudoQV_" # g.Suffix : RVPseudoQVSingle;

foreach g = QVPairGates in
  defm "PseudoQV_" # g.Suffix : RVPseudoQVPair;

// Patterns to match the intrinsics to the Pseudos
multiclass RVPatQVSingle<string intrinsic, string inst> {
  foreach vti = SupportedQVVTypes in {
    let Predicates = GetVTypeMinimalPredicates<vti>.Predicates in {
      def : Pat<(!cast<Intrinsic>(intrinsic) (vti.Vector vti.RegClass:$vs1),
                                             (XLenVT GPR:$rs2), 
                                             (XLenVT uimm5:$block_imm), (XLenVT GPR:$vl)),
                (!cast<Instruction>(inst#"_"#vti.LMul.MX) vti.RegClass:$vs1,
                                                          GPR:$rs2, uimm5:$block_imm,
                                                          GPR:$vl, vti.Log2SEW)>;
    }
  }
}

multiclass RVPatQVPair<string intrinsic, string inst> {
  foreach vti = SupportedQVVTypes in {
    def : Pat<(!cast<Intrinsic>(intrinsic) (vti.Vector vti.RegClass:$vs1),
                                           (vti.Vector vti.RegClass:$vs2),
                                           (XLenVT uimm5:$block_imm), (XLenVT GPR:$vl)),
              (!cast<Instruction>(inst#"_"#vti.LMul.MX) vti.RegClass:$vs1,
                                                        vti.RegClass:$vs2,
                                                        uimm5:$block_imm,
                                                        GPR:$vl, vti.Log2SEW)>;
  }
}

foreach g = QVSingleGates in
  defm : RVPatQVSingle<g.IntrinsicRecord, "PseudoQV_" # g.Suffix>;

foreach g = QVPairGates in
  defm : RVPatQVPair<g.IntrinsicRecord, "PseudoQV_" # g.Suffix>;
}
