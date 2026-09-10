
C:\Users\QingJ\Desktop\root\work\boot_out\output.elf:	file format elf64-littleaarch64

Disassembly of section .kernel:

ffffffc0082dbbf0 <__arm64_sys_futex>:
ffffffc0082dbbf0: d503233f     	paciasp
ffffffc0082dbbf4: d10383ff     	sub	sp, sp, #0xe0
ffffffc0082dbbf8: f800865e     	str	x30, [x18], #0x8
ffffffc0082dbbfc: a9087bfd     	stp	x29, x30, [sp, #0x80]
ffffffc0082dbc00: a9096ffc     	stp	x28, x27, [sp, #0x90]
ffffffc0082dbc04: a90a67fa     	stp	x26, x25, [sp, #0xa0]
ffffffc0082dbc08: a90b5ff8     	stp	x24, x23, [sp, #0xb0]
ffffffc0082dbc0c: a90c57f6     	stp	x22, x21, [sp, #0xc0]
ffffffc0082dbc10: a90d4ff4     	stp	x20, x19, [sp, #0xd0]
ffffffc0082dbc14: 910203fd     	add	x29, sp, #0x80
ffffffc0082dbc18: 900117e8     	adrp	x8, 0xffffffc00a5d7000 <idle_sched_class+0x20>
ffffffc0082dbc1c: f9426908     	ldr	x8, [x8, #0x4d0]
ffffffc0082dbc20: f81f83a8     	stur	x8, [x29, #-0x8]
ffffffc0082dbc24: b9400814     	ldr	w20, [x0, #0x8]
ffffffc0082dbc28: f9400013     	ldr	x19, [x0]
ffffffc0082dbc2c: b9401016     	ldr	w22, [x0, #0x10]
ffffffc0082dbc30: a941d418     	ldp	x24, x21, [x0, #0x18]
ffffffc0082dbc34: b9402817     	ldr	w23, [x0, #0x28]
ffffffc0082dbc38: 12177699     	and	w25, w20, #0xfffffe7f
ffffffc0082dbc3c: f81e03bf     	stur	xzr, [x29, #-0x20]
ffffffc0082dbc40: b4000118     	cbz	x24, 0xffffffc0082dbc60 <__arm64_sys_futex+0x70>
ffffffc0082dbc44: 12803048     	mov	w8, #-0x183     // =-387
ffffffc0082dbc48: 0a080288     	and	w8, w20, w8
ffffffc0082dbc4c: 7100251f     	cmp	w8, #0x9
ffffffc0082dbc50: 54000460     	b.eq	0xffffffc0082dbcdc <__arm64_sys_futex+0xec>
ffffffc0082dbc54: 34000459     	cbz	w25, 0xffffffc0082dbcdc <__arm64_sys_futex+0xec>
ffffffc0082dbc58: 71001b3f     	cmp	w25, #0x6
ffffffc0082dbc5c: 54000400     	b.eq	0xffffffc0082dbcdc <__arm64_sys_futex+0xec>
ffffffc0082dbc60: aa1f03e3     	mov	x3, xzr
ffffffc0082dbc64: 7100333f     	cmp	w25, #0xc
ffffffc0082dbc68: 2a1f03e5     	mov	w5, wzr
ffffffc0082dbc6c: 540000e8     	b.hi	0xffffffc0082dbc88 <__arm64_sys_futex+0x98>
ffffffc0082dbc70: 52800028     	mov	w8, #0x1        // =1
ffffffc0082dbc74: 1ad92108     	lsl	w8, w8, w25
ffffffc0082dbc78: 52820709     	mov	w9, #0x1038     // =4152
ffffffc0082dbc7c: 6a09011f     	tst	w8, w9
ffffffc0082dbc80: 54000040     	b.eq	0xffffffc0082dbc88 <__arm64_sys_futex+0x98>
ffffffc0082dbc84: 2a1803e5     	mov	w5, w24
ffffffc0082dbc88: aa1303e0     	mov	x0, x19
ffffffc0082dbc8c: 2a1403e1     	mov	w1, w20
ffffffc0082dbc90: 2a1603e2     	mov	w2, w22
ffffffc0082dbc94: aa1503e4     	mov	x4, x21
ffffffc0082dbc98: 2a1703e6     	mov	w6, w23
ffffffc0082dbc9c: 97ffc28b     	bl	0xffffffc0082cc6c8 <do_futex>
ffffffc0082dbca0: 900117e9     	adrp	x9, 0xffffffc00a5d7000 <idle_sched_class+0x20>
ffffffc0082dbca4: f85f83a8     	ldur	x8, [x29, #-0x8]
ffffffc0082dbca8: f9426929     	ldr	x9, [x9, #0x4d0]
ffffffc0082dbcac: eb08013f     	cmp	x9, x8
ffffffc0082dbcb0: 54001381     	b.ne	0xffffffc0082dbf20 <__arm64_sys_futex+0x330>
ffffffc0082dbcb4: a9487bfd     	ldp	x29, x30, [sp, #0x80]
ffffffc0082dbcb8: a94d4ff4     	ldp	x20, x19, [sp, #0xd0]
ffffffc0082dbcbc: a94c57f6     	ldp	x22, x21, [sp, #0xc0]
ffffffc0082dbcc0: a94b5ff8     	ldp	x24, x23, [sp, #0xb0]
ffffffc0082dbcc4: a94a67fa     	ldp	x26, x25, [sp, #0xa0]
ffffffc0082dbcc8: a9496ffc     	ldp	x28, x27, [sp, #0x90]
ffffffc0082dbccc: f85f8e5e     	ldr	x30, [x18, #-0x8]!
ffffffc0082dbcd0: 910383ff     	add	sp, sp, #0xe0
ffffffc0082dbcd4: d50323bf     	autiasp
ffffffc0082dbcd8: d65f03c0     	ret
ffffffc0082dbcdc: d10063a0     	sub	x0, x29, #0x18
ffffffc0082dbce0: 52800202     	mov	w2, #0x10       // =16
ffffffc0082dbce4: aa1803e1     	mov	x1, x24
ffffffc0082dbce8: a93effbf     	stp	xzr, xzr, [x29, #-0x18]
ffffffc0082dbcec: 97feef8c     	bl	0xffffffc008297b1c <_copy_from_user.6661>
ffffffc0082dbcf0: 34000060     	cbz	w0, 0xffffffc0082dbcfc <__arm64_sys_futex+0x10c>
ffffffc0082dbcf4: 928001a0     	mov	x0, #-0xe       // =-14
ffffffc0082dbcf8: 17ffffea     	b	0xffffffc0082dbca0 <__arm64_sys_futex+0xb0>
ffffffc0082dbcfc: a97eafa9     	ldp	x9, x11, [x29, #-0x18]
ffffffc0082dbd00: d5384108     	mrs	x8, SP_EL0
ffffffc0082dbd04: f940010a     	ldr	x10, [x8]
ffffffc0082dbd08: 92407d6c     	and	x12, x11, #0xffffffff
ffffffc0082dbd0c: f26a015f     	tst	x10, #0x400000
ffffffc0082dbd10: 9a8c016a     	csel	x10, x11, x12, eq
ffffffc0082dbd14: b7f80ac9     	tbnz	x9, #0x3f, 0xffffffc0082dbe6c <__arm64_sys_futex+0x27c>
ffffffc0082dbd18: 5299400b     	mov	w11, #0xca00    // =51712
ffffffc0082dbd1c: 72a7734b     	movk	w11, #0x3b9a, lsl #16
ffffffc0082dbd20: eb0b015f     	cmp	x10, x11
ffffffc0082dbd24: 54000a42     	b.hs	0xffffffc0082dbe6c <__arm64_sys_futex+0x27c>
ffffffc0082dbd28: d28fa06c     	mov	x12, #0x7d03    // =32003
ffffffc0082dbd2c: f2a4b82c     	movk	x12, #0x25c1, lsl #16
ffffffc0082dbd30: f2c0004c     	movk	x12, #0x2, lsl #32
ffffffc0082dbd34: 9b0b292a     	madd	x10, x9, x11, x10
ffffffc0082dbd38: eb0c013f     	cmp	x9, x12
ffffffc0082dbd3c: 92f00009     	mov	x9, #0x7fffffffffffffff // =9223372036854775807
ffffffc0082dbd40: 9a8ac129     	csel	x9, x9, x10, gt
ffffffc0082dbd44: f81e03a9     	stur	x9, [x29, #-0x20]
ffffffc0082dbd48: 340001d9     	cbz	w25, 0xffffffc0082dbd80 <__arm64_sys_futex+0x190>
ffffffc0082dbd4c: 71001b3f     	cmp	w25, #0x6
ffffffc0082dbd50: d10083a3     	sub	x3, x29, #0x20
ffffffc0082dbd54: 54fff880     	b.eq	0xffffffc0082dbc64 <__arm64_sys_futex+0x74>
ffffffc0082dbd58: 3747f874     	tbnz	w20, #0x8, 0xffffffc0082dbc64 <__arm64_sys_futex+0x74>
ffffffc0082dbd5c: f943e908     	ldr	x8, [x8, #0x7d0]
ffffffc0082dbd60: d001450a     	adrp	x10, 0xffffffc00ab7d000 <event_alarmtimer_start+0x18>
ffffffc0082dbd64: 9132614a     	add	x10, x10, #0xc98
ffffffc0082dbd68: f9401908     	ldr	x8, [x8, #0x30]
ffffffc0082dbd6c: eb0a011f     	cmp	x8, x10
ffffffc0082dbd70: 54000c81     	b.ne	0xffffffc0082dbf00 <__arm64_sys_futex+0x310>
ffffffc0082dbd74: d10083a3     	sub	x3, x29, #0x20
ffffffc0082dbd78: f81e03a9     	stur	x9, [x29, #-0x20]
ffffffc0082dbd7c: 17ffffba     	b	0xffffffc0082dbc64 <__arm64_sys_futex+0x74>
ffffffc0082dbd80: d0013fe8     	adrp	x8, 0xffffffc00aad9000 <nf_conntrack_locks+0x6c0>
ffffffc0082dbd84: b94fad08     	ldr	w8, [x8, #0xfac]
ffffffc0082dbd88: f81d83b3     	stur	x19, [x29, #-0x28]
ffffffc0082dbd8c: 35000b68     	cbnz	w8, 0xffffffc0082dbef8 <__arm64_sys_futex+0x308>
ffffffc0082dbd90: b00153f9     	adrp	x25, 0xffffffc00ad58000 <irqs_resend+0x240>
ffffffc0082dbd94: b00153fa     	adrp	x26, 0xffffffc00ad58000 <irqs_resend+0x240>
ffffffc0082dbd98: f000ba3b     	adrp	x27, 0xffffffc009a22000 <sdhci_start_signal_voltage_switch.cfi_jt>
ffffffc0082dbd9c: 91150339     	add	x25, x25, #0x540
ffffffc0082dbda0: 9115235a     	add	x26, x26, #0x548
ffffffc0082dbda4: 9127237b     	add	x27, x27, #0x9c8
ffffffc0082dbda8: 88dfff33     	ldar	w19, [x25]
ffffffc0082dbdac: 36000093     	tbz	w19, #0x0, 0xffffffc0082dbdbc <__arm64_sys_futex+0x1cc>
ffffffc0082dbdb0: d503203f     	yield
ffffffc0082dbdb4: 88dfff33     	ldar	w19, [x25]
ffffffc0082dbdb8: 3707ffd3     	tbnz	w19, #0x0, 0xffffffc0082dbdb0 <__arm64_sys_futex+0x1c0>
ffffffc0082dbdbc: d50339bf     	dmb	ishld
ffffffc0082dbdc0: f940175c     	ldr	x28, [x26, #0x28]
ffffffc0082dbdc4: c8dfff58     	ldar	x24, [x26]
ffffffc0082dbdc8: f9400308     	ldr	x8, [x24]
ffffffc0082dbdcc: cb1b0109     	sub	x9, x8, x27
ffffffc0082dbdd0: 93c90d29     	ror	x9, x9, #0x3
ffffffc0082dbdd4: f100193f     	cmp	x9, #0x6
ffffffc0082dbdd8: 54000162     	b.hs	0xffffffc0082dbe04 <__arm64_sys_futex+0x214>
ffffffc0082dbddc: aa1803e0     	mov	x0, x24
ffffffc0082dbde0: d63f0100     	blr	x8
ffffffc0082dbde4: a9412f2c     	ldp	x12, x11, [x25, #0x10]
ffffffc0082dbde8: f9401729     	ldr	x9, [x25, #0x28]
ffffffc0082dbdec: 2944232a     	ldp	w10, w8, [x25, #0x20]
ffffffc0082dbdf0: d50339bf     	dmb	ishld
ffffffc0082dbdf4: 88dfff2d     	ldar	w13, [x25]
ffffffc0082dbdf8: 6b1301bf     	cmp	w13, w19
ffffffc0082dbdfc: 54fffd61     	b.ne	0xffffffc0082dbda8 <__arm64_sys_futex+0x1b8>
ffffffc0082dbe00: 1400000b     	b	0xffffffc0082dbe2c <__arm64_sys_futex+0x23c>
ffffffc0082dbe04: d28f4d80     	mov	x0, #0x7a6c     // =31340
ffffffc0082dbe08: f2a610e0     	movk	x0, #0x3087, lsl #16
ffffffc0082dbe0c: f2d7cf60     	movk	x0, #0xbe7b, lsl #32
ffffffc0082dbe10: f2fa2f60     	movk	x0, #0xd17b, lsl #48
ffffffc0082dbe14: aa0803e1     	mov	x1, x8
ffffffc0082dbe18: aa1f03e2     	mov	x2, xzr
ffffffc0082dbe1c: f81d03a8     	stur	x8, [x29, #-0x30]
ffffffc0082dbe20: 9404dd1d     	bl	0xffffffc008413294 <__cfi_slowpath>
ffffffc0082dbe24: f85d03a8     	ldur	x8, [x29, #-0x30]
ffffffc0082dbe28: 17ffffed     	b	0xffffffc0082dbddc <__arm64_sys_futex+0x1ec>
ffffffc0082dbe2c: cb0b000b     	sub	x11, x0, x11
ffffffc0082dbe30: 8a0c016b     	and	x11, x11, x12
ffffffc0082dbe34: a97db3b3     	ldp	x19, x12, [x29, #-0x28]
ffffffc0082dbe38: 9b0a2569     	madd	x9, x11, x10, x9
ffffffc0082dbe3c: 9ac82528     	lsr	x8, x9, x8
ffffffc0082dbe40: 8b1c0108     	add	x8, x8, x28
ffffffc0082dbe44: 8b080189     	add	x9, x12, x8
ffffffc0082dbe48: eb08013f     	cmp	x9, x8
ffffffc0082dbe4c: fa40a928     	ccmp	x9, #0x0, #0x8, ge
ffffffc0082dbe50: 92f0000a     	mov	x10, #0x7fffffffffffffff // =9223372036854775807
ffffffc0082dbe54: fa4ca128     	ccmp	x9, x12, #0x8, ge
ffffffc0082dbe58: 9a89b148     	csel	x8, x10, x9, lt
ffffffc0082dbe5c: 2a1f03e5     	mov	w5, wzr
ffffffc0082dbe60: f81e03a8     	stur	x8, [x29, #-0x20]
ffffffc0082dbe64: d10083a3     	sub	x3, x29, #0x20
ffffffc0082dbe68: 17ffff88     	b	0xffffffc0082dbc88 <__arm64_sys_futex+0x98>
ffffffc0082dbe6c: 90015a2b     	adrp	x11, 0xffffffc00ae1f000 <rsc_lock_boost_trace+0xe8>
ffffffc0082dbe70: b941216c     	ldr	w12, [x11, #0x120]
ffffffc0082dbe74: 9136e10d     	add	x13, x8, #0xdb8
ffffffc0082dbe78: 911e4102     	add	x2, x8, #0x790
ffffffc0082dbe7c: b0010240     	adrp	x0, 0xffffffc00a324000 <hci_reset_dev.hw_err+0x1fc63>
ffffffc0082dbe80: 1100058c     	add	w12, w12, #0x1
ffffffc0082dbe84: b901216c     	str	w12, [x11, #0x120]
ffffffc0082dbe88: f943c10b     	ldr	x11, [x8, #0x780]
ffffffc0082dbe8c: f943050c     	ldr	x12, [x8, #0x608]
ffffffc0082dbe90: b945c903     	ldr	w3, [x8, #0x5c8]
ffffffc0082dbe94: 3975b506     	ldrb	w6, [x8, #0xd6d]
ffffffc0082dbe98: b9400561     	ldr	w1, [x11, #0x4]
ffffffc0082dbe9c: b945c985     	ldr	w5, [x12, #0x5c8]
ffffffc0082dbea0: c8dffda7     	ldar	x7, [x13]
ffffffc0082dbea4: f940010b     	ldr	x11, [x8]
ffffffc0082dbea8: 3975b908     	ldrb	w8, [x8, #0xd6e]
ffffffc0082dbeac: 911e4184     	add	x4, x12, #0x790
ffffffc0082dbeb0: 9001060c     	adrp	x12, 0xffffffc00a39b000 <f_midi_shortname+0x456d>
ffffffc0082dbeb4: f001024d     	adrp	x13, 0xffffffc00a326000 <hci_reset_dev.hw_err+0x21c63>
ffffffc0082dbeb8: 910a658c     	add	x12, x12, #0x299
ffffffc0082dbebc: 91068dad     	add	x13, x13, #0x1a3
ffffffc0082dbec0: f26a017f     	tst	x11, #0x400000
ffffffc0082dbec4: 9a8c01ab     	csel	x11, x13, x12, eq
ffffffc0082dbec8: 913ad800     	add	x0, x0, #0xeb6
ffffffc0082dbecc: a9042be9     	stp	x9, x10, [sp, #0x40]
ffffffc0082dbed0: b9003bf7     	str	w23, [sp, #0x38]
ffffffc0082dbed4: b90033ff     	str	wzr, [sp, #0x30]
ffffffc0082dbed8: b9002bf6     	str	w22, [sp, #0x28]
ffffffc0082dbedc: b90023f4     	str	w20, [sp, #0x20]
ffffffc0082dbee0: a90157f3     	stp	x19, x21, [sp, #0x10]
ffffffc0082dbee4: b9000be8     	str	w8, [sp, #0x8]
ffffffc0082dbee8: f90003eb     	str	x11, [sp]
ffffffc0082dbeec: 97fd5a47     	bl	0xffffffc008232808 <printk>
ffffffc0082dbef0: 928002a0     	mov	x0, #-0x16      // =-22
ffffffc0082dbef4: 17ffff6b     	b	0xffffffc0082dbca0 <__arm64_sys_futex+0xb0>
ffffffc0082dbef8: d4210000     	brk	#0x800
ffffffc0082dbefc: 17ffffa5     	b	0xffffffc0082dbd90 <__arm64_sys_futex+0x1a0>
ffffffc0082dbf00: a943210a     	ldp	x10, x8, [x8, #0x30]
ffffffc0082dbf04: 9b0b2148     	madd	x8, x10, x11, x8
ffffffc0082dbf08: eb0c015f     	cmp	x10, x12
ffffffc0082dbf0c: 92f0000a     	mov	x10, #0x7fffffffffffffff // =9223372036854775807
ffffffc0082dbf10: 9a88c148     	csel	x8, x10, x8, gt
ffffffc0082dbf14: eb080128     	subs	x8, x9, x8
ffffffc0082dbf18: 9a88b3e9     	csel	x9, xzr, x8, lt
ffffffc0082dbf1c: 17ffff96     	b	0xffffffc0082dbd74 <__arm64_sys_futex+0x184>
ffffffc0082dbf20: 9455754d     	bl	0xffffffc009839454 <__stack_chk_fail>
ffffffc0082dbf24: b8bfc333     	ldapr	w19, [x25]
ffffffc0082dbf28: b8bfc333     	ldapr	w19, [x25]
ffffffc0082dbf2c: f8bfc358     	ldapr	x24, [x26]
ffffffc0082dbf30: b8bfc32d     	ldapr	w13, [x25]
ffffffc0082dbf34: f8bfc1a7     	ldapr	x7, [x13]
