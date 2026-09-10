
C:\Users\QingJ\Desktop\root\work\boot_out\output.elf:	file format elf64-littleaarch64

Disassembly of section .kernel:

ffffffc0082d3d64 <futex_wait_requeue_pi>:
ffffffc0082d3d64: d503233f     	paciasp
ffffffc0082d3d68: d106c3ff     	sub	sp, sp, #0x1b0
ffffffc0082d3d6c: f800865e     	str	x30, [x18], #0x8
ffffffc0082d3d70: a9157bfd     	stp	x29, x30, [sp, #0x150]
ffffffc0082d3d74: a9166ffc     	stp	x28, x27, [sp, #0x160]
ffffffc0082d3d78: a91767fa     	stp	x26, x25, [sp, #0x170]
ffffffc0082d3d7c: a9185ff8     	stp	x24, x23, [sp, #0x180]
ffffffc0082d3d80: a91957f6     	stp	x22, x21, [sp, #0x190]
ffffffc0082d3d84: a91a4ff4     	stp	x20, x19, [sp, #0x1a0]
ffffffc0082d3d88: 910543fd     	add	x29, sp, #0x150
ffffffc0082d3d8c: 90011828     	adrp	x8, 0xffffffc00a5d7000 <idle_sched_class+0x20>
ffffffc0082d3d90: f9426908     	ldr	x8, [x8, #0x4d0]
ffffffc0082d3d94: b0010ac9     	adrp	x9, 0xffffffc00a42c000 <clock_posix_cpu+0x18>
ffffffc0082d3d98: 9112c129     	add	x9, x9, #0x4b0
ffffffc0082d3d9c: a9462d2a     	ldp	x10, x11, [x9, #0x60]
ffffffc0082d3da0: f81f03a8     	stur	x8, [x29, #-0x10]
ffffffc0082d3da4: a9473128     	ldp	x8, x12, [x9, #0x70]
ffffffc0082d3da8: eb04001f     	cmp	x0, x4
ffffffc0082d3dac: a93d2faa     	stp	x10, x11, [x29, #-0x30]
ffffffc0082d3db0: a9442d2a     	ldp	x10, x11, [x9, #0x40]
ffffffc0082d3db4: a93e33a8     	stp	x8, x12, [x29, #-0x20]
ffffffc0082d3db8: a9453128     	ldp	x8, x12, [x9, #0x50]
ffffffc0082d3dbc: a90b7fff     	stp	xzr, xzr, [sp, #0xb0]
ffffffc0082d3dc0: a93b2faa     	stp	x10, x11, [x29, #-0x50]
ffffffc0082d3dc4: a9422d2a     	ldp	x10, x11, [x9, #0x20]
ffffffc0082d3dc8: a93c33a8     	stp	x8, x12, [x29, #-0x40]
ffffffc0082d3dcc: a9433128     	ldp	x8, x12, [x9, #0x30]
ffffffc0082d3dd0: a90a7fff     	stp	xzr, xzr, [sp, #0xa0]
ffffffc0082d3dd4: a9392faa     	stp	x10, x11, [x29, #-0x70]
ffffffc0082d3dd8: a9402d2a     	ldp	x10, x11, [x9]
ffffffc0082d3ddc: a93a33a8     	stp	x8, x12, [x29, #-0x60]
ffffffc0082d3de0: a9412528     	ldp	x8, x9, [x9, #0x10]
ffffffc0082d3de4: a9097fff     	stp	xzr, xzr, [sp, #0x90]
ffffffc0082d3de8: a9372faa     	stp	x10, x11, [x29, #-0x90]
ffffffc0082d3dec: a9087fff     	stp	xzr, xzr, [sp, #0x80]
ffffffc0082d3df0: a9077fff     	stp	xzr, xzr, [sp, #0x70]
ffffffc0082d3df4: a9067fff     	stp	xzr, xzr, [sp, #0x60]
ffffffc0082d3df8: a9057fff     	stp	xzr, xzr, [sp, #0x50]
ffffffc0082d3dfc: a9047fff     	stp	xzr, xzr, [sp, #0x40]
ffffffc0082d3e00: a9037fff     	stp	xzr, xzr, [sp, #0x30]
ffffffc0082d3e04: a9027fff     	stp	xzr, xzr, [sp, #0x20]
ffffffc0082d3e08: a9017fff     	stp	xzr, xzr, [sp, #0x10]
ffffffc0082d3e0c: a9007fff     	stp	xzr, xzr, [sp]
ffffffc0082d3e10: a93827a8     	stp	x8, x9, [x29, #-0x80]
ffffffc0082d3e14: 54000300     	b.eq	0xffffffc0082d3e74 <futex_wait_requeue_pi+0x110>
ffffffc0082d3e18: aa0403f5     	mov	x21, x4
ffffffc0082d3e1c: aa0303f6     	mov	x22, x3
ffffffc0082d3e20: 2a0203f7     	mov	w23, w2
ffffffc0082d3e24: 2a0103f9     	mov	w25, w1
ffffffc0082d3e28: aa0003fa     	mov	x26, x0
ffffffc0082d3e2c: d5384114     	mrs	x20, SP_EL0
ffffffc0082d3e30: b4000263     	cbz	x3, 0xffffffc0082d3e7c <futex_wait_requeue_pi+0x118>
ffffffc0082d3e34: f9454e98     	ldr	x24, [x20, #0xa98]
ffffffc0082d3e38: 52800028     	mov	w8, #0x1        // =1
ffffffc0082d3e3c: 0a790501     	bic	w1, w8, w25, lsr #1
ffffffc0082d3e40: 9101c3e0     	add	x0, sp, #0x70
ffffffc0082d3e44: 2a1f03e2     	mov	w2, wzr
ffffffc0082d3e48: 9101c3f3     	add	x19, sp, #0x70
ffffffc0082d3e4c: 97ff3780     	bl	0xffffffc0082a1c4c <hrtimer_init_sleeper>
ffffffc0082d3e50: f94002c8     	ldr	x8, [x22]
ffffffc0082d3e54: 92f00009     	mov	x9, #0x7fffffffffffffff // =9223372036854775807
ffffffc0082d3e58: 8b08030a     	add	x10, x24, x8
ffffffc0082d3e5c: eb08015f     	cmp	x10, x8
ffffffc0082d3e60: fa40a948     	ccmp	x10, #0x0, #0x8, ge
ffffffc0082d3e64: fa58a148     	ccmp	x10, x24, #0x8, ge
ffffffc0082d3e68: 9a8ab129     	csel	x9, x9, x10, lt
ffffffc0082d3e6c: a908a3e9     	stp	x9, x8, [sp, #0x88]
ffffffc0082d3e70: 14000004     	b	0xffffffc0082d3e80 <futex_wait_requeue_pi+0x11c>
ffffffc0082d3e74: 128002b8     	mov	w24, #-0x16     // =-22
ffffffc0082d3e78: 1400019f     	b	0xffffffc0082d44f4 <futex_wait_requeue_pi+0x790>
ffffffc0082d3e7c: aa1f03f3     	mov	x19, xzr
ffffffc0082d3e80: 910083fb     	add	x27, sp, #0x20
ffffffc0082d3e84: 91006368     	add	x8, x27, #0x18
ffffffc0082d3e88: 12000321     	and	w1, w25, #0x1
ffffffc0082d3e8c: 910003e2     	mov	x2, sp
ffffffc0082d3e90: 52800023     	mov	w3, #0x1        // =1
ffffffc0082d3e94: aa1503e0     	mov	x0, x21
ffffffc0082d3e98: f9002bff     	str	xzr, [sp, #0x50]
ffffffc0082d3e9c: f9001fe8     	str	x8, [sp, #0x38]
ffffffc0082d3ea0: f90013fb     	str	x27, [sp, #0x20]
ffffffc0082d3ea4: 910003fc     	mov	x28, sp
ffffffc0082d3ea8: 94000292     	bl	0xffffffc0082d48f0 <get_futex_key>
ffffffc0082d3eac: 35002160     	cbnz	w0, 0xffffffc0082d42d8 <futex_wait_requeue_pi+0x574>
ffffffc0082d3eb0: 12800008     	mov	w8, #-0x1       // =-1
ffffffc0082d3eb4: d10243a3     	sub	x3, x29, #0x90
ffffffc0082d3eb8: 910063e4     	add	x4, sp, #0x18
ffffffc0082d3ebc: aa1a03e0     	mov	x0, x26
ffffffc0082d3ec0: 2a1703e1     	mov	w1, w23
ffffffc0082d3ec4: 2a1903e2     	mov	w2, w25
ffffffc0082d3ec8: b81d83a8     	stur	w8, [x29, #-0x28]
ffffffc0082d3ecc: a93cf3bb     	stp	x27, x28, [x29, #-0x38]
ffffffc0082d3ed0: d10243bb     	sub	x27, x29, #0x90
ffffffc0082d3ed4: 940003a5     	bl	0xffffffc0082d4d68 <futex_wait_setup>
ffffffc0082d3ed8: 2a0003f8     	mov	w24, w0
ffffffc0082d3edc: 350016e0     	cbnz	w0, 0xffffffc0082d41b8 <futex_wait_requeue_pi+0x454>
ffffffc0082d3ee0: b100e37f     	cmn	x27, #0x38
ffffffc0082d3ee4: 54000400     	b.eq	0xffffffc0082d3f64 <futex_wait_requeue_pi+0x200>
ffffffc0082d3ee8: f85b03a8     	ldur	x8, [x29, #-0x50]
ffffffc0082d3eec: f94007e9     	ldr	x9, [sp, #0x8]
ffffffc0082d3ef0: eb09011f     	cmp	x8, x9
ffffffc0082d3ef4: 54000381     	b.ne	0xffffffc0082d3f64 <futex_wait_requeue_pi+0x200>
ffffffc0082d3ef8: f85a83a8     	ldur	x8, [x29, #-0x58]
ffffffc0082d3efc: f94003e9     	ldr	x9, [sp]
ffffffc0082d3f00: eb09011f     	cmp	x8, x9
ffffffc0082d3f04: 54000301     	b.ne	0xffffffc0082d3f64 <futex_wait_requeue_pi+0x200>
ffffffc0082d3f08: b85b83a8     	ldur	w8, [x29, #-0x48]
ffffffc0082d3f0c: b94013e9     	ldr	w9, [sp, #0x10]
ffffffc0082d3f10: 6b09011f     	cmp	w8, w9
ffffffc0082d3f14: 54000281     	b.ne	0xffffffc0082d3f64 <futex_wait_requeue_pi+0x200>
ffffffc0082d3f18: f9400ff5     	ldr	x21, [sp, #0x18]
ffffffc0082d3f1c: 2a1f03e8     	mov	w8, wzr
ffffffc0082d3f20: 910012a9     	add	x9, x21, #0x4
ffffffc0082d3f24: 089ffd28     	stlrb	w8, [x9]
ffffffc0082d3f28: 91006288     	add	x8, x20, #0x18
ffffffc0082d3f2c: c8dffd09     	ldar	x9, [x8]
ffffffc0082d3f30: f1000529     	subs	x9, x9, #0x1
ffffffc0082d3f34: b9001a89     	str	w9, [x20, #0x18]
ffffffc0082d3f38: 540021e0     	b.eq	0xffffffc0082d4374 <futex_wait_requeue_pi+0x610>
ffffffc0082d3f3c: c8dffd09     	ldar	x9, [x8]
ffffffc0082d3f40: b40021a9     	cbz	x9, 0xffffffc0082d4374 <futex_wait_requeue_pi+0x610>
ffffffc0082d3f44: 1400015e     	b	0xffffffc0082d44bc <futex_wait_requeue_pi+0x758>
ffffffc0082d3f48: 1400015d     	b	0xffffffc0082d44bc <futex_wait_requeue_pi+0x758>
ffffffc0082d3f4c: 52800028     	mov	w8, #0x1        // =1
ffffffc0082d3f50: 4b0803e8     	neg	w8, w8
ffffffc0082d3f54: b82802bf     	stadd	w8, [x21]
ffffffc0082d3f58: 128002b8     	mov	w24, #-0x16     // =-22
ffffffc0082d3f5c: b5002c73     	cbnz	x19, 0xffffffc0082d44e8 <futex_wait_requeue_pi+0x784>
ffffffc0082d3f60: 14000165     	b	0xffffffc0082d44f4 <futex_wait_requeue_pi+0x790>
ffffffc0082d3f64: f9400ff8     	ldr	x24, [sp, #0x18]
ffffffc0082d3f68: d10243a1     	sub	x1, x29, #0x90
ffffffc0082d3f6c: aa1303e2     	mov	x2, x19
ffffffc0082d3f70: 2a1f03e3     	mov	w3, wzr
ffffffc0082d3f74: aa1803e0     	mov	x0, x24
ffffffc0082d3f78: aa1f03e4     	mov	x4, xzr
ffffffc0082d3f7c: 2a1f03e5     	mov	w5, wzr
ffffffc0082d3f80: 2a1f03e6     	mov	w6, wzr
ffffffc0082d3f84: 940004c1     	bl	0xffffffc0082d5288 <futex_wait_queue_me>
ffffffc0082d3f88: 91006288     	add	x8, x20, #0x18
ffffffc0082d3f8c: 88dffd08     	ldar	w8, [x8]
ffffffc0082d3f90: 11000508     	add	w8, w8, #0x1
ffffffc0082d3f94: b9001a88     	str	w8, [x20, #0x18]
ffffffc0082d3f98: 91001317     	add	x23, x24, #0x4
ffffffc0082d3f9c: 1400012d     	b	0xffffffc0082d4450 <futex_wait_requeue_pi+0x6ec>
ffffffc0082d3fa0: 1400012c     	b	0xffffffc0082d4450 <futex_wait_requeue_pi+0x6ec>
ffffffc0082d3fa4: aa1f03e1     	mov	x1, xzr
ffffffc0082d3fa8: aa1703e0     	mov	x0, x23
ffffffc0082d3fac: 52800022     	mov	w2, #0x1        // =1
ffffffc0082d3fb0: 2a0103e8     	mov	w8, w1
ffffffc0082d3fb4: 88e87ee2     	casa	w8, w2, [x23]
ffffffc0082d3fb8: 2a0803e0     	mov	w0, w8
ffffffc0082d3fbc: aa0003e1     	mov	x1, x0
ffffffc0082d3fc0: 350025c1     	cbnz	w1, 0xffffffc0082d4478 <futex_wait_requeue_pi+0x714>
ffffffc0082d3fc4: f85b03a8     	ldur	x8, [x29, #-0x50]
ffffffc0082d3fc8: f94007e9     	ldr	x9, [sp, #0x8]
ffffffc0082d3fcc: eb09011f     	cmp	x8, x9
ffffffc0082d3fd0: 54000621     	b.ne	0xffffffc0082d4094 <futex_wait_requeue_pi+0x330>
ffffffc0082d3fd4: f85a83a8     	ldur	x8, [x29, #-0x58]
ffffffc0082d3fd8: f94003e9     	ldr	x9, [sp]
ffffffc0082d3fdc: eb09011f     	cmp	x8, x9
ffffffc0082d3fe0: 540005a1     	b.ne	0xffffffc0082d4094 <futex_wait_requeue_pi+0x330>
ffffffc0082d3fe4: b85b83a8     	ldur	w8, [x29, #-0x48]
ffffffc0082d3fe8: b94013e9     	ldr	w9, [sp, #0x10]
ffffffc0082d3fec: 6b09011f     	cmp	w8, w9
ffffffc0082d3ff0: 54000521     	b.ne	0xffffffc0082d4094 <futex_wait_requeue_pi+0x330>
ffffffc0082d3ff4: 2a1f03e8     	mov	w8, wzr
ffffffc0082d3ff8: 089ffee8     	stlrb	w8, [x23]
ffffffc0082d3ffc: 91006288     	add	x8, x20, #0x18
ffffffc0082d4000: c8dffd09     	ldar	x9, [x8]
ffffffc0082d4004: f1000529     	subs	x9, x9, #0x1
ffffffc0082d4008: b9001a89     	str	w9, [x20, #0x18]
ffffffc0082d400c: 54001920     	b.eq	0xffffffc0082d4330 <futex_wait_requeue_pi+0x5cc>
ffffffc0082d4010: c8dffd09     	ldar	x9, [x8]
ffffffc0082d4014: b40018e9     	cbz	x9, 0xffffffc0082d4330 <futex_wait_requeue_pi+0x5cc>
ffffffc0082d4018: a97c27a8     	ldp	x8, x9, [x29, #-0x40]
ffffffc0082d401c: b4000d29     	cbz	x9, 0xffffffc0082d41c0 <futex_wait_requeue_pi+0x45c>
ffffffc0082d4020: b4001cc8     	cbz	x8, 0xffffffc0082d43b8 <futex_wait_requeue_pi+0x654>
ffffffc0082d4024: 91004116     	add	x22, x8, #0x10
ffffffc0082d4028: 910083e2     	add	x2, sp, #0x20
ffffffc0082d402c: aa1603e0     	mov	x0, x22
ffffffc0082d4030: aa1303e1     	mov	x1, x19
ffffffc0082d4034: 97fd5129     	bl	0xffffffc0082284d8 <rt_mutex_wait_proxy_lock>
ffffffc0082d4038: 91006289     	add	x9, x20, #0x18
ffffffc0082d403c: f85a03a8     	ldur	x8, [x29, #-0x60]
ffffffc0082d4040: 88dffd29     	ldar	w9, [x9]
ffffffc0082d4044: 11000529     	add	w9, w9, #0x1
ffffffc0082d4048: b9001a89     	str	w9, [x20, #0x18]
ffffffc0082d404c: 2a0003f7     	mov	w23, w0
ffffffc0082d4050: 1400013a     	b	0xffffffc0082d4538 <futex_wait_requeue_pi+0x7d4>
ffffffc0082d4054: 14000139     	b	0xffffffc0082d4538 <futex_wait_requeue_pi+0x7d4>
ffffffc0082d4058: aa1f03e1     	mov	x1, xzr
ffffffc0082d405c: aa0803e0     	mov	x0, x8
ffffffc0082d4060: 52800022     	mov	w2, #0x1        // =1
ffffffc0082d4064: 2a0103e9     	mov	w9, w1
ffffffc0082d4068: 88e97d02     	casa	w9, w2, [x8]
ffffffc0082d406c: 2a0903e0     	mov	w0, w9
ffffffc0082d4070: aa0003e1     	mov	x1, x0
ffffffc0082d4074: 35002761     	cbnz	w1, 0xffffffc0082d4560 <futex_wait_requeue_pi+0x7fc>
ffffffc0082d4078: 340027b7     	cbz	w23, 0xffffffc0082d456c <futex_wait_requeue_pi+0x808>
ffffffc0082d407c: 910083e1     	add	x1, sp, #0x20
ffffffc0082d4080: aa1603e0     	mov	x0, x22
ffffffc0082d4084: 97fd5180     	bl	0xffffffc008228684 <rt_mutex_cleanup_proxy_lock>
ffffffc0082d4088: 7200001f     	tst	w0, #0x1
ffffffc0082d408c: 1a9f12f6     	csel	w22, w23, wzr, ne
ffffffc0082d4090: 14000138     	b	0xffffffc0082d4570 <futex_wait_requeue_pi+0x80c>
ffffffc0082d4094: f85a03a8     	ldur	x8, [x29, #-0x60]
ffffffc0082d4098: b4000068     	cbz	x8, 0xffffffc0082d40a4 <futex_wait_requeue_pi+0x340>
ffffffc0082d409c: eb0802ff     	cmp	x23, x8
ffffffc0082d40a0: 54001441     	b.ne	0xffffffc0082d4328 <futex_wait_requeue_pi+0x5c4>
ffffffc0082d40a4: d10243b9     	sub	x25, x29, #0x90
ffffffc0082d40a8: 91002335     	add	x21, x25, #0x8
ffffffc0082d40ac: c8dffea8     	ldar	x8, [x21]
ffffffc0082d40b0: eb0802bf     	cmp	x21, x8
ffffffc0082d40b4: 540003c0     	b.eq	0xffffffc0082d412c <futex_wait_requeue_pi+0x3c8>
ffffffc0082d40b8: f85883a8     	ldur	x8, [x29, #-0x78]
ffffffc0082d40bc: 91004309     	add	x9, x24, #0x10
ffffffc0082d40c0: eb09011f     	cmp	x8, x9
ffffffc0082d40c4: 54000260     	b.eq	0xffffffc0082d4110 <futex_wait_requeue_pi+0x3ac>
ffffffc0082d40c8: d1004101     	sub	x1, x8, #0x10
ffffffc0082d40cc: c8dffc29     	ldar	x9, [x1]
ffffffc0082d40d0: eb01013f     	cmp	x9, x1
ffffffc0082d40d4: 540001e1     	b.ne	0xffffffc0082d4110 <futex_wait_requeue_pi+0x3ac>
ffffffc0082d40d8: b4003295     	cbz	x21, 0xffffffc0082d4728 <futex_wait_requeue_pi+0x9c4>
ffffffc0082d40dc: f85783a3     	ldur	x3, [x29, #-0x88]
ffffffc0082d40e0: b40032c3     	cbz	x3, 0xffffffc0082d4738 <futex_wait_requeue_pi+0x9d4>
ffffffc0082d40e4: f9400462     	ldr	x2, [x3, #0x8]
ffffffc0082d40e8: eb15005f     	cmp	x2, x21
ffffffc0082d40ec: 540032e1     	b.ne	0xffffffc0082d4748 <futex_wait_requeue_pi+0x9e4>
ffffffc0082d40f0: eb0102bf     	cmp	x21, x1
ffffffc0082d40f4: 54001da0     	b.eq	0xffffffc0082d44a8 <futex_wait_requeue_pi+0x744>
ffffffc0082d40f8: eb01007f     	cmp	x3, x1
ffffffc0082d40fc: 54001d60     	b.eq	0xffffffc0082d44a8 <futex_wait_requeue_pi+0x744>
ffffffc0082d4100: d1006108     	sub	x8, x8, #0x18
ffffffc0082d4104: f9000461     	str	x1, [x3, #0x8]
ffffffc0082d4108: a900d503     	stp	x3, x21, [x8, #0x8]
ffffffc0082d410c: f81783a1     	stur	x1, [x29, #-0x88]
ffffffc0082d4110: aa1503e0     	mov	x0, x21
ffffffc0082d4114: 941f7557     	bl	0xffffffc008ab1670 <__list_del_entry_valid>
ffffffc0082d4118: a977a3a9     	ldp	x9, x8, [x29, #-0x88]
ffffffc0082d411c: f9000528     	str	x8, [x9, #0x8]
ffffffc0082d4120: f9000109     	str	x9, [x8]
ffffffc0082d4124: f81783b5     	stur	x21, [x29, #-0x88]
ffffffc0082d4128: f81803b5     	stur	x21, [x29, #-0x80]
ffffffc0082d412c: 91006335     	add	x21, x25, #0x18
ffffffc0082d4130: aa1503e0     	mov	x0, x21
ffffffc0082d4134: 941f754f     	bl	0xffffffc008ab1670 <__list_del_entry_valid>
ffffffc0082d4138: a978a3a9     	ldp	x9, x8, [x29, #-0x78]
ffffffc0082d413c: f9000528     	str	x8, [x9, #0x8]
ffffffc0082d4140: f9000109     	str	x9, [x8]
ffffffc0082d4144: f81883b5     	stur	x21, [x29, #-0x78]
ffffffc0082d4148: f81903b5     	stur	x21, [x29, #-0x70]
ffffffc0082d414c: 140000ce     	b	0xffffffc0082d4484 <futex_wait_requeue_pi+0x720>
ffffffc0082d4150: 140000cd     	b	0xffffffc0082d4484 <futex_wait_requeue_pi+0x720>
ffffffc0082d4154: 52800028     	mov	w8, #0x1        // =1
ffffffc0082d4158: 4b0803e8     	neg	w8, w8
ffffffc0082d415c: b828031f     	stadd	w8, [x24]
ffffffc0082d4160: b4000093     	cbz	x19, 0xffffffc0082d4170 <futex_wait_requeue_pi+0x40c>
ffffffc0082d4164: b4001756     	cbz	x22, 0xffffffc0082d444c <futex_wait_requeue_pi+0x6e8>
ffffffc0082d4168: f9402668     	ldr	x8, [x19, #0x48]
ffffffc0082d416c: b4000128     	cbz	x8, 0xffffffc0082d4190 <futex_wait_requeue_pi+0x42c>
ffffffc0082d4170: f9400288     	ldr	x8, [x20]
ffffffc0082d4174: 12804018     	mov	w24, #-0x201    // =-513
ffffffc0082d4178: 373800e8     	tbnz	w8, #0x7, 0xffffffc0082d4194 <futex_wait_requeue_pi+0x430>
ffffffc0082d417c: f9400288     	ldr	x8, [x20]
ffffffc0082d4180: f240011f     	tst	x8, #0x1
ffffffc0082d4184: 12800148     	mov	w8, #-0xb       // =-11
ffffffc0082d4188: 1a980118     	csel	w24, w8, w24, eq
ffffffc0082d418c: 14000002     	b	0xffffffc0082d4194 <futex_wait_requeue_pi+0x430>
ffffffc0082d4190: 12800db8     	mov	w24, #-0x6e     // =-110
ffffffc0082d4194: 2a1f03e8     	mov	w8, wzr
ffffffc0082d4198: 089ffee8     	stlrb	w8, [x23]
ffffffc0082d419c: 91006288     	add	x8, x20, #0x18
ffffffc0082d41a0: c8dffd09     	ldar	x9, [x8]
ffffffc0082d41a4: f1000529     	subs	x9, x9, #0x1
ffffffc0082d41a8: b9001a89     	str	w9, [x20, #0x18]
ffffffc0082d41ac: 540009c0     	b.eq	0xffffffc0082d42e4 <futex_wait_requeue_pi+0x580>
ffffffc0082d41b0: c8dffd09     	ldar	x9, [x8]
ffffffc0082d41b4: b4000989     	cbz	x9, 0xffffffc0082d42e4 <futex_wait_requeue_pi+0x580>
ffffffc0082d41b8: b5001993     	cbnz	x19, 0xffffffc0082d44e8 <futex_wait_requeue_pi+0x784>
ffffffc0082d41bc: 140000ce     	b	0xffffffc0082d44f4 <futex_wait_requeue_pi+0x790>
ffffffc0082d41c0: b4000868     	cbz	x8, 0xffffffc0082d42cc <futex_wait_requeue_pi+0x568>
ffffffc0082d41c4: f9401908     	ldr	x8, [x8, #0x30]
ffffffc0082d41c8: eb14011f     	cmp	x8, x20
ffffffc0082d41cc: 54000800     	b.eq	0xffffffc0082d42cc <futex_wait_requeue_pi+0x568>
ffffffc0082d41d0: 91006289     	add	x9, x20, #0x18
ffffffc0082d41d4: f85a03a8     	ldur	x8, [x29, #-0x60]
ffffffc0082d41d8: 88dffd29     	ldar	w9, [x9]
ffffffc0082d41dc: 11000529     	add	w9, w9, #0x1
ffffffc0082d41e0: b9001a89     	str	w9, [x20, #0x18]
ffffffc0082d41e4: 1400015f     	b	0xffffffc0082d4760 <futex_wait_requeue_pi+0x9fc>
ffffffc0082d41e8: 1400015e     	b	0xffffffc0082d4760 <futex_wait_requeue_pi+0x9fc>
ffffffc0082d41ec: aa1f03e1     	mov	x1, xzr
ffffffc0082d41f0: aa0803e0     	mov	x0, x8
ffffffc0082d41f4: 52800022     	mov	w2, #0x1        // =1
ffffffc0082d41f8: 2a0103e9     	mov	w9, w1
ffffffc0082d41fc: 88e97d02     	casa	w9, w2, [x8]
ffffffc0082d4200: 2a0903e0     	mov	w0, w9
ffffffc0082d4204: aa0003e1     	mov	x1, x0
ffffffc0082d4208: 35002c01     	cbnz	w1, 0xffffffc0082d4788 <futex_wait_requeue_pi+0xa24>
ffffffc0082d420c: f85c03a8     	ldur	x8, [x29, #-0x40]
ffffffc0082d4210: 91004116     	add	x22, x8, #0x10
ffffffc0082d4214: d503201f     	nop
ffffffc0082d4218: 52800c08     	mov	w8, #0x60       // =96
ffffffc0082d421c: d50342df     	msr	DAIFSet, #0x2
ffffffc0082d4220: 91006288     	add	x8, x20, #0x18
ffffffc0082d4224: 88dffd08     	ldar	w8, [x8]
ffffffc0082d4228: 11000508     	add	w8, w8, #0x1
ffffffc0082d422c: b9001a88     	str	w8, [x20, #0x18]
ffffffc0082d4230: 14000159     	b	0xffffffc0082d4794 <futex_wait_requeue_pi+0xa30>
ffffffc0082d4234: 14000158     	b	0xffffffc0082d4794 <futex_wait_requeue_pi+0xa30>
ffffffc0082d4238: aa1f03e1     	mov	x1, xzr
ffffffc0082d423c: aa1603e0     	mov	x0, x22
ffffffc0082d4240: 52800022     	mov	w2, #0x1        // =1
ffffffc0082d4244: 2a0103e8     	mov	w8, w1
ffffffc0082d4248: 88e87ec2     	casa	w8, w2, [x22]
ffffffc0082d424c: 2a0803e0     	mov	w0, w8
ffffffc0082d4250: aa0003e1     	mov	x1, x0
ffffffc0082d4254: 35002b41     	cbnz	w1, 0xffffffc0082d47bc <futex_wait_requeue_pi+0xa58>
ffffffc0082d4258: d10243a1     	sub	x1, x29, #0x90
ffffffc0082d425c: aa1503e0     	mov	x0, x21
ffffffc0082d4260: aa1403e2     	mov	x2, x20
ffffffc0082d4264: 9400095a     	bl	0xffffffc0082d67cc <__fixup_pi_state_owner>
ffffffc0082d4268: 2a1f03e8     	mov	w8, wzr
ffffffc0082d426c: 089ffec8     	stlrb	w8, [x22]
ffffffc0082d4270: 52801c08     	mov	w8, #0xe0       // =224
ffffffc0082d4274: d50342ff     	msr	DAIFClr, #0x2
ffffffc0082d4278: 91006288     	add	x8, x20, #0x18
ffffffc0082d427c: c8dffd09     	ldar	x9, [x8]
ffffffc0082d4280: 2a0003f5     	mov	w21, w0
ffffffc0082d4284: f1000529     	subs	x9, x9, #0x1
ffffffc0082d4288: b9001a89     	str	w9, [x20, #0x18]
ffffffc0082d428c: 540009c0     	b.eq	0xffffffc0082d43c4 <futex_wait_requeue_pi+0x660>
ffffffc0082d4290: c8dffd09     	ldar	x9, [x8]
ffffffc0082d4294: b4000989     	cbz	x9, 0xffffffc0082d43c4 <futex_wait_requeue_pi+0x660>
ffffffc0082d4298: f85c03a0     	ldur	x0, [x29, #-0x40]
ffffffc0082d429c: 94000b37     	bl	0xffffffc0082d6f78 <put_pi_state>
ffffffc0082d42a0: 2a1f03e8     	mov	w8, wzr
ffffffc0082d42a4: f85a03a9     	ldur	x9, [x29, #-0x60]
ffffffc0082d42a8: 089ffd28     	stlrb	w8, [x9]
ffffffc0082d42ac: 91006288     	add	x8, x20, #0x18
ffffffc0082d42b0: c8dffd09     	ldar	x9, [x8]
ffffffc0082d42b4: f1000529     	subs	x9, x9, #0x1
ffffffc0082d42b8: b9001a89     	str	w9, [x20, #0x18]
ffffffc0082d42bc: 54000a60     	b.eq	0xffffffc0082d4408 <futex_wait_requeue_pi+0x6a4>
ffffffc0082d42c0: c8dffd09     	ldar	x9, [x8]
ffffffc0082d42c4: b4000a29     	cbz	x9, 0xffffffc0082d4408 <futex_wait_requeue_pi+0x6a4>
ffffffc0082d42c8: 37f81ef5     	tbnz	w21, #0x1f, 0xffffffc0082d46a4 <futex_wait_requeue_pi+0x940>
ffffffc0082d42cc: 2a1f03f8     	mov	w24, wzr
ffffffc0082d42d0: b50010d3     	cbnz	x19, 0xffffffc0082d44e8 <futex_wait_requeue_pi+0x784>
ffffffc0082d42d4: 14000088     	b	0xffffffc0082d44f4 <futex_wait_requeue_pi+0x790>
ffffffc0082d42d8: 2a0003f8     	mov	w24, w0
ffffffc0082d42dc: b5001073     	cbnz	x19, 0xffffffc0082d44e8 <futex_wait_requeue_pi+0x784>
ffffffc0082d42e0: 14000085     	b	0xffffffc0082d44f4 <futex_wait_requeue_pi+0x790>
ffffffc0082d42e4: 88dffd08     	ldar	w8, [x8]
ffffffc0082d42e8: 35fff688     	cbnz	w8, 0xffffffc0082d41b8 <futex_wait_requeue_pi+0x454>
ffffffc0082d42ec: d53b4228     	mrs	x8, DAIF
ffffffc0082d42f0: 12190109     	and	w9, w8, #0x80
ffffffc0082d42f4: 35fff629     	cbnz	w9, 0xffffffc0082d41b8 <futex_wait_requeue_pi+0x454>
ffffffc0082d42f8: 91006295     	add	x21, x20, #0x18
ffffffc0082d42fc: 88dffea8     	ldar	w8, [x21]
ffffffc0082d4300: 11000508     	add	w8, w8, #0x1
ffffffc0082d4304: b9001a88     	str	w8, [x20, #0x18]
ffffffc0082d4308: 52800020     	mov	w0, #0x1        // =1
ffffffc0082d430c: 9464b6d3     	bl	0xffffffc009c01e58 <__schedule>
ffffffc0082d4310: 88dffea8     	ldar	w8, [x21]
ffffffc0082d4314: 51000508     	sub	w8, w8, #0x1
ffffffc0082d4318: b9001a88     	str	w8, [x20, #0x18]
ffffffc0082d431c: f9400288     	ldr	x8, [x20]
ffffffc0082d4320: 370ffec8     	tbnz	w8, #0x1, 0xffffffc0082d42f8 <futex_wait_requeue_pi+0x594>
ffffffc0082d4324: 17ffffa5     	b	0xffffffc0082d41b8 <futex_wait_requeue_pi+0x454>
ffffffc0082d4328: d4210000     	brk	#0x800
ffffffc0082d432c: 17ffff5e     	b	0xffffffc0082d40a4 <futex_wait_requeue_pi+0x340>
ffffffc0082d4330: 88dffd08     	ldar	w8, [x8]
ffffffc0082d4334: 35ffe728     	cbnz	w8, 0xffffffc0082d4018 <futex_wait_requeue_pi+0x2b4>
ffffffc0082d4338: d53b4228     	mrs	x8, DAIF
ffffffc0082d433c: 12190109     	and	w9, w8, #0x80
ffffffc0082d4340: 35ffe6c9     	cbnz	w9, 0xffffffc0082d4018 <futex_wait_requeue_pi+0x2b4>
ffffffc0082d4344: 91006296     	add	x22, x20, #0x18
ffffffc0082d4348: 88dffec8     	ldar	w8, [x22]
ffffffc0082d434c: 11000508     	add	w8, w8, #0x1
ffffffc0082d4350: b9001a88     	str	w8, [x20, #0x18]
ffffffc0082d4354: 52800020     	mov	w0, #0x1        // =1
ffffffc0082d4358: 9464b6c0     	bl	0xffffffc009c01e58 <__schedule>
ffffffc0082d435c: 88dffec8     	ldar	w8, [x22]
ffffffc0082d4360: 51000508     	sub	w8, w8, #0x1
ffffffc0082d4364: b9001a88     	str	w8, [x20, #0x18]
ffffffc0082d4368: f9400288     	ldr	x8, [x20]
ffffffc0082d436c: 370ffec8     	tbnz	w8, #0x1, 0xffffffc0082d4344 <futex_wait_requeue_pi+0x5e0>
ffffffc0082d4370: 17ffff2a     	b	0xffffffc0082d4018 <futex_wait_requeue_pi+0x2b4>
ffffffc0082d4374: 88dffd08     	ldar	w8, [x8]
ffffffc0082d4378: 35ffde68     	cbnz	w8, 0xffffffc0082d3f44 <futex_wait_requeue_pi+0x1e0>
ffffffc0082d437c: d53b4228     	mrs	x8, DAIF
ffffffc0082d4380: 12190109     	and	w9, w8, #0x80
ffffffc0082d4384: 35ffde09     	cbnz	w9, 0xffffffc0082d3f44 <futex_wait_requeue_pi+0x1e0>
ffffffc0082d4388: 91006296     	add	x22, x20, #0x18
ffffffc0082d438c: 88dffec8     	ldar	w8, [x22]
ffffffc0082d4390: 11000508     	add	w8, w8, #0x1
ffffffc0082d4394: b9001a88     	str	w8, [x20, #0x18]
ffffffc0082d4398: 52800020     	mov	w0, #0x1        // =1
ffffffc0082d439c: 9464b6af     	bl	0xffffffc009c01e58 <__schedule>
ffffffc0082d43a0: 88dffec8     	ldar	w8, [x22]
ffffffc0082d43a4: 51000508     	sub	w8, w8, #0x1
ffffffc0082d43a8: b9001a88     	str	w8, [x20, #0x18]
ffffffc0082d43ac: f9400288     	ldr	x8, [x20]
ffffffc0082d43b0: 370ffec8     	tbnz	w8, #0x1, 0xffffffc0082d4388 <futex_wait_requeue_pi+0x624>
ffffffc0082d43b4: 17fffee4     	b	0xffffffc0082d3f44 <futex_wait_requeue_pi+0x1e0>
ffffffc0082d43b8: d4210000     	brk	#0x800
ffffffc0082d43bc: f85c03a8     	ldur	x8, [x29, #-0x40]
ffffffc0082d43c0: 17ffff19     	b	0xffffffc0082d4024 <futex_wait_requeue_pi+0x2c0>
ffffffc0082d43c4: 88dffd08     	ldar	w8, [x8]
ffffffc0082d43c8: 35fff688     	cbnz	w8, 0xffffffc0082d4298 <futex_wait_requeue_pi+0x534>
ffffffc0082d43cc: d53b4228     	mrs	x8, DAIF
ffffffc0082d43d0: 12190109     	and	w9, w8, #0x80
ffffffc0082d43d4: 35fff629     	cbnz	w9, 0xffffffc0082d4298 <futex_wait_requeue_pi+0x534>
ffffffc0082d43d8: 91006296     	add	x22, x20, #0x18
ffffffc0082d43dc: 88dffec8     	ldar	w8, [x22]
ffffffc0082d43e0: 11000508     	add	w8, w8, #0x1
ffffffc0082d43e4: b9001a88     	str	w8, [x20, #0x18]
ffffffc0082d43e8: 52800020     	mov	w0, #0x1        // =1
ffffffc0082d43ec: 9464b69b     	bl	0xffffffc009c01e58 <__schedule>
ffffffc0082d43f0: 88dffec8     	ldar	w8, [x22]
ffffffc0082d43f4: 51000508     	sub	w8, w8, #0x1
ffffffc0082d43f8: b9001a88     	str	w8, [x20, #0x18]
ffffffc0082d43fc: f9400288     	ldr	x8, [x20]
ffffffc0082d4400: 370ffec8     	tbnz	w8, #0x1, 0xffffffc0082d43d8 <futex_wait_requeue_pi+0x674>
ffffffc0082d4404: 17ffffa5     	b	0xffffffc0082d4298 <futex_wait_requeue_pi+0x534>
ffffffc0082d4408: 88dffd08     	ldar	w8, [x8]
ffffffc0082d440c: 35fff5e8     	cbnz	w8, 0xffffffc0082d42c8 <futex_wait_requeue_pi+0x564>
ffffffc0082d4410: d53b4228     	mrs	x8, DAIF
ffffffc0082d4414: 12190109     	and	w9, w8, #0x80
ffffffc0082d4418: 35fff589     	cbnz	w9, 0xffffffc0082d42c8 <futex_wait_requeue_pi+0x564>
ffffffc0082d441c: 91006296     	add	x22, x20, #0x18
ffffffc0082d4420: 88dffec8     	ldar	w8, [x22]
ffffffc0082d4424: 11000508     	add	w8, w8, #0x1
ffffffc0082d4428: b9001a88     	str	w8, [x20, #0x18]
ffffffc0082d442c: 52800020     	mov	w0, #0x1        // =1
ffffffc0082d4430: 9464b68a     	bl	0xffffffc009c01e58 <__schedule>
ffffffc0082d4434: 88dffec8     	ldar	w8, [x22]
ffffffc0082d4438: 51000508     	sub	w8, w8, #0x1
ffffffc0082d443c: b9001a88     	str	w8, [x20, #0x18]
ffffffc0082d4440: f9400288     	ldr	x8, [x20]
ffffffc0082d4444: 370ffec8     	tbnz	w8, #0x1, 0xffffffc0082d441c <futex_wait_requeue_pi+0x6b8>
ffffffc0082d4448: 17ffffa0     	b	0xffffffc0082d42c8 <futex_wait_requeue_pi+0x564>
ffffffc0082d444c: d4200020     	brk	#0x1
ffffffc0082d4450: d503249f     	bti	j
ffffffc0082d4454: aa1f03e8     	mov	x8, xzr
ffffffc0082d4458: 52800029     	mov	w9, #0x1        // =1
ffffffc0082d445c: f98002f1     	prfm	pstl1strm, [x23]
ffffffc0082d4460: 885ffee1     	ldaxr	w1, [x23]
ffffffc0082d4464: 4a08002a     	eor	w10, w1, w8
ffffffc0082d4468: 3500006a     	cbnz	w10, 0xffffffc0082d4474 <futex_wait_requeue_pi+0x710>
ffffffc0082d446c: 880a7ee9     	stxr	w10, w9, [x23]
ffffffc0082d4470: 35ffff8a     	cbnz	w10, 0xffffffc0082d4460 <futex_wait_requeue_pi+0x6fc>
ffffffc0082d4474: 34ffda81     	cbz	w1, 0xffffffc0082d3fc4 <futex_wait_requeue_pi+0x260>
ffffffc0082d4478: aa1703e0     	mov	x0, x23
ffffffc0082d447c: 97fd40ef     	bl	0xffffffc008224838 <queued_spin_lock_slowpath>
ffffffc0082d4480: 17fffed1     	b	0xffffffc0082d3fc4 <futex_wait_requeue_pi+0x260>
ffffffc0082d4484: d503249f     	bti	j
ffffffc0082d4488: 52800028     	mov	w8, #0x1        // =1
ffffffc0082d448c: f9800311     	prfm	pstl1strm, [x24]
ffffffc0082d4490: 885f7f09     	ldxr	w9, [x24]
ffffffc0082d4494: 4b080129     	sub	w9, w9, w8
ffffffc0082d4498: 880a7f09     	stxr	w10, w9, [x24]
ffffffc0082d449c: 35ffffaa     	cbnz	w10, 0xffffffc0082d4490 <futex_wait_requeue_pi+0x72c>
ffffffc0082d44a0: b5ffe633     	cbnz	x19, 0xffffffc0082d4164 <futex_wait_requeue_pi+0x400>
ffffffc0082d44a4: 17ffff33     	b	0xffffffc0082d4170 <futex_wait_requeue_pi+0x40c>
ffffffc0082d44a8: 90010700     	adrp	x0, 0xffffffc00a3b4000 <stat_nam.17992+0x18d75>
ffffffc0082d44ac: 910e1800     	add	x0, x0, #0x386
ffffffc0082d44b0: aa1503e2     	mov	x2, x21
ffffffc0082d44b4: 97fd78d5     	bl	0xffffffc008232808 <printk>
ffffffc0082d44b8: d4210000     	brk	#0x800
ffffffc0082d44bc: d503249f     	bti	j
ffffffc0082d44c0: 52800028     	mov	w8, #0x1        // =1
ffffffc0082d44c4: f98002b1     	prfm	pstl1strm, [x21]
ffffffc0082d44c8: 885f7ea9     	ldxr	w9, [x21]
ffffffc0082d44cc: 4b080129     	sub	w9, w9, w8
ffffffc0082d44d0: 880a7ea9     	stxr	w10, w9, [x21]
ffffffc0082d44d4: 35ffffaa     	cbnz	w10, 0xffffffc0082d44c8 <futex_wait_requeue_pi+0x764>
ffffffc0082d44d8: 128002b8     	mov	w24, #-0x16     // =-22
ffffffc0082d44dc: b5000073     	cbnz	x19, 0xffffffc0082d44e8 <futex_wait_requeue_pi+0x784>
ffffffc0082d44e0: 14000005     	b	0xffffffc0082d44f4 <futex_wait_requeue_pi+0x790>
ffffffc0082d44e4: d503203f     	yield
ffffffc0082d44e8: aa1303e0     	mov	x0, x19
ffffffc0082d44ec: 97ff3733     	bl	0xffffffc0082a21b8 <hrtimer_try_to_cancel>
ffffffc0082d44f0: 37ffffa0     	tbnz	w0, #0x1f, 0xffffffc0082d44e4 <futex_wait_requeue_pi+0x780>
ffffffc0082d44f4: f0011809     	adrp	x9, 0xffffffc00a5d7000 <idle_sched_class+0x20>
ffffffc0082d44f8: f85f03a8     	ldur	x8, [x29, #-0x10]
ffffffc0082d44fc: f9426929     	ldr	x9, [x9, #0x4d0]
ffffffc0082d4500: eb08013f     	cmp	x9, x8
ffffffc0082d4504: 54000181     	b.ne	0xffffffc0082d4534 <futex_wait_requeue_pi+0x7d0>
ffffffc0082d4508: a9557bfd     	ldp	x29, x30, [sp, #0x150]
ffffffc0082d450c: 2a1803e0     	mov	w0, w24
ffffffc0082d4510: a95a4ff4     	ldp	x20, x19, [sp, #0x1a0]
ffffffc0082d4514: a95957f6     	ldp	x22, x21, [sp, #0x190]
ffffffc0082d4518: a9585ff8     	ldp	x24, x23, [sp, #0x180]
ffffffc0082d451c: a95767fa     	ldp	x26, x25, [sp, #0x170]
ffffffc0082d4520: a9566ffc     	ldp	x28, x27, [sp, #0x160]
ffffffc0082d4524: f85f8e5e     	ldr	x30, [x18, #-0x8]!
ffffffc0082d4528: 9106c3ff     	add	sp, sp, #0x1b0
ffffffc0082d452c: d50323bf     	autiasp
ffffffc0082d4530: d65f03c0     	ret
ffffffc0082d4534: 945593c8     	bl	0xffffffc009839454 <__stack_chk_fail>
ffffffc0082d4538: d503249f     	bti	j
ffffffc0082d453c: aa1f03e9     	mov	x9, xzr
ffffffc0082d4540: 5280002a     	mov	w10, #0x1       // =1
ffffffc0082d4544: f9800111     	prfm	pstl1strm, [x8]
ffffffc0082d4548: 885ffd01     	ldaxr	w1, [x8]
ffffffc0082d454c: 4a09002b     	eor	w11, w1, w9
ffffffc0082d4550: 3500006b     	cbnz	w11, 0xffffffc0082d455c <futex_wait_requeue_pi+0x7f8>
ffffffc0082d4554: 880b7d0a     	stxr	w11, w10, [x8]
ffffffc0082d4558: 35ffff8b     	cbnz	w11, 0xffffffc0082d4548 <futex_wait_requeue_pi+0x7e4>
ffffffc0082d455c: 34ffd8e1     	cbz	w1, 0xffffffc0082d4078 <futex_wait_requeue_pi+0x314>
ffffffc0082d4560: aa0803e0     	mov	x0, x8
ffffffc0082d4564: 97fd40b5     	bl	0xffffffc008224838 <queued_spin_lock_slowpath>
ffffffc0082d4568: 35ffd8b7     	cbnz	w23, 0xffffffc0082d407c <futex_wait_requeue_pi+0x318>
ffffffc0082d456c: 2a1f03f6     	mov	w22, wzr
ffffffc0082d4570: 710002df     	cmp	w22, #0x0
ffffffc0082d4574: 1a9f17e2     	cset	w2, eq
ffffffc0082d4578: d10243a1     	sub	x1, x29, #0x90
ffffffc0082d457c: aa1503e0     	mov	x0, x21
ffffffc0082d4580: d10243b7     	sub	x23, x29, #0x90
ffffffc0082d4584: 94000b5b     	bl	0xffffffc0082d72f0 <fixup_owner>
ffffffc0082d4588: f85a03a8     	ldur	x8, [x29, #-0x60]
ffffffc0082d458c: 0a807c09     	and	w9, w0, w0, asr #31
ffffffc0082d4590: 7100001f     	cmp	w0, #0x0
ffffffc0082d4594: 1a8902d5     	csel	w21, w22, w9, eq
ffffffc0082d4598: b4000b08     	cbz	x8, 0xffffffc0082d46f8 <futex_wait_requeue_pi+0x994>
ffffffc0082d459c: 910062f6     	add	x22, x23, #0x18
ffffffc0082d45a0: c8dffec8     	ldar	x8, [x22]
ffffffc0082d45a4: eb0802df     	cmp	x22, x8
ffffffc0082d45a8: 54000ac0     	b.eq	0xffffffc0082d4700 <futex_wait_requeue_pi+0x99c>
ffffffc0082d45ac: f85a03b8     	ldur	x24, [x29, #-0x60]
ffffffc0082d45b0: d10243a8     	sub	x8, x29, #0x90
ffffffc0082d45b4: 91002117     	add	x23, x8, #0x8
ffffffc0082d45b8: c8dffee8     	ldar	x8, [x23]
ffffffc0082d45bc: eb0802ff     	cmp	x23, x8
ffffffc0082d45c0: 540003c0     	b.eq	0xffffffc0082d4638 <futex_wait_requeue_pi+0x8d4>
ffffffc0082d45c4: f85883a8     	ldur	x8, [x29, #-0x78]
ffffffc0082d45c8: 91003309     	add	x9, x24, #0xc
ffffffc0082d45cc: eb09011f     	cmp	x8, x9
ffffffc0082d45d0: 54000260     	b.eq	0xffffffc0082d461c <futex_wait_requeue_pi+0x8b8>
ffffffc0082d45d4: d1004101     	sub	x1, x8, #0x10
ffffffc0082d45d8: c8dffc29     	ldar	x9, [x1]
ffffffc0082d45dc: eb01013f     	cmp	x9, x1
ffffffc0082d45e0: 540001e1     	b.ne	0xffffffc0082d461c <futex_wait_requeue_pi+0x8b8>
ffffffc0082d45e4: b4001037     	cbz	x23, 0xffffffc0082d47e8 <futex_wait_requeue_pi+0xa84>
ffffffc0082d45e8: f85783a3     	ldur	x3, [x29, #-0x88]
ffffffc0082d45ec: b4001063     	cbz	x3, 0xffffffc0082d47f8 <futex_wait_requeue_pi+0xa94>
ffffffc0082d45f0: f9400462     	ldr	x2, [x3, #0x8]
ffffffc0082d45f4: eb17005f     	cmp	x2, x23
ffffffc0082d45f8: 54001081     	b.ne	0xffffffc0082d4808 <futex_wait_requeue_pi+0xaa4>
ffffffc0082d45fc: eb0102ff     	cmp	x23, x1
ffffffc0082d4600: 54000e40     	b.eq	0xffffffc0082d47c8 <futex_wait_requeue_pi+0xa64>
ffffffc0082d4604: eb01007f     	cmp	x3, x1
ffffffc0082d4608: 54000e00     	b.eq	0xffffffc0082d47c8 <futex_wait_requeue_pi+0xa64>
ffffffc0082d460c: d1006108     	sub	x8, x8, #0x18
ffffffc0082d4610: f9000461     	str	x1, [x3, #0x8]
ffffffc0082d4614: a900dd03     	stp	x3, x23, [x8, #0x8]
ffffffc0082d4618: f81783a1     	stur	x1, [x29, #-0x88]
ffffffc0082d461c: aa1703e0     	mov	x0, x23
ffffffc0082d4620: 941f7414     	bl	0xffffffc008ab1670 <__list_del_entry_valid>
ffffffc0082d4624: a977a3a9     	ldp	x9, x8, [x29, #-0x88]
ffffffc0082d4628: f9000528     	str	x8, [x9, #0x8]
ffffffc0082d462c: f9000109     	str	x9, [x8]
ffffffc0082d4630: f81783b7     	stur	x23, [x29, #-0x88]
ffffffc0082d4634: f81803b7     	stur	x23, [x29, #-0x80]
ffffffc0082d4638: aa1603e0     	mov	x0, x22
ffffffc0082d463c: d1001317     	sub	x23, x24, #0x4
ffffffc0082d4640: 941f740c     	bl	0xffffffc008ab1670 <__list_del_entry_valid>
ffffffc0082d4644: a978a3a9     	ldp	x9, x8, [x29, #-0x78]
ffffffc0082d4648: f9000528     	str	x8, [x9, #0x8]
ffffffc0082d464c: f9000109     	str	x9, [x8]
ffffffc0082d4650: f81883b6     	stur	x22, [x29, #-0x78]
ffffffc0082d4654: f81903b6     	stur	x22, [x29, #-0x70]
ffffffc0082d4658: 1400002c     	b	0xffffffc0082d4708 <futex_wait_requeue_pi+0x9a4>
ffffffc0082d465c: 1400002b     	b	0xffffffc0082d4708 <futex_wait_requeue_pi+0x9a4>
ffffffc0082d4660: 52800028     	mov	w8, #0x1        // =1
ffffffc0082d4664: 4b0803e8     	neg	w8, w8
ffffffc0082d4668: b82802ff     	stadd	w8, [x23]
ffffffc0082d466c: f85c03a0     	ldur	x0, [x29, #-0x40]
ffffffc0082d4670: b4000760     	cbz	x0, 0xffffffc0082d475c <futex_wait_requeue_pi+0x9f8>
ffffffc0082d4674: 94000a41     	bl	0xffffffc0082d6f78 <put_pi_state>
ffffffc0082d4678: f81c03bf     	stur	xzr, [x29, #-0x40]
ffffffc0082d467c: 2a1f03e8     	mov	w8, wzr
ffffffc0082d4680: f85a03a9     	ldur	x9, [x29, #-0x60]
ffffffc0082d4684: 089ffd28     	stlrb	w8, [x9]
ffffffc0082d4688: 91006288     	add	x8, x20, #0x18
ffffffc0082d468c: c8dffd09     	ldar	x9, [x8]
ffffffc0082d4690: f1000529     	subs	x9, x9, #0x1
ffffffc0082d4694: b9001a89     	str	w9, [x20, #0x18]
ffffffc0082d4698: 540000e0     	b.eq	0xffffffc0082d46b4 <futex_wait_requeue_pi+0x950>
ffffffc0082d469c: c8dffd09     	ldar	x9, [x8]
ffffffc0082d46a0: b40000a9     	cbz	x9, 0xffffffc0082d46b4 <futex_wait_requeue_pi+0x950>
ffffffc0082d46a4: 310012bf     	cmn	w21, #0x4
ffffffc0082d46a8: 12800148     	mov	w8, #-0xb       // =-11
ffffffc0082d46ac: 1a950118     	csel	w24, w8, w21, eq
ffffffc0082d46b0: 17fffec2     	b	0xffffffc0082d41b8 <futex_wait_requeue_pi+0x454>
ffffffc0082d46b4: 88dffd08     	ldar	w8, [x8]
ffffffc0082d46b8: 35ffff68     	cbnz	w8, 0xffffffc0082d46a4 <futex_wait_requeue_pi+0x940>
ffffffc0082d46bc: d53b4228     	mrs	x8, DAIF
ffffffc0082d46c0: 12190109     	and	w9, w8, #0x80
ffffffc0082d46c4: 35ffff09     	cbnz	w9, 0xffffffc0082d46a4 <futex_wait_requeue_pi+0x940>
ffffffc0082d46c8: 91006296     	add	x22, x20, #0x18
ffffffc0082d46cc: 88dffec8     	ldar	w8, [x22]
ffffffc0082d46d0: 11000508     	add	w8, w8, #0x1
ffffffc0082d46d4: b9001a88     	str	w8, [x20, #0x18]
ffffffc0082d46d8: 52800020     	mov	w0, #0x1        // =1
ffffffc0082d46dc: 9464b5df     	bl	0xffffffc009c01e58 <__schedule>
ffffffc0082d46e0: 88dffec8     	ldar	w8, [x22]
ffffffc0082d46e4: 51000508     	sub	w8, w8, #0x1
ffffffc0082d46e8: b9001a88     	str	w8, [x20, #0x18]
ffffffc0082d46ec: f9400288     	ldr	x8, [x20]
ffffffc0082d46f0: 370ffec8     	tbnz	w8, #0x1, 0xffffffc0082d46c8 <futex_wait_requeue_pi+0x964>
ffffffc0082d46f4: 17ffffec     	b	0xffffffc0082d46a4 <futex_wait_requeue_pi+0x940>
ffffffc0082d46f8: d4210000     	brk	#0x800
ffffffc0082d46fc: 17ffffdc     	b	0xffffffc0082d466c <futex_wait_requeue_pi+0x908>
ffffffc0082d4700: d4210000     	brk	#0x800
ffffffc0082d4704: 17ffffda     	b	0xffffffc0082d466c <futex_wait_requeue_pi+0x908>
ffffffc0082d4708: d503249f     	bti	j
ffffffc0082d470c: 52800028     	mov	w8, #0x1        // =1
ffffffc0082d4710: f98002f1     	prfm	pstl1strm, [x23]
ffffffc0082d4714: 885f7ee9     	ldxr	w9, [x23]
ffffffc0082d4718: 4b080129     	sub	w9, w9, w8
ffffffc0082d471c: 880a7ee9     	stxr	w10, w9, [x23]
ffffffc0082d4720: 35ffffaa     	cbnz	w10, 0xffffffc0082d4714 <futex_wait_requeue_pi+0x9b0>
ffffffc0082d4724: 17ffffd2     	b	0xffffffc0082d466c <futex_wait_requeue_pi+0x908>
ffffffc0082d4728: d0010340     	adrp	x0, 0xffffffc00a33e000 <max_tt_usecs+0x533a>
ffffffc0082d472c: 913c5c00     	add	x0, x0, #0xf17
ffffffc0082d4730: 97fd7836     	bl	0xffffffc008232808 <printk>
ffffffc0082d4734: d4210000     	brk	#0x800
ffffffc0082d4738: f0010200     	adrp	x0, 0xffffffc00a317000 <hci_reset_dev.hw_err+0x12c63>
ffffffc0082d473c: 913a3000     	add	x0, x0, #0xe8c
ffffffc0082d4740: 97fd7832     	bl	0xffffffc008232808 <printk>
ffffffc0082d4744: d4210000     	brk	#0x800
ffffffc0082d4748: f00107a0     	adrp	x0, 0xffffffc00a3cb000 <stat_nam.17992+0x2fd75>
ffffffc0082d474c: 910f8000     	add	x0, x0, #0x3e0
ffffffc0082d4750: aa1503e1     	mov	x1, x21
ffffffc0082d4754: 97fd782d     	bl	0xffffffc008232808 <printk>
ffffffc0082d4758: d4210000     	brk	#0x800
ffffffc0082d475c: d4210000     	brk	#0x800
ffffffc0082d4760: d503249f     	bti	j
ffffffc0082d4764: aa1f03e9     	mov	x9, xzr
ffffffc0082d4768: 5280002a     	mov	w10, #0x1       // =1
ffffffc0082d476c: f9800111     	prfm	pstl1strm, [x8]
ffffffc0082d4770: 885ffd01     	ldaxr	w1, [x8]
ffffffc0082d4774: 4a09002b     	eor	w11, w1, w9
ffffffc0082d4778: 3500006b     	cbnz	w11, 0xffffffc0082d4784 <futex_wait_requeue_pi+0xa20>
ffffffc0082d477c: 880b7d0a     	stxr	w11, w10, [x8]
ffffffc0082d4780: 35ffff8b     	cbnz	w11, 0xffffffc0082d4770 <futex_wait_requeue_pi+0xa0c>
ffffffc0082d4784: 34ffd441     	cbz	w1, 0xffffffc0082d420c <futex_wait_requeue_pi+0x4a8>
ffffffc0082d4788: aa0803e0     	mov	x0, x8
ffffffc0082d478c: 97fd402b     	bl	0xffffffc008224838 <queued_spin_lock_slowpath>
ffffffc0082d4790: 17fffe9f     	b	0xffffffc0082d420c <futex_wait_requeue_pi+0x4a8>
ffffffc0082d4794: d503249f     	bti	j
ffffffc0082d4798: aa1f03e8     	mov	x8, xzr
ffffffc0082d479c: 52800029     	mov	w9, #0x1        // =1
ffffffc0082d47a0: f98002d1     	prfm	pstl1strm, [x22]
ffffffc0082d47a4: 885ffec1     	ldaxr	w1, [x22]
ffffffc0082d47a8: 4a08002a     	eor	w10, w1, w8
ffffffc0082d47ac: 3500006a     	cbnz	w10, 0xffffffc0082d47b8 <futex_wait_requeue_pi+0xa54>
ffffffc0082d47b0: 880a7ec9     	stxr	w10, w9, [x22]
ffffffc0082d47b4: 35ffff8a     	cbnz	w10, 0xffffffc0082d47a4 <futex_wait_requeue_pi+0xa40>
ffffffc0082d47b8: 34ffd501     	cbz	w1, 0xffffffc0082d4258 <futex_wait_requeue_pi+0x4f4>
ffffffc0082d47bc: aa1603e0     	mov	x0, x22
ffffffc0082d47c0: 97fd401e     	bl	0xffffffc008224838 <queued_spin_lock_slowpath>
ffffffc0082d47c4: 17fffea5     	b	0xffffffc0082d4258 <futex_wait_requeue_pi+0x4f4>
ffffffc0082d47c8: 90010700     	adrp	x0, 0xffffffc00a3b4000 <stat_nam.17992+0x18d75>
ffffffc0082d47cc: 910e1800     	add	x0, x0, #0x386
ffffffc0082d47d0: aa1703e2     	mov	x2, x23
ffffffc0082d47d4: 97fd780d     	bl	0xffffffc008232808 <printk>
ffffffc0082d47d8: d4210000     	brk	#0x800
ffffffc0082d47dc: d503249f     	bti	j
ffffffc0082d47e0: 52801408     	mov	w8, #0xa0       // =160
ffffffc0082d47e4: 17fffe8e     	b	0xffffffc0082d421c <futex_wait_requeue_pi+0x4b8>
ffffffc0082d47e8: d0010340     	adrp	x0, 0xffffffc00a33e000 <max_tt_usecs+0x533a>
ffffffc0082d47ec: 913c5c00     	add	x0, x0, #0xf17
ffffffc0082d47f0: 97fd7806     	bl	0xffffffc008232808 <printk>
ffffffc0082d47f4: d4210000     	brk	#0x800
ffffffc0082d47f8: f0010200     	adrp	x0, 0xffffffc00a317000 <hci_reset_dev.hw_err+0x12c63>
ffffffc0082d47fc: 913a3000     	add	x0, x0, #0xe8c
ffffffc0082d4800: 97fd7802     	bl	0xffffffc008232808 <printk>
ffffffc0082d4804: d4210000     	brk	#0x800
ffffffc0082d4808: f00107a0     	adrp	x0, 0xffffffc00a3cb000 <stat_nam.17992+0x2fd75>
ffffffc0082d480c: 910f8000     	add	x0, x0, #0x3e0
ffffffc0082d4810: aa1703e1     	mov	x1, x23
ffffffc0082d4814: 97fd77fd     	bl	0xffffffc008232808 <printk>
ffffffc0082d4818: d4210000     	brk	#0x800
ffffffc0082d481c: f8bfc109     	ldapr	x9, [x8]
ffffffc0082d4820: f8bfc109     	ldapr	x9, [x8]
ffffffc0082d4824: b8bfc108     	ldapr	w8, [x8]
ffffffc0082d4828: f8bfc109     	ldapr	x9, [x8]
ffffffc0082d482c: f8bfc109     	ldapr	x9, [x8]
ffffffc0082d4830: b8bfc129     	ldapr	w9, [x9]
ffffffc0082d4834: f8bfc2a8     	ldapr	x8, [x21]
ffffffc0082d4838: f8bfc029     	ldapr	x9, [x1]
ffffffc0082d483c: f8bfc109     	ldapr	x9, [x8]
ffffffc0082d4840: f8bfc109     	ldapr	x9, [x8]
ffffffc0082d4844: b8bfc129     	ldapr	w9, [x9]
ffffffc0082d4848: d5184608     	msr	ICC_PMR_EL1, x8
ffffffc0082d484c: b8bfc108     	ldapr	w8, [x8]
ffffffc0082d4850: d5184608     	msr	ICC_PMR_EL1, x8
ffffffc0082d4854: f8bfc109     	ldapr	x9, [x8]
ffffffc0082d4858: f8bfc109     	ldapr	x9, [x8]
ffffffc0082d485c: f8bfc109     	ldapr	x9, [x8]
ffffffc0082d4860: f8bfc109     	ldapr	x9, [x8]
ffffffc0082d4864: b8bfc108     	ldapr	w8, [x8]
ffffffc0082d4868: d5384608     	mrs	x8, ICC_PMR_EL1
ffffffc0082d486c: 521b0909     	eor	w9, w8, #0xe0
ffffffc0082d4870: b8bfc2a8     	ldapr	w8, [x21]
ffffffc0082d4874: b8bfc2a8     	ldapr	w8, [x21]
ffffffc0082d4878: b8bfc108     	ldapr	w8, [x8]
ffffffc0082d487c: d5384608     	mrs	x8, ICC_PMR_EL1
ffffffc0082d4880: 521b0909     	eor	w9, w8, #0xe0
ffffffc0082d4884: b8bfc2c8     	ldapr	w8, [x22]
ffffffc0082d4888: b8bfc2c8     	ldapr	w8, [x22]
ffffffc0082d488c: b8bfc108     	ldapr	w8, [x8]
ffffffc0082d4890: d5384608     	mrs	x8, ICC_PMR_EL1
ffffffc0082d4894: 521b0909     	eor	w9, w8, #0xe0
ffffffc0082d4898: b8bfc2c8     	ldapr	w8, [x22]
ffffffc0082d489c: b8bfc2c8     	ldapr	w8, [x22]
ffffffc0082d48a0: b8bfc108     	ldapr	w8, [x8]
ffffffc0082d48a4: d5384608     	mrs	x8, ICC_PMR_EL1
ffffffc0082d48a8: 521b0909     	eor	w9, w8, #0xe0
ffffffc0082d48ac: b8bfc2c8     	ldapr	w8, [x22]
ffffffc0082d48b0: b8bfc2c8     	ldapr	w8, [x22]
ffffffc0082d48b4: b8bfc108     	ldapr	w8, [x8]
ffffffc0082d48b8: d5384608     	mrs	x8, ICC_PMR_EL1
ffffffc0082d48bc: 521b0909     	eor	w9, w8, #0xe0
ffffffc0082d48c0: b8bfc2c8     	ldapr	w8, [x22]
ffffffc0082d48c4: b8bfc2c8     	ldapr	w8, [x22]
ffffffc0082d48c8: f8bfc2c8     	ldapr	x8, [x22]
ffffffc0082d48cc: f8bfc2e8     	ldapr	x8, [x23]
ffffffc0082d48d0: f8bfc029     	ldapr	x9, [x1]
ffffffc0082d48d4: f8bfc109     	ldapr	x9, [x8]
ffffffc0082d48d8: f8bfc109     	ldapr	x9, [x8]
ffffffc0082d48dc: b8bfc108     	ldapr	w8, [x8]
ffffffc0082d48e0: d5384608     	mrs	x8, ICC_PMR_EL1
ffffffc0082d48e4: 521b0909     	eor	w9, w8, #0xe0
ffffffc0082d48e8: b8bfc2c8     	ldapr	w8, [x22]
ffffffc0082d48ec: b8bfc2c8     	ldapr	w8, [x22]
