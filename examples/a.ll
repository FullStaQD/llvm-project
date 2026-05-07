; llc -mtriple=riscv32 -mattr=+v examples/a.ll -o examples/a.s

; Target Data Layout for RV32
target datalayout = "e-m:e-p:32:32-i64:64-n32-S128"
target triple = "riscv32"

; vle8.v intrinsic: returns vector, takes (passthrough, ptr, vector_length)
declare <vscale x 8 x i8> @llvm.riscv.vle.nxv8i8(<vscale x 8 x i8>, ptr, i32)
declare void @llvm.riscv.vse.nxv8i8(<vscale x 8 x i8>, ptr, i32)

; For comparision: vadd.vx or vadd.vi:
declare <vscale x 8 x i8> @llvm.riscv.vadd.nxv8i8.i8.i32(
    <vscale x 8 x i8> %passthru,
    <vscale x 8 x i8> %op1,
    i8 %op2,
    i32 %vl
)

; my_vadd.vx or my_vadd.vi:
declare <vscale x 8 x i8> @llvm.riscv.my.vadd.nxv8i8.i32.i32(
    <vscale x 8 x i8> %passthru,
    <vscale x 8 x i8> %op1,
    i32 %op2,  ; Sorry: ideal would be i8, but this would need some more coding work.
    i32 %vl
)

; qv.h vs1, rs2, Block_imm
declare void @llvm.riscv.qv.h.nxv8i8.i32.i32(
    <vscale x 8 x i8> %tgt,      ; vs1
    i32 %tag,                    ; rs2
    i32 %block_imm,              ; Block_imm (will be constrained to 5 bits)
    i32 %vl                      ; vl (for vsetvli magic)
)

define void @_start() {
entry:
    ; data_ptr = 0x1000
    %data_ptr = inttoptr i32 4096 to ptr

    ; sw -> stores [0, 1, 2, 0] in one 32-bit write
    store i32 131328, ptr %data_ptr, align 4

    ; vle8.v with VL = 3
    %v1 = call <vscale x 8 x i8> @llvm.riscv.vle.nxv8i8(<vscale x 8 x i8> poison, ptr %data_ptr, i32 3)

    ; my.vadd.vx with VL = 3
    %v2 = call <vscale x 8 x i8> @llvm.riscv.my.vadd.nxv8i8.i32.i32(<vscale x 8 x i8> poison, <vscale x 8 x i8> %v1, i32 0, i32 3)

    ; qv.h with VL = 2 (!= 3 to test vsetvli magic)
    call void @llvm.riscv.qv.h.nxv8i8.i32.i32(<vscale x 8 x i8> %v2, i32 85, i32 12, i32 2)

    ; FIXME: does this really work?
    ; jal zero, 0 -> infinite loop
    br label %loop

loop:
    br label %loop
}