
C:\Users\QingJ\Desktop\root\work\boot_out\output.elf:	file format elf64-littleaarch64

Disassembly of section .kernel:

ffffffc0080bbd30 <el0_svc_common>:
ffffffc0080bbd30: d503233f     	paciasp
ffffffc0080bbd34: d10143ff     	sub	sp, sp, #0x50
ffffffc0080bbd38: f800865e     	str	x30, [x18], #0x8
ffffffc0080bbd3c: a9017bfd     	stp	x29, x30, [sp, #0x10]
ffffffc0080bbd40: a9025ff8     	stp	x24, x23, [sp, #0x20]
ffffffc0080bbd44: a90357f6     	stp	x22, x21, [sp, #0x30]
ffffffc0080bbd48: a9044ff4     	stp	x20, x19, [sp, #0x40]
ffffffc0080bbd4c: 910043fd     	add	x29, sp, #0x10
ffffffc0080bbd50: f9400008     	ldr	x8, [x0]
ffffffc0080bbd54: d5384116     	mrs	x22, SP_EL0
ffffffc0080bbd58: f94002d7     	ldr	x23, [x22]
ffffffc0080bbd5c: b9011801     	str	w1, [x0, #0x118]
ffffffc0080bbd60: f9008808     	str	x8, [x0, #0x110]
ffffffc0080bbd64: f94002c8     	ldr	x8, [x22]
ffffffc0080bbd68: 2a0103f5     	mov	w21, w1
ffffffc0080bbd6c: aa0003f3     	mov	x19, x0
ffffffc0080bbd70: aa0203f4     	mov	x20, x2
ffffffc0080bbd74: 37a80988     	tbnz	w8, #0x15, 0xffffffc0080bbea4 <el0_svc_common+0x174>
ffffffc0080bbd78: aa1f03e8     	mov	x8, xzr
ffffffc0080bbd7c: d51b4228     	msr	DAIF, x8
ffffffc0080bbd80: 37300457     	tbnz	w23, #0x6, 0xffffffc0080bbe08 <el0_svc_common+0xd8>
ffffffc0080bbd84: f27812f7     	ands	x23, x23, #0x1f00
ffffffc0080bbd88: 540001e0     	b.eq	0xffffffc0080bbdc4 <el0_svc_common+0x94>
ffffffc0080bbd8c: 310006bf     	cmn	w21, #0x1
ffffffc0080bbd90: 54000101     	b.ne	0xffffffc0080bbdb0 <el0_svc_common+0x80>
ffffffc0080bbd94: f94002c8     	ldr	x8, [x22]
ffffffc0080bbd98: 12804009     	mov	w9, #-0x201     // =-513
ffffffc0080bbd9c: 91076d29     	add	x9, x9, #0x1db
ffffffc0080bbda0: f26a011f     	tst	x8, #0x400000
ffffffc0080bbda4: 928004a8     	mov	x8, #-0x26      // =-38
ffffffc0080bbda8: 9a890108     	csel	x8, x8, x9, eq
ffffffc0080bbdac: f9000268     	str	x8, [x19]
ffffffc0080bbdb0: aa1303e0     	mov	x0, x19
ffffffc0080bbdb4: 97ffa980     	bl	0xffffffc0080a63b4 <syscall_trace_enter>
ffffffc0080bbdb8: 2a0003f5     	mov	w21, w0
ffffffc0080bbdbc: 3100041f     	cmn	w0, #0x1
ffffffc0080bbdc0: 540005e0     	b.eq	0xffffffc0080bbe7c <el0_svc_common+0x14c>
ffffffc0080bbdc4: 710702bf     	cmp	w21, #0x1c0
ffffffc0080bbdc8: 540002e8     	b.hi	0xffffffc0080bbe24 <el0_svc_common+0xf4>
ffffffc0080bbdcc: 2a1503e8     	mov	w8, w21
ffffffc0080bbdd0: f107051f     	cmp	x8, #0x1c1
ffffffc0080bbdd4: da1f03e8     	ngc	x8, xzr
ffffffc0080bbdd8: d503229f     	csdb
ffffffc0080bbddc: 0a0802a8     	and	w8, w21, w8
ffffffc0080bbde0: f8685a94     	ldr	x20, [x20, w8, uxtw #3]
ffffffc0080bbde4: f000cb88     	adrp	x8, 0xffffffc009a2e000 <sk_msg_zerocopy_from_iter.cfi_jt>
ffffffc0080bbde8: 91036108     	add	x8, x8, #0xd8
ffffffc0080bbdec: cb080288     	sub	x8, x20, x8
ffffffc0080bbdf0: 93c80d08     	ror	x8, x8, #0x3
ffffffc0080bbdf4: f107dd1f     	cmp	x8, #0x1f7
ffffffc0080bbdf8: 540009e2     	b.hs	0xffffffc0080bbf34 <el0_svc_common+0x204>
ffffffc0080bbdfc: aa1303e0     	mov	x0, x19
ffffffc0080bbe00: d63f0280     	blr	x20
ffffffc0080bbe04: 14000010     	b	0xffffffc0080bbe44 <el0_svc_common+0x114>
ffffffc0080bbe08: f94002c8     	ldr	x8, [x22]
ffffffc0080bbe0c: 12804009     	mov	w9, #-0x201     // =-513
ffffffc0080bbe10: f26a011f     	tst	x8, #0x400000
ffffffc0080bbe14: 92804008     	mov	x8, #-0x201     // =-513
ffffffc0080bbe18: 9a890108     	csel	x8, x8, x9, eq
ffffffc0080bbe1c: f9000268     	str	x8, [x19]
ffffffc0080bbe20: 14000019     	b	0xffffffc0080bbe84 <el0_svc_common+0x154>
ffffffc0080bbe24: f94002c8     	ldr	x8, [x22]
ffffffc0080bbe28: 36b000c8     	tbz	w8, #0x16, 0xffffffc0080bbe40 <el0_svc_common+0x110>
ffffffc0080bbe2c: aa1303e0     	mov	x0, x19
ffffffc0080bbe30: 2a1503e1     	mov	w1, w21
ffffffc0080bbe34: 94001f1b     	bl	0xffffffc0080c3aa0 <compat_arm_syscall>
ffffffc0080bbe38: b100981f     	cmn	x0, #0x26
ffffffc0080bbe3c: 54000041     	b.ne	0xffffffc0080bbe44 <el0_svc_common+0x114>
ffffffc0080bbe40: 928004a0     	mov	x0, #-0x26      // =-38
ffffffc0080bbe44: f94002c8     	ldr	x8, [x22]
ffffffc0080bbe48: 92407c09     	and	x9, x0, #0xffffffff
ffffffc0080bbe4c: f26a011f     	tst	x8, #0x400000
ffffffc0080bbe50: 9a890008     	csel	x8, x0, x9, eq
ffffffc0080bbe54: f9000268     	str	x8, [x19]
ffffffc0080bbe58: b5000137     	cbnz	x23, 0xffffffc0080bbe7c <el0_svc_common+0x14c>
ffffffc0080bbe5c: d5034fdf     	msr	DAIFSet, #0xf
ffffffc0080bbe60: b94002c8     	ldr	w8, [x22]
ffffffc0080bbe64: 5283e009     	mov	w9, #0x1f00     // =7936
ffffffc0080bbe68: 72a00409     	movk	w9, #0x20, lsl #16
ffffffc0080bbe6c: 6a09011f     	tst	w8, w9
ffffffc0080bbe70: 540000a0     	b.eq	0xffffffc0080bbe84 <el0_svc_common+0x154>
ffffffc0080bbe74: aa1f03e8     	mov	x8, xzr
ffffffc0080bbe78: d51b4228     	msr	DAIF, x8
ffffffc0080bbe7c: aa1303e0     	mov	x0, x19
ffffffc0080bbe80: 97ffa9df     	bl	0xffffffc0080a65fc <syscall_trace_exit>
ffffffc0080bbe84: a9417bfd     	ldp	x29, x30, [sp, #0x10]
ffffffc0080bbe88: a9444ff4     	ldp	x20, x19, [sp, #0x40]
ffffffc0080bbe8c: a94357f6     	ldp	x22, x21, [sp, #0x30]
ffffffc0080bbe90: a9425ff8     	ldp	x24, x23, [sp, #0x20]
ffffffc0080bbe94: f85f8e5e     	ldr	x30, [x18, #-0x8]!
ffffffc0080bbe98: 910143ff     	add	sp, sp, #0x50
ffffffc0080bbe9c: d50323bf     	autiasp
ffffffc0080bbea0: d65f03c0     	ret
ffffffc0080bbea4: 910062c8     	add	x8, x22, #0x18
ffffffc0080bbea8: 88dffd08     	ldar	w8, [x8]
ffffffc0080bbeac: 35000088     	cbnz	w8, 0xffffffc0080bbebc <el0_svc_common+0x18c>
ffffffc0080bbeb0: d53b4228     	mrs	x8, DAIF
ffffffc0080bbeb4: 12190109     	and	w9, w8, #0x80
ffffffc0080bbeb8: 340004e9     	cbz	w9, 0xffffffc0080bbf54 <el0_svc_common+0x224>
ffffffc0080bbebc: 900128e8     	adrp	x8, 0xffffffc00a5d7000 <idle_sched_class+0x20>
ffffffc0080bbec0: f9441900     	ldr	x0, [x8, #0x830]
ffffffc0080bbec4: b4fff5a0     	cbz	x0, 0xffffffc0080bbd78 <el0_svc_common+0x48>
ffffffc0080bbec8: f9400808     	ldr	x8, [x0, #0x10]
ffffffc0080bbecc: b000ca29     	adrp	x9, 0xffffffc009a00000 <__traceiter_initcall_start.cfi_jt>
ffffffc0080bbed0: 910ac129     	add	x9, x9, #0x2b0
ffffffc0080bbed4: cb090109     	sub	x9, x8, x9
ffffffc0080bbed8: 93c90d29     	ror	x9, x9, #0x3
ffffffc0080bbedc: f100813f     	cmp	x9, #0x20
ffffffc0080bbee0: 540003e2     	b.hs	0xffffffc0080bbf5c <el0_svc_common+0x22c>
ffffffc0080bbee4: 52800021     	mov	w1, #0x1        // =1
ffffffc0080bbee8: 52800038     	mov	w24, #0x1       // =1
ffffffc0080bbeec: d63f0100     	blr	x8
ffffffc0080bbef0: 3607f440     	tbz	w0, #0x0, 0xffffffc0080bbd78 <el0_svc_common+0x48>
ffffffc0080bbef4: b0014f69     	adrp	x9, 0xffffffc00aaa8000 <overflow_stack+0xd00>
ffffffc0080bbef8: d538d088     	mrs	x8, TPIDR_EL1
ffffffc0080bbefc: 911ee129     	add	x9, x9, #0x7b8
ffffffc0080bbf00: 5284002a     	mov	w10, #0x2001    // =8193
ffffffc0080bbf04: b8296918     	str	w24, [x8, x9]
ffffffc0080bbf08: d5300248     	mrs	x8, MDSCR_EL1
ffffffc0080bbf0c: 927f790b     	and	x11, x8, #0xfffffffe
ffffffc0080bbf10: aa0a016a     	orr	x10, x11, x10
ffffffc0080bbf14: d510024a     	msr	MDSCR_EL1, x10
ffffffc0080bbf18: d50348ff     	msr	DAIFClr, #0x8
ffffffc0080bbf1c: d5033fdf     	isb
ffffffc0080bbf20: 92407d08     	and	x8, x8, #0xffffffff
ffffffc0080bbf24: d5100248     	msr	MDSCR_EL1, x8
ffffffc0080bbf28: d538d088     	mrs	x8, TPIDR_EL1
ffffffc0080bbf2c: b829691f     	str	wzr, [x8, x9]
ffffffc0080bbf30: 17ffff92     	b	0xffffffc0080bbd78 <el0_svc_common+0x48>
ffffffc0080bbf34: d2839800     	mov	x0, #0x1cc0     // =7360
ffffffc0080bbf38: f2bef7e0     	movk	x0, #0xf7bf, lsl #16
ffffffc0080bbf3c: f2c4bc20     	movk	x0, #0x25e1, lsl #32
ffffffc0080bbf40: f2e23260     	movk	x0, #0x1193, lsl #48
ffffffc0080bbf44: aa1403e1     	mov	x1, x20
ffffffc0080bbf48: aa1f03e2     	mov	x2, xzr
ffffffc0080bbf4c: 940d5cd2     	bl	0xffffffc008413294 <__cfi_slowpath>
ffffffc0080bbf50: 17ffffab     	b	0xffffffc0080bbdfc <el0_svc_common+0xcc>
ffffffc0080bbf54: d4210000     	brk	#0x800
ffffffc0080bbf58: 17ffff88     	b	0xffffffc0080bbd78 <el0_svc_common+0x48>
ffffffc0080bbf5c: f90007e0     	str	x0, [sp, #0x8]
ffffffc0080bbf60: d29bdd20     	mov	x0, #0xdee9     // =57065
ffffffc0080bbf64: f2aae660     	movk	x0, #0x5733, lsl #16
ffffffc0080bbf68: f2c38280     	movk	x0, #0x1c14, lsl #32
ffffffc0080bbf6c: f2e18aa0     	movk	x0, #0xc55, lsl #48
ffffffc0080bbf70: aa0803e1     	mov	x1, x8
ffffffc0080bbf74: aa1f03e2     	mov	x2, xzr
ffffffc0080bbf78: aa0803f8     	mov	x24, x8
ffffffc0080bbf7c: 940d5cc6     	bl	0xffffffc008413294 <__cfi_slowpath>
ffffffc0080bbf80: f94007e0     	ldr	x0, [sp, #0x8]
ffffffc0080bbf84: aa1803e8     	mov	x8, x24
ffffffc0080bbf88: 17ffffd7     	b	0xffffffc0080bbee4 <el0_svc_common+0x1b4>
ffffffc0080bbf8c: b8bfc108     	ldapr	w8, [x8]
ffffffc0080bbf90: d5384608     	mrs	x8, ICC_PMR_EL1
ffffffc0080bbf94: 521b0909     	eor	w9, w8, #0xe0
ffffffc0080bbf98: d53cd048     	mrs	x8, TPIDR_EL2
ffffffc0080bbf9c: d53cd048     	mrs	x8, TPIDR_EL2
