
C:\Users\QingJ\Desktop\root\work\boot_out\output.elf:	file format elf64-littleaarch64

Disassembly of section .kernel:

ffffffc008604e64 <__arm64_sys_pselect6>:
ffffffc008604e64: d503233f     	paciasp
ffffffc008604e68: d10283ff     	sub	sp, sp, #0xa0
ffffffc008604e6c: f800865e     	str	x30, [x18], #0x8
ffffffc008604e70: a9047bfd     	stp	x29, x30, [sp, #0x40]
ffffffc008604e74: a9056ffc     	stp	x28, x27, [sp, #0x50]
ffffffc008604e78: a90667fa     	stp	x26, x25, [sp, #0x60]
ffffffc008604e7c: a9075ff8     	stp	x24, x23, [sp, #0x70]
ffffffc008604e80: a90857f6     	stp	x22, x21, [sp, #0x80]
ffffffc008604e84: a9094ff4     	stp	x20, x19, [sp, #0x90]
ffffffc008604e88: 910103fd     	add	x29, sp, #0x40
ffffffc008604e8c: f000fe88     	adrp	x8, 0xffffffc00a5d7000 <idle_sched_class+0x20>
ffffffc008604e90: f9426908     	ldr	x8, [x8, #0x4d0]
ffffffc008604e94: f81f83a8     	stur	x8, [x29, #-0x8]
ffffffc008604e98: f9401401     	ldr	x1, [x0, #0x28]
ffffffc008604e9c: b9400014     	ldr	w20, [x0]
ffffffc008604ea0: a940d815     	ldp	x21, x22, [x0, #0x8]
ffffffc008604ea4: a941cc17     	ldp	x23, x19, [x0, #0x18]
ffffffc008604ea8: 910023e0     	add	x0, sp, #0x8
ffffffc008604eac: a900ffff     	stp	xzr, xzr, [sp, #0x8]
ffffffc008604eb0: 94000060     	bl	0xffffffc008605030 <get_sigset_argpack>
ffffffc008604eb4: 34000220     	cbz	w0, 0xffffffc008604ef8 <__arm64_sys_pselect6+0x94>
ffffffc008604eb8: 928001a0     	mov	x0, #-0xe       // =-14
ffffffc008604ebc: f000fe89     	adrp	x9, 0xffffffc00a5d7000 <idle_sched_class+0x20>
ffffffc008604ec0: f85f83a8     	ldur	x8, [x29, #-0x8]
ffffffc008604ec4: f9426929     	ldr	x9, [x9, #0x4d0]
ffffffc008604ec8: eb08013f     	cmp	x9, x8
ffffffc008604ecc: 54000b01     	b.ne	0xffffffc00860502c <__arm64_sys_pselect6+0x1c8>
ffffffc008604ed0: a9447bfd     	ldp	x29, x30, [sp, #0x40]
ffffffc008604ed4: a9494ff4     	ldp	x20, x19, [sp, #0x90]
ffffffc008604ed8: a94857f6     	ldp	x22, x21, [sp, #0x80]
ffffffc008604edc: a9475ff8     	ldp	x24, x23, [sp, #0x70]
ffffffc008604ee0: a94667fa     	ldp	x26, x25, [sp, #0x60]
ffffffc008604ee4: a9456ffc     	ldp	x28, x27, [sp, #0x50]
ffffffc008604ee8: f85f8e5e     	ldr	x30, [x18, #-0x8]!
ffffffc008604eec: 910283ff     	add	sp, sp, #0xa0
ffffffc008604ef0: d50323bf     	autiasp
ffffffc008604ef4: d65f03c0     	ret
ffffffc008604ef8: a940e7f8     	ldp	x24, x25, [sp, #0x8]
ffffffc008604efc: a901ffff     	stp	xzr, xzr, [sp, #0x18]
ffffffc008604f00: b40006d3     	cbz	x19, 0xffffffc008604fd8 <__arm64_sys_pselect6+0x174>
ffffffc008604f04: d10063a0     	sub	x0, x29, #0x18
ffffffc008604f08: 52800202     	mov	w2, #0x10       // =16
ffffffc008604f0c: aa1303e1     	mov	x1, x19
ffffffc008604f10: a93effbf     	stp	xzr, xzr, [x29, #-0x18]
ffffffc008604f14: 97f24b02     	bl	0xffffffc008297b1c <_copy_from_user.6661>
ffffffc008604f18: 35fffd00     	cbnz	w0, 0xffffffc008604eb8 <__arm64_sys_pselect6+0x54>
ffffffc008604f1c: d5384108     	mrs	x8, SP_EL0
ffffffc008604f20: a97ea7ba     	ldp	x26, x9, [x29, #-0x18]
ffffffc008604f24: f9400108     	ldr	x8, [x8]
ffffffc008604f28: 928002a0     	mov	x0, #-0x16      // =-22
ffffffc008604f2c: 92407d2a     	and	x10, x9, #0xffffffff
ffffffc008604f30: f26a011f     	tst	x8, #0x400000
ffffffc008604f34: 9a8a013c     	csel	x28, x9, x10, eq
ffffffc008604f38: b7fffc3a     	tbnz	x26, #0x3f, 0xffffffc008604ebc <__arm64_sys_pselect6+0x58>
ffffffc008604f3c: 52993ffb     	mov	w27, #0xc9ff    // =51711
ffffffc008604f40: 72a7735b     	movk	w27, #0x3b9a, lsl #16
ffffffc008604f44: 91000768     	add	x8, x27, #0x1
ffffffc008604f48: eb08039f     	cmp	x28, x8
ffffffc008604f4c: 54fffb82     	b.hs	0xffffffc008604ebc <__arm64_sys_pselect6+0x58>
ffffffc008604f50: aa1a0388     	orr	x8, x28, x26
ffffffc008604f54: b4000468     	cbz	x8, 0xffffffc008604fe0 <__arm64_sys_pselect6+0x17c>
ffffffc008604f58: 910063e0     	add	x0, sp, #0x18
ffffffc008604f5c: 97f2875f     	bl	0xffffffc0082a6cd8 <ktime_get_ts64>
ffffffc008604f60: a941a7ea     	ldp	x10, x9, [sp, #0x18]
ffffffc008604f64: 8b090389     	add	x9, x28, x9
ffffffc008604f68: 8b0a0348     	add	x8, x26, x10
ffffffc008604f6c: eb1b013f     	cmp	x9, x27
ffffffc008604f70: f81e83a9     	stur	x9, [x29, #-0x18]
ffffffc008604f74: 5400010d     	b.le	0xffffffc008604f94 <__arm64_sys_pselect6+0x130>
ffffffc008604f78: 92993feb     	mov	x11, #-0xca00   // =-51712
ffffffc008604f7c: f2b88cab     	movk	x11, #0xc465, lsl #16
ffffffc008604f80: 8b0b0129     	add	x9, x9, x11
ffffffc008604f84: eb1b013f     	cmp	x9, x27
ffffffc008604f88: 91000508     	add	x8, x8, #0x1
ffffffc008604f8c: f81e83a9     	stur	x9, [x29, #-0x18]
ffffffc008604f90: 54ffff8c     	b.gt	0xffffffc008604f80 <__arm64_sys_pselect6+0x11c>
ffffffc008604f94: b6f800c9     	tbz	x9, #0x3f, 0xffffffc008604fac <__arm64_sys_pselect6+0x148>
ffffffc008604f98: 8b090369     	add	x9, x27, x9
ffffffc008604f9c: 91000529     	add	x9, x9, #0x1
ffffffc008604fa0: d1000508     	sub	x8, x8, #0x1
ffffffc008604fa4: f81e83a9     	stur	x9, [x29, #-0x18]
ffffffc008604fa8: b7ffff89     	tbnz	x9, #0x3f, 0xffffffc008604f98 <__arm64_sys_pselect6+0x134>
ffffffc008604fac: eb0a011f     	cmp	x8, x10
ffffffc008604fb0: 1a9fa7eb     	cset	w11, lt
ffffffc008604fb4: eb1a011f     	cmp	x8, x26
ffffffc008604fb8: 1a9fa7ec     	cset	w12, lt
ffffffc008604fbc: 2a0c016b     	orr	w11, w11, w12
ffffffc008604fc0: 92f0000a     	mov	x10, #0x7fffffffffffffff // =9223372036854775807
ffffffc008604fc4: 7100017f     	cmp	w11, #0x0
ffffffc008604fc8: 9a881148     	csel	x8, x10, x8, ne
ffffffc008604fcc: 9a8913e9     	csel	x9, xzr, x9, ne
ffffffc008604fd0: a901a7e8     	stp	x8, x9, [sp, #0x18]
ffffffc008604fd4: 14000004     	b	0xffffffc008604fe4 <__arm64_sys_pselect6+0x180>
ffffffc008604fd8: aa1f03fa     	mov	x26, xzr
ffffffc008604fdc: 14000003     	b	0xffffffc008604fe8 <__arm64_sys_pselect6+0x184>
ffffffc008604fe0: a901ffff     	stp	xzr, xzr, [sp, #0x18]
ffffffc008604fe4: 910063fa     	add	x26, sp, #0x18
ffffffc008604fe8: aa1803e0     	mov	x0, x24
ffffffc008604fec: aa1903e1     	mov	x1, x25
ffffffc008604ff0: 97edfbcd     	bl	0xffffffc008183f24 <set_user_sigmask>
ffffffc008604ff4: 35000180     	cbnz	w0, 0xffffffc008605024 <__arm64_sys_pselect6+0x1c0>
ffffffc008604ff8: 2a1403e0     	mov	w0, w20
ffffffc008604ffc: aa1503e1     	mov	x1, x21
ffffffc008605000: aa1603e2     	mov	x2, x22
ffffffc008605004: aa1703e3     	mov	x3, x23
ffffffc008605008: aa1a03e4     	mov	x4, x26
ffffffc00860500c: 97fffa3b     	bl	0xffffffc0086038f8 <core_sys_select>
ffffffc008605010: 2a0003e3     	mov	w3, w0
ffffffc008605014: 910063e0     	add	x0, sp, #0x18
ffffffc008605018: 52800042     	mov	w2, #0x2        // =2
ffffffc00860501c: aa1303e1     	mov	x1, x19
ffffffc008605020: 97fffb18     	bl	0xffffffc008603c80 <poll_select_finish>
ffffffc008605024: 93407c00     	sxtw	x0, w0
ffffffc008605028: 17ffffa5     	b	0xffffffc008604ebc <__arm64_sys_pselect6+0x58>
ffffffc00860502c: 9448d10a     	bl	0xffffffc009839454 <__stack_chk_fail>
