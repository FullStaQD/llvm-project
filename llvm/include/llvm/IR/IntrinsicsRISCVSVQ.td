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

let TargetPrefix = "riscv" in {
// Custom add instruction. It will translate to: @llvm.riscv.svq.add()
    def int_riscv_svq_add :     
        Intrinsic<[llvm_i32_ty], 
                  [llvm_i32_ty, llvm_i32_ty],
                  [IntrNoMem]>;
}