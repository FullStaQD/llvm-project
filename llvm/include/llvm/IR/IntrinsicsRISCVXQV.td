//===- IntrinsicsRISCVQV.td - Defines RISCVQV intrinsics -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Standard Vector Quantum extension of RISCV.
//
//===----------------------------------------------------------------------===//

// QV.SINGLE vs1, rs2, Block_imm
class QVSingleIntrinsic : Intrinsic<[], // void return type
                     [llvm_anyvector_ty, // vs1 (qubits)
                      llvm_anyint_ty,    // rs2 (tag)
                      llvm_anyint_ty,    // Block_imm (wait time)
                      llvm_anyint_ty],   // vl
                     [IntrHasSideEffects, IntrNoMem]>;
    
// QV.Pair vs1, vs2, Block_imm
class QVPairIntrinsic : Intrinsic<[],
                     [llvm_anyvector_ty, // vs1
                      llvm_anyvector_ty, // vs2
                      llvm_anyint_ty,    // Block_imm (wait time)
                      llvm_anyint_ty],   // vl
                     [IntrHasSideEffects, IntrNoMem]>;


let TargetPrefix = "riscv" in {
    def int_riscv_qv_h : QVSingleIntrinsic;
    def int_riscv_qv_x : QVSingleIntrinsic;
    def int_riscv_qv_mz : QVSingleIntrinsic;

    def int_riscv_qv_cx : QVPairIntrinsic;

    // Reads CSR qv.mres: bit k is the outcome of element k of the latest qv.mz.
    // TODO: The hardware stores the outcomes of a measurement in qv.mres, a
    // single 32-bit register. A qv.mz with VL > 32 still measures all elements,
    // but the outcomes of elements 32 and up are silently dropped (HiSEP-Q
    // plans to trap instead). This is a workaround on their side for now. For
    // QCC this means we have to be careful: our workaround likely has to check
    // for a static VL <= 32 when measuring.
    def int_riscv_qv_mres : Intrinsic<[llvm_anyint_ty], [],
                                      [IntrHasSideEffects, IntrNoMem]>;
}
