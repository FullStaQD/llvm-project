// Custom add instruction for SVQ extension. TODO: Move it to another file.
include "RISCVInstrFormatsSVQ.td"

def SVQ_ADD_NODE : SDNode<
  "llvm::RISCVSVQ::SVQ_ADD",
  SDTypeProfile<
    1, 2,
    [
      SDTCisInt<0>,
      SDTCisSameAs<0, 1>,
      SDTCisSameAs<0, 2>
    ]
  >
>;

let Predicates = [HasStdExtSVQ] in {

def G_SVQ_H : Pseudo<
    (outs),
    (ins VR:$vs1, GPR:$rs2, uimm5:$imm),
    []
> {
  let hasSideEffects = 1;
  let isPseudo = 1;
  let mayLoad = 0;
  let mayStore = 0;
}

def SVQ_ADD : RVInstR<
    0b0001000,          // funct7
    0b111,              // funct3
    OPC_OP,             // opcode (standard R-type)
    (outs GPR:$rd),
    (ins GPR:$rs1, GPR:$rs2),
    "svq.add", 
    "$rd, $rs1, $rs2">;

def SVQ_MUL : RVInstR<
    0b0001000,          // funct7
    0b101,              // funct3
    OPC_OP,             // opcode (standard R-type)
    (outs GPR:$rd),
    (ins GPR:$rs1, GPR:$rs2),
    "svq.mul", 
    "$rd, $rs1, $rs2">;

def SVQ_H : RVInstSQ<
    0b0001000,                       // gateid
    (outs),                         
    (ins VR:$vs1, GPR:$rs2, uimm5:$block_imm),
    "svq.h",
    "$vs1, $rs2, $block_imm"> {
    let hasSideEffects = 1;
    let mayLoad = 0;
    let mayStore = 0;
}
def SVQ_X : RVInstSQ<
    0b0001001,                       // gateid
    (outs),                         
    (ins VR:$vs1, GPR:$rs2, uimm5:$block_imm),
    "svq.x",
    "$vs1, $rs2, $block_imm"> {
    let hasSideEffects = 1;
    let mayLoad = 0;
    let mayStore = 0;
}
  
def SVQ_MZ : RVInstSQ<
    0b1101000,                       // gateid
    (outs),                         
    (ins VR:$vs1, GPR:$rs2, uimm5:$block_imm),
    "svq.mz",
    "$vs1, $rs2, $block_imm"> {
    let hasSideEffects = 1;
    let mayLoad = 0;
    let mayStore = 0;
}

def SVQ_CX : RVInstPQ<
    0b0001001,                       // gateid
    (outs),                         
    (ins VR:$vs1, VR:$vs2, uimm5:$block_imm),
    "svq.cx",
    "$vs1, $vs2, $block_imm">{
    let hasSideEffects = 1;
    let mayLoad = 0;
    let mayStore = 0;
}


def : Pat<
  (SVQ_ADD_NODE i32:$rs1, i32:$rs2),
  (SVQ_ADD GPR:$rs1, GPR:$rs2)
>;
def : Pat<
  (int_riscv_svq_mul i32:$rs1, i32:$rs2),
  (SVQ_MUL GPR:$rs1, GPR:$rs2)
>;

// Pseudos for VSETVLI insertion and LMUL handling
multiclass VPseudoSVQ_Single<int mLoad, int mStore> {
  foreach m = MxList in {
    let VLMul = m.value in {
      def "_" # m.MX : RISCVVPseudo<(outs),
                       (ins m.vrclass:$vs1, GPR:$rs2, uimm5:$imm, AVL:$vl, sew:$sew)> {
        let mayLoad = mLoad;
        let mayStore = mStore;
        let hasSideEffects = 1;
        let HasVLOp = 1;
        let HasSEWOp = 1;
      }
    }
  }
}

multiclass VPseudoSVQ_Double<int mLoad, int mStore> {
  foreach m = MxList in {
    let VLMul = m.value in {
      def "_" # m.MX : RISCVVPseudo<(outs),
                       (ins m.vrclass:$vs1, m.vrclass:$vs2, uimm5:$imm, AVL:$vl, sew:$sew)> {
        let mayLoad = mLoad;
        let mayStore = mStore;
        let hasSideEffects = 1;
        let HasVLOp = 1;
        let HasSEWOp = 1;
      }
    }
  }
}

defm PseudoSVQ_H  : VPseudoSVQ_Single<0, 0>;
defm PseudoSVQ_X  : VPseudoSVQ_Single<0, 0>;
defm PseudoSVQ_MZ : VPseudoSVQ_Single<0, 0>;
defm PseudoSVQ_CX : VPseudoSVQ_Double<0, 0>;

// Patterns to match the intrinsics to the Pseudos
multiclass VPatSVQ_Single<string intrinsic, string inst> {
  foreach vti = AllVectors in {
    let Predicates = GetVTypeMinimalPredicates<vti>.Predicates in {
      def : Pat<(!cast<Intrinsic>(intrinsic) (vti.Vector vti.RegClass:$vs1),
                                             (XLenVT GPR:$rs2), (XLenVT uimm5:$imm), (XLenVT GPR:$vl)),
                (!cast<Instruction>(inst#"_"#vti.LMul.MX) vti.RegClass:$vs1,
                                                          GPR:$rs2, uimm5:$imm,
                                                          GPR:$vl, vti.Log2SEW)>;
    }
  }
}

multiclass VPatSVQ_Double<string intrinsic, string inst> {
  foreach vti = AllVectors in {
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
