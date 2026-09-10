	.file	"sigframe_offset.c"
	.text
	.globl	main                            // -- Begin function main
	.p2align	2
	.type	main,@function
main:                                   // @main
	.cfi_startproc
// %bb.0:
	sub	sp, sp, #32
	.cfi_def_cfa_offset 32
	stp	x29, x30, [sp, #16]             // 16-byte Folded Spill
	add	x29, sp, #16
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	mov	w8, wzr
	str	w8, [sp, #8]                    // 4-byte Folded Spill
	stur	wzr, [x29, #-4]
	adrp	x0, .L.str
	add	x0, x0, :lo12:.L.str
	mov	x1, #4384                       // =0x1120
	bl	printf
	adrp	x0, .L.str.1
	add	x0, x0, :lo12:.L.str.1
	mov	x1, #16                         // =0x10
	bl	printf
	adrp	x0, .L.str.2
	add	x0, x0, :lo12:.L.str.2
	mov	x1, #4560                       // =0x11d0
	bl	printf
	adrp	x0, .L.str.3
	add	x0, x0, :lo12:.L.str.3
	mov	x1, #4688                       // =0x1250
	bl	printf
	adrp	x0, .L.str.4
	add	x0, x0, :lo12:.L.str.4
	mov	x1, #168                        // =0xa8
	bl	printf
	adrp	x0, .L.str.5
	add	x0, x0, :lo12:.L.str.5
	mov	x1, #304                        // =0x130
	bl	printf
	adrp	x0, .L.str.6
	add	x0, x0, :lo12:.L.str.6
	mov	x1, #312                        // =0x138
	bl	printf
	adrp	x0, .L.str.7
	add	x0, x0, :lo12:.L.str.7
	mov	x1, #560                        // =0x230
	bl	printf
	adrp	x0, .L.str.8
	add	x0, x0, :lo12:.L.str.8
	mov	x1, #568                        // =0x238
	bl	printf
	adrp	x0, .L.str.9
	add	x0, x0, :lo12:.L.str.9
	mov	x1, #576                        // =0x240
	bl	printf
	adrp	x0, .L.str.10
	add	x0, x0, :lo12:.L.str.10
	mov	x1, #592                        // =0x250
	mov	x2, xzr
	bl	printf
	adrp	x0, .L.str.11
	add	x0, x0, :lo12:.L.str.11
	mov	x1, #608                        // =0x260
	bl	printf
	adrp	x0, .L.str.12
	add	x0, x0, :lo12:.L.str.12
	mov	x1, #1120                       // =0x460
	bl	printf
	ldr	w0, [sp, #8]                    // 4-byte Folded Reload
	.cfi_def_cfa wsp, 32
	ldp	x29, x30, [sp, #16]             // 16-byte Folded Reload
	add	sp, sp, #32
	.cfi_def_cfa_offset 0
	.cfi_restore w30
	.cfi_restore w29
	ret
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc
                                        // -- End function
	.type	.L.str,@object                  // @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"sizeof sigcontext = 0x%zx\n"
	.size	.L.str, 27

	.type	.L.str.1,@object                // @.str.1
.L.str.1:
	.asciz	"alignof sigcontext = %zu\n"
	.size	.L.str.1, 26

	.type	.L.str.2,@object                // @.str.2
.L.str.2:
	.asciz	"sizeof ucontext    = 0x%zx\n"
	.size	.L.str.2, 28

	.type	.L.str.3,@object                // @.str.3
.L.str.3:
	.asciz	"sizeof rt_sigframe = 0x%zx\n"
	.size	.L.str.3, 28

	.type	.L.str.4,@object                // @.str.4
.L.str.4:
	.asciz	"uc_sigmask         = 0x%zx\n"
	.size	.L.str.4, 28

	.type	.L.str.5,@object                // @.str.5
.L.str.5:
	.asciz	"uc_mcontext        = 0x%zx\n"
	.size	.L.str.5, 28

	.type	.L.str.6,@object                // @.str.6
.L.str.6:
	.asciz	"regs[0]            = 0x%zx\n"
	.size	.L.str.6, 28

	.type	.L.str.7,@object                // @.str.7
.L.str.7:
	.asciz	"sp                 = 0x%zx\n"
	.size	.L.str.7, 28

	.type	.L.str.8,@object                // @.str.8
.L.str.8:
	.asciz	"pc                 = 0x%zx\n"
	.size	.L.str.8, 28

	.type	.L.str.9,@object                // @.str.9
.L.str.9:
	.asciz	"pstate             = 0x%zx\n"
	.size	.L.str.9, 28

	.type	.L.str.10,@object               // @.str.10
.L.str.10:
	.asciz	"__reserved         = 0x%zx  (mod16=%zu)\n"
	.size	.L.str.10, 41

	.type	.L.str.11,@object               // @.str.11
.L.str.11:
	.asciz	"vregs              = 0x%zx\n"
	.size	.L.str.11, 28

	.type	.L.str.12,@object               // @.str.12
.L.str.12:
	.asciz	"fpsimd term        = 0x%zx\n"
	.size	.L.str.12, 28

	.ident	"Android (13989888, based on r563880c) clang version 21.0.0 (https://android.googlesource.com/toolchain/llvm-project 5e96669f06077099aa41290cdb4c5e6fa0f59349)"
	.section	".note.GNU-stack","",@progbits
