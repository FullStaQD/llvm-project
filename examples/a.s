	.attribute	4, 16
	.attribute	5, "rv32i2p1_f2p2_d2p2_v1p0_zicsr2p0_zve32f1p0_zve32x1p0_zve64d1p0_zve64f1p0_zve64x1p0_zvl128b1p0_zvl32b1p0_zvl64b1p0"
	.file	"a.ll"
	.text
	.globl	_start                          # -- Begin function _start
	.p2align	2
	.type	_start,@function
_start:                                 # @_start
	.cfi_startproc
# %bb.0:                                # %entry
	lui	a0, 32
	lui	a1, 1
	addi	a0, a0, 256
	sw	a0, 0(a1)
	vsetivli	zero, 3, e8, m1, ta, ma
	vle8.v	v8, (a1)
	my_vadd.vx	v8, v8, zero
	li	a0, 85
	vsetivli	zero, 2, e8, m1, ta, ma
	qv.h	v8, a0, 12
.LBB0_1:                                # %loop
                                        # =>This Inner Loop Header: Depth=1
	j	.LBB0_1
.Lfunc_end0:
	.size	_start, .Lfunc_end0-_start
	.cfi_endproc
                                        # -- End function
	.section	".note.GNU-stack","",@progbits
