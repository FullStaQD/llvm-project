// Custom add instruction for SVQ extension. TODO: Move it to another file.
include "RISCVInstrFormatsSVQ.td"

let Predicates = [HasStdExtSVQ] in {


defvar QV_H_FUNCT7  = 0b0001000;
defvar QV_X_FUNCT7  = 0b0001001;
defvar QV_MZ_FUNCT7 = 0b1101000;
defvar QV_CX_FUNCT7 = 0b0001101;

def SVQ_H  : RVInstSQ<QV_H_FUNCT7,  "svq.h">;
def SVQ_X  : RVInstSQ<QV_X_FUNCT7,  "svq.x">;
def SVQ_MZ : RVInstSQ<QV_MZ_FUNCT7, "svq.mz">;
def SVQ_CX : RVInstPQ<QV_CX_FUNCT7, "svq.cx">;

// Pseudos for VSETVLI insertion and LMUL handling
multiclass VPseudoSVQ_Single {
  foreach m = MxList in {
    let VLMul = m.value in {
      def "_" # m.MX : RISCVVPseudo<(outs),
                       (ins m.vrclass:$vs1, GPR:$rs2, uimm5:$imm, AVL:$vl, sew:$sew)> {
        let mayLoad = 0;
        let mayStore = 0;
        let hasSideEffects = 1;
        let HasVLOp = 1;
        let HasSEWOp = 1;
      }
    }
  }
}

multiclass VPseudoSVQ_Double {
  foreach m = MxList in {
    let VLMul = m.value in {
      def "_" # m.MX : RISCVVPseudo<(outs),
                       (ins m.vrclass:$vs1, m.vrclass:$vs2, uimm5:$imm, AVL:$vl, sew:$sew)> {
        let mayLoad = 0;
        let mayStore = 0;
        let hasSideEffects = 1;
        let HasVLOp = 1;
        let HasSEWOp = 1;
      }
    }
  }
}

defm PseudoSVQ_H  : VPseudoSVQ_Single;
defm PseudoSVQ_X  : VPseudoSVQ_Single;
defm PseudoSVQ_MZ : VPseudoSVQ_Single;
defm PseudoSVQ_CX : VPseudoSVQ_Double;

// Patterns to match the intrinsics to the Pseudos
multiclass VPatSVQ_Single<string intrinsic, string inst> {
  foreach vti = SupportedSVQVTypes in {
    let Predicates = GetVTypeMinimalPredicates<vti>.Predicates in {
      def : Pat<(!cast<Intrinsic>(intrinsic) (vti.Vector vti.RegClass:$vs1),
                                             (XLenVT GPR:$rs2), 
                                             (XLenVT uimm5:$imm), (XLenVT GPR:$vl)),
                (!cast<Instruction>(inst#"_"#vti.LMul.MX) vti.RegClass:$vs1,
                                                          GPR:$rs2, uimm5:$imm,
                                                          GPR:$vl, vti.Log2SEW)>;
    }
  }
}

multiclass VPatSVQ_Double<string intrinsic, string inst> {
  foreach vti = SupportedSVQVTypes in {
    let Predicates = GetVTypeMinimalPredicates<vti>.Predicates in {
      def : Pat<(!cast<Intrinsic>(intrinsic) (vti.Vector vti.RegClass:$vs1),
                                             (vti.Vector vti.RegClass:$vs2),
                                             (XLenVT uimm5:$imm), (XLenVT GPR:$vl)),
                (!cast<Instruction>(inst#"_"#vti.LMul.MX) vti.RegClass:$vs1,
                                                          vti.RegClass:$vs2,
                                                          uimm5:$imm,
                                                          GPR:$vl, vti.Log2SEW)>;
    }
  }
}

defm : VPatSVQ_Single<"int_riscv_svq_h",  "PseudoSVQ_H">;
defm : VPatSVQ_Single<"int_riscv_svq_x",  "PseudoSVQ_X">;
defm : VPatSVQ_Single<"int_riscv_svq_mz", "PseudoSVQ_MZ">;
defm : VPatSVQ_Double<"int_riscv_svq_cx", "PseudoSVQ_CX">;
}
