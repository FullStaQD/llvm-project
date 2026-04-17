// Custom add instruction for SVQ extension. TODO: Move it to another file.

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

def SVQ_ADD : RVInstR<
    0b0001000,          // funct7
    0b111,              // funct3
    OPC_OP,             // opcode (standard R-type)
    (outs GPR:$rd),
    (ins GPR:$rs1, GPR:$rs2),
    "svq.add", 
    "$rd, $rs1, $rs2"> {
      let Predicates = [HasStdExtSVQ];
}

def : Pat<
  (SVQ_ADD_NODE i32:$rs1, i32:$rs2),
  (SVQ_ADD GPR:$rs1, GPR:$rs2)
> {
  let Predicates = [HasStdExtSVQ];
}