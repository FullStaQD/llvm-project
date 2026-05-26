include "RISCVInstrFormatsXQV.td"

let Predicates = [HasVendorXQV] in {


defvar QV_H_FUNCT7  = 0b0001000;
defvar QV_X_FUNCT7  = 0b0001001;
defvar QV_MZ_FUNCT7 = 0b1101000;
defvar QV_CX_FUNCT7 = 0b0001101;

def QV_H  : RVInstSQ<QV_H_FUNCT7,  "qv.h">;
def QV_X  : RVInstSQ<QV_X_FUNCT7,  "qv.x">;
def QV_MZ : RVInstSQ<QV_MZ_FUNCT7, "qv.mz">;
def QV_CX : RVInstPQ<QV_CX_FUNCT7, "qv.cx">;

// Pseudos for VSETVLI insertion and LMUL handling
multiclass VPseudoQV_Single {
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

multiclass VPseudoQV_Pair {
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

defm PseudoQV_H  : VPseudoQV_Single;
defm PseudoQV_X  : VPseudoQV_Single;
defm PseudoQV_MZ : VPseudoQV_Single;
defm PseudoQV_CX : VPseudoQV_Pair;

// Patterns to match the intrinsics to the Pseudos
multiclass VPatQV_Single<string intrinsic, string inst> {
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

multiclass VPatQV_Pair<string intrinsic, string inst> {
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

defm : VPatQV_Single<"int_riscv_qv_h",  "PseudoQV_H">;
defm : VPatQV_Single<"int_riscv_qv_x",  "PseudoQV_X">;
defm : VPatQV_Single<"int_riscv_qv_mz", "PseudoQV_MZ">;
defm : VPatQV_Pair<"int_riscv_qv_cx", "PseudoQV_CX">;
}
