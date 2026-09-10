
C:\Users\QingJ\Desktop\root\work\boot_out\output.elf:	file format elf64-littleaarch64

Disassembly of section .kernel:

ffffffc00860357c <__arm64_sys_select>:
ffffffc00860357c: d503233f     	paciasp
ffffffc008603580: d10203ff     	sub	sp, sp, #0x80
ffffffc008603584: f800865e     	str	x30, [x18], #0x8
ffffffc008603588: a9037bfd     	stp	x29, x30, [sp, #0x30]
ffffffc00860358c: a90467fa     	stp	x26, x25, [sp, #0x40]
ffffffc008603590: a9055ff8     	stp	x24, x23, [sp, #0x50]
ffffffc008603594: a90657f6     	stp	x22, x21, [sp, #0x60]
ffffffc008603598: a9074ff4     	stp	x20, x19, [sp, #0x70]
ffffffc00860359c: 9100c3fd     	add	x29, sp, #0x30
ffffffc0086035a0: 9000fea8     	adrp	x8, 0xffffffc00a5d7000 <idle_sched_class+0x20>
ffffffc0086035a4: f9426908     	ldr	x8, [x8, #0x4d0]
ffffffc0086035a8: f81f83a8     	stur	x8, [x29, #-0x8]
ffffffc0086035ac: b9400014     	ldr	w20, [x0]
ffffffc0086035b0: a940d815     	ldp	x21, x22, [x0, #0x8]
ffffffc0086035b4: a941cc17     	ldp	x23, x19, [x0, #0x18]
ffffffc0086035b8: a9017fff     	stp	xzr, xzr, [sp, #0x10]
ffffffc0086035bc: a9007fff     	stp	xzr, xzr, [sp]
ffffffc0086035c0: b4000113     	cbz	x19, 0xffffffc0086035e0 <__arm64_sys_select+0x64>
ffffffc0086035c4: 910003e0     	mov	x0, sp
ffffffc0086035c8: 52800202     	mov	w2, #0x10       // =16
ffffffc0086035cc: aa1303e1     	mov	x1, x19
ffffffc0086035d0: 94000059     	bl	0xffffffc008603734 <_copy_from_user.17761>
ffffffc0086035d4: b40000a0     	cbz	x0, 0xffffffc0086035e8 <__arm64_sys_select+0x6c>
ffffffc0086035d8: 928001a0     	mov	x0, #-0xe       // =-14
ffffffc0086035dc: 14000047     	b	0xffffffc0086036f8 <__arm64_sys_select+0x17c>
ffffffc0086035e0: aa1f03e4     	mov	x4, xzr
ffffffc0086035e4: 1400003a     	b	0xffffffc0086036cc <__arm64_sys_select+0x150>
ffffffc0086035e8: a94023ea     	ldp	x10, x8, [sp]
ffffffc0086035ec: d2869b69     	mov	x9, #0x34db     // =13531
ffffffc0086035f0: f2baf6c9     	movk	x9, #0xd7b6, lsl #16
ffffffc0086035f4: f2dbd049     	movk	x9, #0xde82, lsl #32
ffffffc0086035f8: f2e86369     	movk	x9, #0x431b, lsl #48
ffffffc0086035fc: 9b497d09     	smulh	x9, x8, x9
ffffffc008603600: 9352fd2b     	asr	x11, x9, #18
ffffffc008603604: 8b49fd69     	add	x9, x11, x9, lsr #63
ffffffc008603608: ab0a0138     	adds	x24, x9, x10
ffffffc00860360c: 928002a0     	mov	x0, #-0x16      // =-22
ffffffc008603610: 54000744     	b.mi	0xffffffc0086036f8 <__arm64_sys_select+0x17c>
ffffffc008603614: 928847ea     	mov	x10, #-0x4240   // =-16960
ffffffc008603618: 52993ff9     	mov	w25, #0xc9ff    // =51711
ffffffc00860361c: f2bffe0a     	movk	x10, #0xfff0, lsl #16
ffffffc008603620: 72a77359     	movk	w25, #0x3b9a, lsl #16
ffffffc008603624: 52807d0b     	mov	w11, #0x3e8     // =1000
ffffffc008603628: 9b0a2128     	madd	x8, x9, x10, x8
ffffffc00860362c: 9b0b7d1a     	mul	x26, x8, x11
ffffffc008603630: 91000728     	add	x8, x25, #0x1
ffffffc008603634: eb08035f     	cmp	x26, x8
ffffffc008603638: 54000602     	b.hs	0xffffffc0086036f8 <__arm64_sys_select+0x17c>
ffffffc00860363c: aa180348     	orr	x8, x26, x24
ffffffc008603640: b4000428     	cbz	x8, 0xffffffc0086036c4 <__arm64_sys_select+0x148>
ffffffc008603644: 910043e0     	add	x0, sp, #0x10
ffffffc008603648: 97f28da4     	bl	0xffffffc0082a6cd8 <ktime_get_ts64>
ffffffc00860364c: a94127ea     	ldp	x10, x9, [sp, #0x10]
ffffffc008603650: 8b090349     	add	x9, x26, x9
ffffffc008603654: 8b0a0308     	add	x8, x24, x10
ffffffc008603658: eb19013f     	cmp	x9, x25
ffffffc00860365c: f81f03a9     	stur	x9, [x29, #-0x10]
ffffffc008603660: 5400010d     	b.le	0xffffffc008603680 <__arm64_sys_select+0x104>
ffffffc008603664: 92993feb     	mov	x11, #-0xca00   // =-51712
ffffffc008603668: f2b88cab     	movk	x11, #0xc465, lsl #16
ffffffc00860366c: 8b0b0129     	add	x9, x9, x11
ffffffc008603670: eb19013f     	cmp	x9, x25
ffffffc008603674: 91000508     	add	x8, x8, #0x1
ffffffc008603678: f81f03a9     	stur	x9, [x29, #-0x10]
ffffffc00860367c: 54ffff8c     	b.gt	0xffffffc00860366c <__arm64_sys_select+0xf0>
ffffffc008603680: b6f800c9     	tbz	x9, #0x3f, 0xffffffc008603698 <__arm64_sys_select+0x11c>
ffffffc008603684: 8b090329     	add	x9, x25, x9
ffffffc008603688: 91000529     	add	x9, x9, #0x1
ffffffc00860368c: d1000508     	sub	x8, x8, #0x1
ffffffc008603690: f81f03a9     	stur	x9, [x29, #-0x10]
ffffffc008603694: b7ffff89     	tbnz	x9, #0x3f, 0xffffffc008603684 <__arm64_sys_select+0x108>
ffffffc008603698: eb0a011f     	cmp	x8, x10
ffffffc00860369c: 1a9fa7eb     	cset	w11, lt
ffffffc0086036a0: eb18011f     	cmp	x8, x24
ffffffc0086036a4: 1a9fa7ec     	cset	w12, lt
ffffffc0086036a8: 2a0c016b     	orr	w11, w11, w12
ffffffc0086036ac: 92f0000a     	mov	x10, #0x7fffffffffffffff // =9223372036854775807
ffffffc0086036b0: 7100017f     	cmp	w11, #0x0
ffffffc0086036b4: 9a881148     	csel	x8, x10, x8, ne
ffffffc0086036b8: 9a8913e9     	csel	x9, xzr, x9, ne
ffffffc0086036bc: a90127e8     	stp	x8, x9, [sp, #0x10]
ffffffc0086036c0: 14000002     	b	0xffffffc0086036c8 <__arm64_sys_select+0x14c>
ffffffc0086036c4: a9017fff     	stp	xzr, xzr, [sp, #0x10]
ffffffc0086036c8: 910043e4     	add	x4, sp, #0x10
ffffffc0086036cc: 2a1403e0     	mov	w0, w20
ffffffc0086036d0: aa1503e1     	mov	x1, x21
ffffffc0086036d4: aa1603e2     	mov	x2, x22
ffffffc0086036d8: aa1703e3     	mov	x3, x23
ffffffc0086036dc: 94000087     	bl	0xffffffc0086038f8 <core_sys_select>
ffffffc0086036e0: 2a0003e3     	mov	w3, w0
ffffffc0086036e4: 910043e0     	add	x0, sp, #0x10
ffffffc0086036e8: aa1303e1     	mov	x1, x19
ffffffc0086036ec: 2a1f03e2     	mov	w2, wzr
ffffffc0086036f0: 94000164     	bl	0xffffffc008603c80 <poll_select_finish>
ffffffc0086036f4: 93407c00     	sxtw	x0, w0
ffffffc0086036f8: 9000fea9     	adrp	x9, 0xffffffc00a5d7000 <idle_sched_class+0x20>
ffffffc0086036fc: f85f83a8     	ldur	x8, [x29, #-0x8]
ffffffc008603700: f9426929     	ldr	x9, [x9, #0x4d0]
ffffffc008603704: eb08013f     	cmp	x9, x8
ffffffc008603708: 54000141     	b.ne	0xffffffc008603730 <__arm64_sys_select+0x1b4>
ffffffc00860370c: a9437bfd     	ldp	x29, x30, [sp, #0x30]
ffffffc008603710: a9474ff4     	ldp	x20, x19, [sp, #0x70]
ffffffc008603714: a94657f6     	ldp	x22, x21, [sp, #0x60]
ffffffc008603718: a9455ff8     	ldp	x24, x23, [sp, #0x50]
ffffffc00860371c: a94467fa     	ldp	x26, x25, [sp, #0x40]
ffffffc008603720: f85f8e5e     	ldr	x30, [x18, #-0x8]!
ffffffc008603724: 910203ff     	add	sp, sp, #0x80
ffffffc008603728: d50323bf     	autiasp
ffffffc00860372c: d65f03c0     	ret
ffffffc008603730: 9448d749     	bl	0xffffffc009839454 <__stack_chk_fail>
