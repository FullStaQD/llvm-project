//===----------------------------------------------------------------------===//
//
// my_vadd.vx (just as a simple demo)
//
//===----------------------------------------------------------------------===//

defvar MY_VADD_FUNCT6 = 0b111111;

def MY_VADD_VX : VALUVX<MY_VADD_FUNCT6, OPIVX, "my_vadd.vx">, 
                 SchedBinaryMC<"WriteVIALUX", "ReadVIALUV", "ReadVIALUX">;

// We define a pseudo specifically for the M1 LMUL and E8 SEW for your experiment
let BaseInstr = MY_VADD_VX in
defm PseudoMYVADD_E8 : VPseudoBinaryV_VX<V_M1, "">;

def : Pat<(nxv8i8 (int_riscv_my_vadd 
                   (nxv8i8 VR:$passthru), 
                   (nxv8i8 VR:$rs1), 
                   (XLenVT GPR:$rs2),  // Use XLenVT to bind the scalar
                   VLOpFrag)),         // Just VLOpFrag; it provides $vl internally
          (PseudoMYVADD_E8_VX_M1 
                   VR:$passthru, 
                   VR:$rs1, 
                   GPR:$rs2, 
                   GPR:$vl,            // This $vl comes from the VLOpFrag above
                   3, 
                   0)>;

//===----------------------------------------------------------------------===//
//
// QV.SINGLE
//
//===----------------------------------------------------------------------===//

defvar QV_H_FUNCT6 = 0b111110;
def OPIQVSingle : RISCVVFormat<0b000>;

class RVInstQVSingle<bits<6> funct6, RISCVVFormat opv, dag outs, dag ins,
                string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  let hasSideEffects = 1; // Prevents the optimizer from deleting "void" instructions
  let mayLoad = 0;        // This instruction doesn't read from system memory
  let mayStore = 0;       // This instruction doesn't write to system memory

  // Variables
  bits<5> rs2;
  bits<5> vs1;
  bits<5> block_imm;
  bit vm;

  // Assignments
  let Inst{31-26} = funct6;
  let Inst{25} = vm;
  let Inst{24-20} = rs2;
  let Inst{19-15} = vs1;
  let Inst{14-12} = opv.Value;
  let Inst{11-7} = block_imm;
  let Inst{6-0} = OPC_OP_V.Value; // def OPC_OP_V : RISCVOpcode<"OP_V", 0b1010111>;

  let Uses = [VL, VTYPE];
  let RVVConstraint = VMConstraint;
}

class QVSingle<bits<6> funct6, RISCVVFormat opv, string opcodestr>
    : RVInstQVSingle<
        funct6, 
        opv, 
        (outs),
        (ins VR:$vs1, GPR:$rs2, uimm5:$block_imm, VMaskOp:$vm),
        opcodestr, 
        // "$vs1, $rs2$vm, $block_imm" // *with* mask
        "$vs1, $rs2, $block_imm">;

def QV_H : QVSingle<QV_H_FUNCT6, OPIQVSingle, "qv.h">, 
           SchedBinaryMC<"WriteVIALUX", "ReadVIALUV", "ReadVIALUX">;

// FIXME: do not hardcode BaseInstr?
class VPseudoQVSingleNoMask<VReg vs1_rc, DAGOperand rs2_rc, LMULInfo m> :
  RISCVVPseudo<(outs), 
               (ins vs1_rc:$vs1, rs2_rc:$rs2, uimm5:$block, uimm5:$vm, GPR:$vl, uimm5:$sew, uimm5:$policy)> {
  let VLMul = m.value;
  let HasVLOp = 1;
  let HasSEWOp = 1;
  let HasVecPolicyOp = 1;
  let BaseInstr = QV_H;

  let hasSideEffects = 1; 
  let mayLoad = 0;
  let mayStore = 0;
}

// We use V_M1 to automatically get the 'VR' register class
def Pseudo_QV_H_M1 : VPseudoQVSingleNoMask<VR, GPR, V_M1>;

def : Pat<(int_riscv_qv_h (nxv8i8 VR:$vs1), (XLenVT GPR:$rs2), (XLenVT imm:$block), VLOpFrag),
          (Pseudo_QV_H_M1 
                   VR:$vs1, 
                   GPR:$rs2, 
                   imm:$block,
                   1,      // $vm (unmasked)
                   GPR:$vl, 
                   3,      // SEW
                   0       // policy
          )>;
