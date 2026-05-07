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
    
    def int_riscv_svq_mul : 
        Intrinsic<[llvm_i32_ty],
                  [llvm_i32_ty, llvm_i32_ty],
                  [IntrNoMem]>;
    def int_riscv_svq_h :
            Intrinsic<[],
            [llvm_anyvector_ty, llvm_i32_ty, llvm_i32_ty],
            []>;
    def int_riscv_svq_x : 
        Intrinsic<[llvm_void_ty],
                  [llvm_anyvector_ty, llvm_i32_ty, llvm_i32_ty],
                  [IntrHasSideEffects, ImmArg<ArgIndex<2>>]>;
    def int_riscv_svq_mz : 
        Intrinsic<[llvm_void_ty],
                  [llvm_anyvector_ty, llvm_i32_ty, llvm_i32_ty],
                  [IntrHasSideEffects, ImmArg<ArgIndex<2>>]>;
    def int_riscv_svq_cx : 
        Intrinsic<[llvm_void_ty],
                  [llvm_anyvector_ty, llvm_anyvector_ty, llvm_i32_ty],
                  [IntrHasSideEffects, ImmArg<ArgIndex<2>>]>;
}