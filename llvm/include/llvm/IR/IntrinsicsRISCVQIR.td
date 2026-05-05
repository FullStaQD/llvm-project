//===- IntrinsicsRISCVQIR.td - Defines RISCVQIR intrinsics -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines all of the RISCV-specific intrinsics used to lower QIR 
// to RISCV dialect.
//
//===----------------------------------------------------------------------===//


//===----------------------------------------------------------------------===//
// Quantum Intermediate Representation (QIR) intrinsics for RISCV

let TargetPrefix = "riscv" in {
// Custom QIR gate instruction instruction. It will translate to: @llvm.riscv.qir.h()

    def int_riscv_qir_initialize :
        Intrinsic<[],
                  [llvm_ptr_ty],
                  [IntrNoMem]>;
    def int_riscv_qir_h:
        Intrinsic<[],
                  [llvm_ptr_ty],
                  [IntrHasSideEffects]>;
    
    def int_riscv_qir_x:
        Intrinsic<[],
                  [llvm_ptr_ty],
                  [IntrHasSideEffects]>;
    def int_riscv_qir_cx:
        Intrinsic<[],
                  [llvm_ptr_ty],
                  [IntrHasSideEffects]>;
    def int_riscv_qir_mz:
        Intrinsic<[],
                  [llvm_ptr_ty, llvm_ptr_ty],
                  [IntrHasSideEffects]>;
}