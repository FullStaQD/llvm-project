; llc -mtriple=riscv32 -mattr=+v examples/a.ll -o examples/a.s

; Target Data Layout for RV32
target datalayout = "e-m:e-p:32:32-i64:64-n32-S128"
target triple = "riscv32"

; --- INTRINSIC DECLARATIONS ---

; vle8.v intrinsic: returns vector, takes (passthrough, ptr, vector_length)
declare <vscale x 1 x i8> @llvm.riscv.vle.nxv1i8(<vscale x 1 x i8>, ptr, i32)
declare <vscale x 8 x i8> @llvm.riscv.vle.nxv8i8(<vscale x 8 x i8>, ptr, i32)
declare void @llvm.riscv.vse.nxv1i8(<vscale x 1 x i8>, ptr, i32)
declare void @llvm.riscv.vse.nxv8i8(<vscale x 8 x i8>, ptr, i32)

; For comparision the intrinsic of vadd.vv:
declare <vscale x 8 x i8> @llvm.riscv.vadd.nxv8i8.nxv8i8(
    <vscale x 8 x i8> %passthru,
    <vscale x 8 x i8> %op1,
    <vscale x 8 x i8> %op2,
    i32 %vl
)
; vadd.vx or vadd.vi:
declare <vscale x 8 x i8> @llvm.riscv.vadd.nxv8i8.i8.i32(
    <vscale x 8 x i8> %passthru,
    <vscale x 8 x i8> %op1,
    i8 %op2,
    i32 %vl
)

declare <vscale x 8 x i8> @llvm.riscv.my.vadd.nxv8i8.i32.i32(
    <vscale x 8 x i8> %passthru,
    <vscale x 8 x i8> %op1,
    i32 %op2,
    i32 %vl
)

; Your custom qv.h intrinsic: returns vector, takes (input_vector, tag, immediate, vector_length)
;declare void @llvm.riscv.qv.h.nxv8i8(<vscale x 8 x i8>, i32, i32, i32)

define void @_start() {
entry:
    ; s0 = 0x1000
    %s0 = inttoptr i32 4096 to ptr

    ; sw t0, 0(s0) -> stores [0, 1, 2, 0] in one 32-bit write
    store i32 131328, ptr %s0, align 4

    ; vsetvli t2, a0, e8, m1, ta, ma (handled implicitly by VL = 3 in the intrinsic)

    ; vle8.v v1, (s0) with VL = 3
    ;%v1 = call <vscale x 1 x i8> @llvm.riscv.vle.nxv1i8(<vscale x 1 x i8> poison, ptr %s0, i32 3)
    %v1 = call <vscale x 8 x i8> @llvm.riscv.vle.nxv8i8(<vscale x 8 x i8> poison, ptr %s0, i32 3)

    ; FIXME: just a demo
    ;%v2 = call <vscale x 8 x i8> @llvm.riscv.vadd.nxv8i8.nxv4i8(<vscale x 8 x i8> poison, <vscale x 8 x i8> %v1, <vscale x 8 x i8> %v1, i32 3)
    ;%v3 = call <vscale x 8 x i8> @llvm.riscv.vadd.nxv8i8.i8.i32(<vscale x 8 x i8> poison, <vscale x 8 x i8> %v2, i8 5, i32 3)
    ;%v4 = call <vscale x 8 x i8> @llvm.riscv.my.vadd.nxv8i8.i8.i32(<vscale x 8 x i8> poison, <vscale x 8 x i8> %v3, i32 15, i32 3)

    %v2 = call <vscale x 8 x i8> @llvm.riscv.my.vadd.nxv8i8.i8.i32(<vscale x 8 x i8> poison, <vscale x 8 x i8> %v1, i32 15, i32 2)

    ; FIXME: this makes sure vle is not optimized away
    ;call void @llvm.riscv.vse.nxv1i8(<vscale x 1 x i8> %v1, ptr %s0, i32 3)
    call void @llvm.riscv.vse.nxv8i8(<vscale x 8 x i8> %v2, ptr %s0, i32 3)

    ; qv.h v1, t1, 0 (t1 = 0x55 = 85 decimal, imm = 0, VL = 3)
    ;%v2 = call <vscale x 1 x i8> @llvm.riscv.qv.h.nxv1i8(<vscale x 1 x i8> %v1, i32 85, i32 0, i32 3)



    ; FIXME: does this really work?
    ; jal zero, 0 -> infinite loop
    br label %loop

loop:
    br label %loop
}