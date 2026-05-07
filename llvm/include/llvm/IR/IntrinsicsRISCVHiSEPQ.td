let TargetPrefix = "riscv" in {
  // Generic intrinsic for my_vadd.vx
  def int_riscv_my_vadd : Intrinsic<[llvm_anyvector_ty], // Output
                         [LLVMMatchType<0>,             // Passthru (must match output type)
                          LLVMMatchType<0>,             // vs2 (Vector operand)
                          llvm_anyint_ty,               // rs1 (Scalar operand)
                          llvm_anyint_ty],              // vl
                         [IntrNoMem]>;                  // Pure math, no memory side effects

  // QV.SINGLE vs1, rs2, Block_imm
  class QVSingleIntrinsic : Intrinsic<[], // void return type
                         [llvm_anyvector_ty, // vs1 (tgt)
                          llvm_anyint_ty,    // rs2 (tag)
                          llvm_anyint_ty,    // Block_imm (wait time)
                          llvm_anyint_ty],   // vl
                         [IntrHasSideEffects, IntrNoMem]>;

  def int_riscv_qv_h : QVSingleIntrinsic;
  def int_riscv_qv_x : QVSingleIntrinsic;
}