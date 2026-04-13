declare i32 @llvm.riscv.svq.add(i32, i32)

define i32 @test(i32 %a, i32 %b) {
entry:
    %res = call i32 @llvm.riscv.svq.add(i32 %a, i32 %b)
    ret i32 %res
}