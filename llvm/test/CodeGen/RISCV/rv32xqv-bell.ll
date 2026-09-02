; RUN: llc -mtriple=riscv32 -mattr=+experimental-xqv -verify-machineinstrs < %s | FileCheck %s

target datalayout = "e-m:e-p:32:32-i64:64-n32-S128"

; TODO: Check for LMUL>1.
; qv.h vs1, rs2, Block_imm
declare void @llvm.riscv.qv.h.nxv8i8.i32.i32.i32(<vscale x 8 x i8>, i32, i32, i32)

; qv.mz vs1, rs2, Block_imm
declare void @llvm.riscv.qv.mz.nxv8i8.i32.i32.i32(<vscale x 8 x i8>, i32, i32, i32)

; qv.cx vs1, vs2, Block_imm
declare void @llvm.riscv.qv.cx.nxv8i8.nxv8i8.i32.i32(<vscale x 8 x i8>, <vscale x 8 x i8>, i32, i32)

@ctrl_qubits = local_unnamed_addr constant <8 x i8> <i8 0, i8 2, i8 4, i8 6, i8 8, i8 10, i8 12, i8 14>, align 8
@tgt_qubits  = local_unnamed_addr constant <8 x i8> <i8 1, i8 3, i8 5, i8 7, i8 9, i8 11, i8 13, i8 15>, align 8

define void @load_vectors() #0 {
entry:
  %ctrl = load <vscale x 8 x i8>, ptr @ctrl_qubits, align 8
  %tgt  = load <vscale x 8 x i8>, ptr @tgt_qubits, align 8

  call void @llvm.riscv.qv.h.nxv8i8.i32.i32.i32(<vscale x 8 x i8> %ctrl, i32 85, i32 12, i32 4)
  call void @llvm.riscv.qv.cx.nxv8i8.nxv8i8.i32.i32(<vscale x 8 x i8> %ctrl, <vscale x 8 x i8> %tgt, i32 12, i32 4)
  call void @llvm.riscv.qv.mz.nxv8i8.i32.i32.i32(<vscale x 8 x i8> %ctrl, i32 85, i32 12, i32 4)
  call void @llvm.riscv.qv.mz.nxv8i8.i32.i32.i32(<vscale x 8 x i8> %tgt, i32 85, i32 12, i32 4)

; TODO: output recording, e.g. via __quantum__rt__bool_record_output .
; Requires support from HiSEP-Q in some form.

  ret void
}

attributes #0 = { "target-features"="+experimental-xqv" }

; CHECK-LABEL: load_vectors:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    lui [[A0:a[0-9]+]], %hi(ctrl_qubits)
; CHECK-NEXT:    addi [[A0]], [[A0]], %lo(ctrl_qubits)
; CHECK-NEXT:    lui [[A1:a[0-9]+]], %hi(tgt_qubits)
; CHECK-NEXT:    addi [[A1]], [[A1]], %lo(tgt_qubits)
; CHECK-NEXT:    vl1r.v [[VCTRL:v[0-9]+]], ([[A0]])
; CHECK-NEXT:    vl1r.v [[VTGT:v[0-9]+]], ([[A1]])
; CHECK-NEXT:    li [[A0]], 4
; CHECK-NEXT:    li [[A1]], 85
; CHECK-NEXT:    vsetvli zero, [[A0]], e8, m1, ta, ma
; CHECK-NEXT:    qv.h [[VCTRL]], [[A1]], 12
; CHECK-NEXT:    qv.cx [[VCTRL]], [[VTGT]], 12
; CHECK-NEXT:    qv.mz [[VCTRL]], [[A1]], 12
; CHECK-NEXT:    qv.mz [[VTGT]], [[A1]], 12
; CHECK-NEXT:    ret
