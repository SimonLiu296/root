
C:\Users\QingJ\Desktop\root\work\boot_out\output.elf:	file format elf64-littleaarch64

Disassembly of section .kernel:

ffffffc0086038f8 <core_sys_select>:
ffffffc0086038f8: d503233f     	paciasp
ffffffc0086038fc: d10703ff     	sub	sp, sp, #0x1c0
ffffffc008603900: f800865e     	str	x30, [x18], #0x8
ffffffc008603904: a9167bfd     	stp	x29, x30, [sp, #0x160]
ffffffc008603908: a9176ffc     	stp	x28, x27, [sp, #0x170]
ffffffc00860390c: a91867fa     	stp	x26, x25, [sp, #0x180]
ffffffc008603910: a9195ff8     	stp	x24, x23, [sp, #0x190]
ffffffc008603914: a91a57f6     	stp	x22, x21, [sp, #0x1a0]
ffffffc008603918: a91b4ff4     	stp	x20, x19, [sp, #0x1b0]
ffffffc00860391c: 910583fd     	add	x29, sp, #0x160
ffffffc008603920: 9000fea8     	adrp	x8, 0xffffffc00a5d7000 <idle_sched_class+0x20>
ffffffc008603924: f9426908     	ldr	x8, [x8, #0x4d0]
ffffffc008603928: f9000fe2     	str	x2, [sp, #0x18]
ffffffc00860392c: f81f03a8     	stur	x8, [x29, #-0x10]
ffffffc008603930: a9047fff     	stp	xzr, xzr, [sp, #0x40]
ffffffc008603934: a9037fff     	stp	xzr, xzr, [sp, #0x30]
ffffffc008603938: a9027fff     	stp	xzr, xzr, [sp, #0x20]
ffffffc00860393c: a9147fff     	stp	xzr, xzr, [sp, #0x140]
ffffffc008603940: a9137fff     	stp	xzr, xzr, [sp, #0x130]
ffffffc008603944: a9127fff     	stp	xzr, xzr, [sp, #0x120]
ffffffc008603948: a9117fff     	stp	xzr, xzr, [sp, #0x110]
ffffffc00860394c: a9107fff     	stp	xzr, xzr, [sp, #0x100]
ffffffc008603950: a90f7fff     	stp	xzr, xzr, [sp, #0xf0]
ffffffc008603954: a90e7fff     	stp	xzr, xzr, [sp, #0xe0]
ffffffc008603958: a90d7fff     	stp	xzr, xzr, [sp, #0xd0]
ffffffc00860395c: a90c7fff     	stp	xzr, xzr, [sp, #0xc0]
ffffffc008603960: a90b7fff     	stp	xzr, xzr, [sp, #0xb0]
ffffffc008603964: a90a7fff     	stp	xzr, xzr, [sp, #0xa0]
ffffffc008603968: a9097fff     	stp	xzr, xzr, [sp, #0x90]
ffffffc00860396c: a9087fff     	stp	xzr, xzr, [sp, #0x80]
ffffffc008603970: a9077fff     	stp	xzr, xzr, [sp, #0x70]
ffffffc008603974: a9067fff     	stp	xzr, xzr, [sp, #0x60]
ffffffc008603978: a9057fff     	stp	xzr, xzr, [sp, #0x50]
ffffffc00860397c: 37f804a0     	tbnz	w0, #0x1f, 0xffffffc008603a10 <core_sys_select+0x118>
ffffffc008603980: d5384118     	mrs	x24, SP_EL0
ffffffc008603984: b9444b08     	ldr	w8, [x24, #0x448]
ffffffc008603988: f9000be3     	str	x3, [sp, #0x10]
ffffffc00860398c: aa0403f7     	mov	x23, x4
ffffffc008603990: aa0103f6     	mov	x22, x1
ffffffc008603994: 11000508     	add	w8, w8, #0x1
ffffffc008603998: b9044b08     	str	w8, [x24, #0x448]
ffffffc00860399c: f943e308     	ldr	x8, [x24, #0x7c0]
ffffffc0086039a0: 2a0003f3     	mov	w19, w0
ffffffc0086039a4: 91008108     	add	x8, x8, #0x20
ffffffc0086039a8: c8dffd08     	ldar	x8, [x8]
ffffffc0086039ac: b9444b09     	ldr	w9, [x24, #0x448]
ffffffc0086039b0: b9400114     	ldr	w20, [x8]
ffffffc0086039b4: 71000528     	subs	w8, w9, #0x1
ffffffc0086039b8: b9044b08     	str	w8, [x24, #0x448]
ffffffc0086039bc: 54000081     	b.ne	0xffffffc0086039cc <core_sys_select+0xd4>
ffffffc0086039c0: 91113308     	add	x8, x24, #0x44c
ffffffc0086039c4: 88dffd08     	ldar	w8, [x8]
ffffffc0086039c8: 35001488     	cbnz	w8, 0xffffffc008603c58 <core_sys_select+0x360>
ffffffc0086039cc: 6b13029f     	cmp	w20, w19
ffffffc0086039d0: 1a93b288     	csel	w8, w20, w19, lt
ffffffc0086039d4: 93407d19     	sxtw	x25, w8
ffffffc0086039d8: 9100ff28     	add	x8, x25, #0x3f
ffffffc0086039dc: d343fd08     	lsr	x8, x8, #3
ffffffc0086039e0: 927de51c     	and	x28, x8, #0x1ffffffffffffff8
ffffffc0086039e4: f100af9f     	cmp	x28, #0x2b
ffffffc0086039e8: 54000183     	b.lo	0xffffffc008603a18 <core_sys_select+0x120>
ffffffc0086039ec: 8b1c0788     	add	x8, x28, x28, lsl #1
ffffffc0086039f0: d37ff900     	lsl	x0, x8, #1
ffffffc0086039f4: 52819801     	mov	w1, #0xcc0      // =3264
ffffffc0086039f8: 12800002     	mov	w2, #-0x1       // =-1
ffffffc0086039fc: 97fb66ab     	bl	0xffffffc0084dd4a8 <kvmalloc_node>
ffffffc008603a00: aa0003f5     	mov	x21, x0
ffffffc008603a04: b50000c0     	cbnz	x0, 0xffffffc008603a1c <core_sys_select+0x124>
ffffffc008603a08: 1280017c     	mov	w28, #-0xc      // =-12
ffffffc008603a0c: 1400007f     	b	0xffffffc008603c08 <core_sys_select+0x310>
ffffffc008603a10: 128002bc     	mov	w28, #-0x16     // =-22
ffffffc008603a14: 1400007d     	b	0xffffffc008603c08 <core_sys_select+0x310>
ffffffc008603a18: 910143f5     	add	x21, sp, #0x50
ffffffc008603a1c: d37ffb88     	lsl	x8, x28, #1
ffffffc008603a20: d37ef789     	lsl	x9, x28, #2
ffffffc008603a24: 8b0802b3     	add	x19, x21, x8
ffffffc008603a28: 8b1c0108     	add	x8, x8, x28
ffffffc008603a2c: 8b0902bb     	add	x27, x21, x9
ffffffc008603a30: 8b1c0129     	add	x9, x9, x28
ffffffc008603a34: f90007f7     	str	x23, [sp, #0x8]
ffffffc008603a38: 8b1c02b4     	add	x20, x21, x28
ffffffc008603a3c: 8b0802b7     	add	x23, x21, x8
ffffffc008603a40: 8b0902a8     	add	x8, x21, x9
ffffffc008603a44: d35fff9a     	lsr	x26, x28, #31
ffffffc008603a48: a90253f5     	stp	x21, x20, [sp, #0x20]
ffffffc008603a4c: a9035ff3     	stp	x19, x23, [sp, #0x30]
ffffffc008603a50: a90423fb     	stp	x27, x8, [sp, #0x40]
ffffffc008603a54: f90003e8     	str	x8, [sp]
ffffffc008603a58: b4000496     	cbz	x22, 0xffffffc008603ae8 <core_sys_select+0x1f0>
ffffffc008603a5c: b5000fba     	cbnz	x26, 0xffffffc008603c50 <core_sys_select+0x358>
ffffffc008603a60: aa1503e0     	mov	x0, x21
ffffffc008603a64: aa1c03e1     	mov	x1, x28
ffffffc008603a68: 2a1f03e2     	mov	w2, wzr
ffffffc008603a6c: 97ff1b94     	bl	0xffffffc0085ca8bc <__check_object_size>
ffffffc008603a70: aa1503e0     	mov	x0, x21
ffffffc008603a74: aa1603e1     	mov	x1, x22
ffffffc008603a78: aa1c03e2     	mov	x2, x28
ffffffc008603a7c: 97ffff2e     	bl	0xffffffc008603734 <_copy_from_user.17761>
ffffffc008603a80: b5000a20     	cbnz	x0, 0xffffffc008603bc4 <core_sys_select+0x2cc>
ffffffc008603a84: f9400fe8     	ldr	x8, [sp, #0x18]
ffffffc008603a88: b40003c8     	cbz	x8, 0xffffffc008603b00 <core_sys_select+0x208>
ffffffc008603a8c: b5000eda     	cbnz	x26, 0xffffffc008603c64 <core_sys_select+0x36c>
ffffffc008603a90: aa1403e0     	mov	x0, x20
ffffffc008603a94: aa1c03e1     	mov	x1, x28
ffffffc008603a98: 2a1f03e2     	mov	w2, wzr
ffffffc008603a9c: 97ff1b88     	bl	0xffffffc0085ca8bc <__check_object_size>
ffffffc008603aa0: f9400fe1     	ldr	x1, [sp, #0x18]
ffffffc008603aa4: aa1403e0     	mov	x0, x20
ffffffc008603aa8: aa1c03e2     	mov	x2, x28
ffffffc008603aac: 97ffff22     	bl	0xffffffc008603734 <_copy_from_user.17761>
ffffffc008603ab0: b50008a0     	cbnz	x0, 0xffffffc008603bc4 <core_sys_select+0x2cc>
ffffffc008603ab4: f9400bf4     	ldr	x20, [sp, #0x10]
ffffffc008603ab8: b4000314     	cbz	x20, 0xffffffc008603b18 <core_sys_select+0x220>
ffffffc008603abc: b5000d9a     	cbnz	x26, 0xffffffc008603c6c <core_sys_select+0x374>
ffffffc008603ac0: aa1303e0     	mov	x0, x19
ffffffc008603ac4: aa1c03e1     	mov	x1, x28
ffffffc008603ac8: 2a1f03e2     	mov	w2, wzr
ffffffc008603acc: 97ff1b7c     	bl	0xffffffc0085ca8bc <__check_object_size>
ffffffc008603ad0: aa1303e0     	mov	x0, x19
ffffffc008603ad4: aa1403e1     	mov	x1, x20
ffffffc008603ad8: aa1c03e2     	mov	x2, x28
ffffffc008603adc: 97ffff16     	bl	0xffffffc008603734 <_copy_from_user.17761>
ffffffc008603ae0: b5000720     	cbnz	x0, 0xffffffc008603bc4 <core_sys_select+0x2cc>
ffffffc008603ae4: 14000011     	b	0xffffffc008603b28 <core_sys_select+0x230>
ffffffc008603ae8: aa1503e0     	mov	x0, x21
ffffffc008603aec: 2a1f03e1     	mov	w1, wzr
ffffffc008603af0: aa1c03e2     	mov	x2, x28
ffffffc008603af4: 97e86fa3     	bl	0xffffffc00801f980 <memset>
ffffffc008603af8: f9400fe8     	ldr	x8, [sp, #0x18]
ffffffc008603afc: b5fffc88     	cbnz	x8, 0xffffffc008603a8c <core_sys_select+0x194>
ffffffc008603b00: aa1403e0     	mov	x0, x20
ffffffc008603b04: 2a1f03e1     	mov	w1, wzr
ffffffc008603b08: aa1c03e2     	mov	x2, x28
ffffffc008603b0c: 97e86f9d     	bl	0xffffffc00801f980 <memset>
ffffffc008603b10: f9400bf4     	ldr	x20, [sp, #0x10]
ffffffc008603b14: b5fffd54     	cbnz	x20, 0xffffffc008603abc <core_sys_select+0x1c4>
ffffffc008603b18: aa1303e0     	mov	x0, x19
ffffffc008603b1c: 2a1f03e1     	mov	w1, wzr
ffffffc008603b20: aa1c03e2     	mov	x2, x28
ffffffc008603b24: 97e86f97     	bl	0xffffffc00801f980 <memset>
ffffffc008603b28: aa1703e0     	mov	x0, x23
ffffffc008603b2c: 2a1f03e1     	mov	w1, wzr
ffffffc008603b30: aa1c03e2     	mov	x2, x28
ffffffc008603b34: 97e86f93     	bl	0xffffffc00801f980 <memset>
ffffffc008603b38: aa1b03e0     	mov	x0, x27
ffffffc008603b3c: 2a1f03e1     	mov	w1, wzr
ffffffc008603b40: aa1c03e2     	mov	x2, x28
ffffffc008603b44: 97e86f8f     	bl	0xffffffc00801f980 <memset>
ffffffc008603b48: f94003f3     	ldr	x19, [sp]
ffffffc008603b4c: 2a1f03e1     	mov	w1, wzr
ffffffc008603b50: aa1c03e2     	mov	x2, x28
ffffffc008603b54: aa1303e0     	mov	x0, x19
ffffffc008603b58: 97e86f8a     	bl	0xffffffc00801f980 <memset>
ffffffc008603b5c: f94007e2     	ldr	x2, [sp, #0x8]
ffffffc008603b60: 910083e1     	add	x1, sp, #0x20
ffffffc008603b64: 2a1903e0     	mov	w0, w25
ffffffc008603b68: 94000138     	bl	0xffffffc008604048 <do_select>
ffffffc008603b6c: 2a0003fc     	mov	w28, w0
ffffffc008603b70: 37f802c0     	tbnz	w0, #0x1f, 0xffffffc008603bc8 <core_sys_select+0x2d0>
ffffffc008603b74: 350000bc     	cbnz	w28, 0xffffffc008603b88 <core_sys_select+0x290>
ffffffc008603b78: f9400308     	ldr	x8, [x24]
ffffffc008603b7c: 37380668     	tbnz	w8, #0x7, 0xffffffc008603c48 <core_sys_select+0x350>
ffffffc008603b80: f9400308     	ldr	x8, [x24]
ffffffc008603b84: 37000628     	tbnz	w8, #0x0, 0xffffffc008603c48 <core_sys_select+0x350>
ffffffc008603b88: aa1903e0     	mov	x0, x25
ffffffc008603b8c: aa1603e1     	mov	x1, x22
ffffffc008603b90: aa1703e2     	mov	x2, x23
ffffffc008603b94: 940003a6     	bl	0xffffffc008604a2c <set_fd_set>
ffffffc008603b98: b5000160     	cbnz	x0, 0xffffffc008603bc4 <core_sys_select+0x2cc>
ffffffc008603b9c: f9400fe1     	ldr	x1, [sp, #0x18]
ffffffc008603ba0: aa1903e0     	mov	x0, x25
ffffffc008603ba4: aa1b03e2     	mov	x2, x27
ffffffc008603ba8: 940003a1     	bl	0xffffffc008604a2c <set_fd_set>
ffffffc008603bac: b50000c0     	cbnz	x0, 0xffffffc008603bc4 <core_sys_select+0x2cc>
ffffffc008603bb0: aa1903e0     	mov	x0, x25
ffffffc008603bb4: aa1403e1     	mov	x1, x20
ffffffc008603bb8: aa1303e2     	mov	x2, x19
ffffffc008603bbc: 9400039c     	bl	0xffffffc008604a2c <set_fd_set>
ffffffc008603bc0: b4000040     	cbz	x0, 0xffffffc008603bc8 <core_sys_select+0x2d0>
ffffffc008603bc4: 128001bc     	mov	w28, #-0xe      // =-14
ffffffc008603bc8: 910143e8     	add	x8, sp, #0x50
ffffffc008603bcc: eb0802bf     	cmp	x21, x8
ffffffc008603bd0: 540001c0     	b.eq	0xffffffc008603c08 <core_sys_select+0x310>
ffffffc008603bd4: b25a67e8     	mov	x8, #-0x4000000000 // =-274877906944
ffffffc008603bd8: f2a10008     	movk	x8, #0x800, lsl #16
ffffffc008603bdc: eb0802bf     	cmp	x21, x8
ffffffc008603be0: 54000103     	b.lo	0xffffffc008603c00 <core_sys_select+0x308>
ffffffc008603be4: 92a80028     	mov	x8, #-0x40010001 // =-1073807361
ffffffc008603be8: f2dfffc8     	movk	x8, #0xfffe, lsl #32
ffffffc008603bec: eb0802bf     	cmp	x21, x8
ffffffc008603bf0: 54000088     	b.hi	0xffffffc008603c00 <core_sys_select+0x308>
ffffffc008603bf4: aa1503e0     	mov	x0, x21
ffffffc008603bf8: 97fce584     	bl	0xffffffc00853d208 <vfree>
ffffffc008603bfc: 14000003     	b	0xffffffc008603c08 <core_sys_select+0x310>
ffffffc008603c00: aa1503e0     	mov	x0, x21
ffffffc008603c04: 97fdcac3     	bl	0xffffffc008576710 <kfree>
ffffffc008603c08: 9000fea9     	adrp	x9, 0xffffffc00a5d7000 <idle_sched_class+0x20>
ffffffc008603c0c: f85f03a8     	ldur	x8, [x29, #-0x10]
ffffffc008603c10: f9426929     	ldr	x9, [x9, #0x4d0]
ffffffc008603c14: eb08013f     	cmp	x9, x8
ffffffc008603c18: 540002e1     	b.ne	0xffffffc008603c74 <core_sys_select+0x37c>
ffffffc008603c1c: a9567bfd     	ldp	x29, x30, [sp, #0x160]
ffffffc008603c20: 2a1c03e0     	mov	w0, w28
ffffffc008603c24: a95b4ff4     	ldp	x20, x19, [sp, #0x1b0]
ffffffc008603c28: a95a57f6     	ldp	x22, x21, [sp, #0x1a0]
ffffffc008603c2c: a9595ff8     	ldp	x24, x23, [sp, #0x190]
ffffffc008603c30: a95867fa     	ldp	x26, x25, [sp, #0x180]
ffffffc008603c34: a9576ffc     	ldp	x28, x27, [sp, #0x170]
ffffffc008603c38: f85f8e5e     	ldr	x30, [x18, #-0x8]!
ffffffc008603c3c: 910703ff     	add	sp, sp, #0x1c0
ffffffc008603c40: d50323bf     	autiasp
ffffffc008603c44: d65f03c0     	ret
ffffffc008603c48: 1280403c     	mov	w28, #-0x202    // =-514
ffffffc008603c4c: 17ffffdf     	b	0xffffffc008603bc8 <core_sys_select+0x2d0>
ffffffc008603c50: d4210000     	brk	#0x800
ffffffc008603c54: 17ffffdc     	b	0xffffffc008603bc4 <core_sys_select+0x2cc>
ffffffc008603c58: aa1803e0     	mov	x0, x24
ffffffc008603c5c: 97f1ade5     	bl	0xffffffc00826f3f0 <rcu_read_unlock_special>
ffffffc008603c60: 17ffff5b     	b	0xffffffc0086039cc <core_sys_select+0xd4>
ffffffc008603c64: d4210000     	brk	#0x800
ffffffc008603c68: 17ffffd7     	b	0xffffffc008603bc4 <core_sys_select+0x2cc>
ffffffc008603c6c: d4210000     	brk	#0x800
ffffffc008603c70: 17ffffd5     	b	0xffffffc008603bc4 <core_sys_select+0x2cc>
ffffffc008603c74: 9448d5f8     	bl	0xffffffc009839454 <__stack_chk_fail>
ffffffc008603c78: f8bfc108     	ldapr	x8, [x8]
ffffffc008603c7c: b8bfc108     	ldapr	w8, [x8]
