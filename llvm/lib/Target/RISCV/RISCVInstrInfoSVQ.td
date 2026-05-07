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
}
