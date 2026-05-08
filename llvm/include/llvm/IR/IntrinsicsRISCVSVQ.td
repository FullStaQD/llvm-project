//===- IntrinsicsRISCVSVQ.td - Defines RISCVSVQ intrinsics -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines all of the RISCV-specific intrinsics.
//
//===----------------------------------------------------------------------===//


//===----------------------------------------------------------------------===//
// SVQ

// Standard Vector Quantum extension of RISCV

    // QV.SINGLE vs1, rs2, Block_imm
    class QVSingleIntrinsic : Intrinsic<[], // void return type
                         [llvm_anyvector_ty, // vs1 (tgt)
                          llvm_anyint_ty,    // rs2 (tag)
                          llvm_anyint_ty,    // Block_imm (wait time)
                          llvm_anyint_ty],   // vl
                         [IntrHasSideEffects, IntrNoMem]>;
    
    // QV.Pair vs1, vs2, Block_imm
    class QVPairIntrinsic : Intrinsic<[],
                         [llvm_anyvector_ty, // vs1 (tgt)
                          llvm_anyvector_ty, // vs2 (src)
                          llvm_anyint_ty,    // Block_imm (wait time)
                          llvm_anyint_ty],   // vl
                         [IntrHasSideEffects, IntrNoMem]>;


let TargetPrefix = "riscv" in {
    def int_riscv_svq_h : QVSingleIntrinsic;
    def int_riscv_svq_x : QVSingleIntrinsic;
    def int_riscv_svq_mz : QVSingleIntrinsic;
    def int_riscv_svq_cx : QVPairIntrinsic;
}