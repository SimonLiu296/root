
C:\Users\QingJ\Desktop\root\work\boot_out\output.elf:	file format elf64-littleaarch64

Disassembly of section .kernel:

ffffffc0080bbc98 <do_el0_svc>:
ffffffc0080bbc98: d503233f     	paciasp
ffffffc0080bbc9c: f800865e     	str	x30, [x18], #0x8
ffffffc0080bbca0: a9bf7bfd     	stp	x29, x30, [sp, #-0x10]!
ffffffc0080bbca4: 910003fd     	mov	x29, sp
ffffffc0080bbca8: 1400000a     	b	0xffffffc0080bbcd0 <do_el0_svc+0x38>
ffffffc0080bbcac: d503201f     	nop
ffffffc0080bbcb0: b9404001     	ldr	w1, [x0, #0x40]
ffffffc0080bbcb4: f0011aa2     	adrp	x2, 0xffffffc00a412000 <linux_banner+0x48>
ffffffc0080bbcb8: 9125e042     	add	x2, x2, #0x978
ffffffc0080bbcbc: 9400001d     	bl	0xffffffc0080bbd30 <el0_svc_common>
ffffffc0080bbcc0: a8c17bfd     	ldp	x29, x30, [sp], #0x10
ffffffc0080bbcc4: f85f8e5e     	ldr	x30, [x18, #-0x8]!
ffffffc0080bbcc8: d50323bf     	autiasp
ffffffc0080bbccc: d65f03c0     	ret
ffffffc0080bbcd0: d503249f     	bti	j
ffffffc0080bbcd4: 900163a8     	adrp	x8, 0xffffffc00ad2f000 <reset_devices>
ffffffc0080bbcd8: f9430d08     	ldr	x8, [x8, #0x618]
ffffffc0080bbcdc: 36b7fea8     	tbz	w8, #0x16, 0xffffffc0080bbcb0 <do_el0_svc+0x18>
ffffffc0080bbce0: d503249f     	bti	j
ffffffc0080bbce4: d5384108     	mrs	x8, SP_EL0
ffffffc0080bbce8: 1400000a     	b	0xffffffc0080bbd10 <do_el0_svc+0x78>
ffffffc0080bbcec: 14000009     	b	0xffffffc0080bbd10 <do_el0_svc+0x78>
ffffffc0080bbcf0: 52a01009     	mov	w9, #0x800000   // =8388608
ffffffc0080bbcf4: f829111f     	stclr	x9, [x8]
ffffffc0080bbcf8: d5381049     	mrs	x9, CPACR_EL1
ffffffc0080bbcfc: 926ef928     	and	x8, x9, #0xfffffffffffdffff
ffffffc0080bbd00: eb09011f     	cmp	x8, x9
ffffffc0080bbd04: 54fffd60     	b.eq	0xffffffc0080bbcb0 <do_el0_svc+0x18>
ffffffc0080bbd08: d5181048     	msr	CPACR_EL1, x8
ffffffc0080bbd0c: 17ffffe9     	b	0xffffffc0080bbcb0 <do_el0_svc+0x18>
ffffffc0080bbd10: d503249f     	bti	j
ffffffc0080bbd14: 52a01009     	mov	w9, #0x800000   // =8388608
ffffffc0080bbd18: f9800111     	prfm	pstl1strm, [x8]
ffffffc0080bbd1c: c85f7d0a     	ldxr	x10, [x8]
ffffffc0080bbd20: 8a29014a     	bic	x10, x10, x9
ffffffc0080bbd24: c80b7d0a     	stxr	w11, x10, [x8]
ffffffc0080bbd28: 35ffffab     	cbnz	w11, 0xffffffc0080bbd1c <do_el0_svc+0x84>
ffffffc0080bbd2c: 17fffff3     	b	0xffffffc0080bbcf8 <do_el0_svc+0x60>
