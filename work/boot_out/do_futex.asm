
C:\Users\QingJ\Desktop\root\work\boot_out\output.elf:	file format elf64-littleaarch64

Disassembly of section .kernel:

ffffffc0082cc6c8 <do_futex>:
ffffffc0082cc6c8: d503233f     	paciasp
ffffffc0082cc6cc: d10303ff     	sub	sp, sp, #0xc0
ffffffc0082cc6d0: f800865e     	str	x30, [x18], #0x8
ffffffc0082cc6d4: a9067bfd     	stp	x29, x30, [sp, #0x60]
ffffffc0082cc6d8: a9076ffc     	stp	x28, x27, [sp, #0x70]
ffffffc0082cc6dc: a90867fa     	stp	x26, x25, [sp, #0x80]
ffffffc0082cc6e0: a9095ff8     	stp	x24, x23, [sp, #0x90]
ffffffc0082cc6e4: a90a57f6     	stp	x22, x21, [sp, #0xa0]
ffffffc0082cc6e8: a90b4ff4     	stp	x20, x19, [sp, #0xb0]
ffffffc0082cc6ec: 910183fd     	add	x29, sp, #0x60
ffffffc0082cc6f0: f0011848     	adrp	x8, 0xffffffc00a5d7000 <idle_sched_class+0x20>
ffffffc0082cc6f4: f9426908     	ldr	x8, [x8, #0x4d0]
ffffffc0082cc6f8: 2a0503f6     	mov	w22, w5
ffffffc0082cc6fc: aa0403f5     	mov	x21, x4
ffffffc0082cc700: aa0303f7     	mov	x23, x3
ffffffc0082cc704: 2a0203f3     	mov	w19, w2
ffffffc0082cc708: 2a0103f9     	mov	w25, w1
ffffffc0082cc70c: aa0003f4     	mov	x20, x0
ffffffc0082cc710: 2a1f03e5     	mov	w5, wzr
ffffffc0082cc714: 72177438     	ands	w24, w1, #0xfffffe7f
ffffffc0082cc718: f81f83a8     	stur	x8, [x29, #-0x8]
ffffffc0082cc71c: 293e1bbf     	stp	wzr, w6, [x29, #-0x10]
ffffffc0082cc720: 540007e1     	b.ne	0xffffffc0082cc81c <do_futex+0x154>
ffffffc0082cc724: d5384108     	mrs	x8, SP_EL0
ffffffc0082cc728: f9400109     	ldr	x9, [x8]
ffffffc0082cc72c: 926a013a     	and	x26, x9, #0x400000
ffffffc0082cc730: b4001d15     	cbz	x21, 0xffffffc0082ccad0 <do_futex+0x408>
ffffffc0082cc734: 5297dde9     	mov	w9, #0xbeef     // =48879
ffffffc0082cc738: 72bbd5a9     	movk	w9, #0xdead, lsl #16
ffffffc0082cc73c: 6b0900df     	cmp	w6, w9
ffffffc0082cc740: 54001c81     	b.ne	0xffffffc0082ccad0 <do_futex+0x408>
ffffffc0082cc744: 52800aab     	mov	w11, #0x55      // =85
ffffffc0082cc748: 53105eaa     	ubfx	w10, w21, #16, #8
ffffffc0082cc74c: 0a55456b     	and	w11, w11, w21, lsr #17
ffffffc0082cc750: 5280066c     	mov	w12, #0x33      // =51
ffffffc0082cc754: 4b0b014b     	sub	w11, w10, w11
ffffffc0082cc758: 928fffed     	mov	x13, #-0x8000   // =-32768
ffffffc0082cc75c: 0a0c016f     	and	w15, w11, w12
ffffffc0082cc760: 0a4b098b     	and	w11, w12, w11, lsr #2
ffffffc0082cc764: f2bfe00d     	movk	x13, #0xff00, lsl #16
ffffffc0082cc768: 0b0f016b     	add	w11, w11, w15
ffffffc0082cc76c: 52bfc00e     	mov	w14, #-0x2000000 // =-33554432
ffffffc0082cc770: 8a0d02ad     	and	x13, x21, x13
ffffffc0082cc774: 0b4b116b     	add	w11, w11, w11, lsr #4
ffffffc0082cc778: eb0e01bf     	cmp	x13, x14
ffffffc0082cc77c: 12000d6b     	and	w11, w11, #0xf
ffffffc0082cc780: 54001601     	b.ne	0xffffffc0082cca40 <do_futex+0x378>
ffffffc0082cc784: 7100057f     	cmp	w11, #0x1
ffffffc0082cc788: 540015c1     	b.ne	0xffffffc0082cca40 <do_futex+0x378>
ffffffc0082cc78c: d0015a89     	adrp	x9, 0xffffffc00ae1e000 <hash_table.13018+0x3360>
ffffffc0082cc790: f9478528     	ldr	x8, [x9, #0xf08]
ffffffc0082cc794: 9100050b     	add	x11, x8, #0x1
ffffffc0082cc798: f2403ea8     	ands	x8, x21, #0xffff
ffffffc0082cc79c: f907852b     	str	x11, [x9, #0xf08]
ffffffc0082cc7a0: 54000120     	b.eq	0xffffffc0082cc7c4 <do_futex+0xfc>
ffffffc0082cc7a4: 120062a5     	and	w5, w21, #0x1ffffff
ffffffc0082cc7a8: 3400020a     	cbz	w10, 0xffffffc0082cc7e8 <do_futex+0x120>
ffffffc0082cc7ac: 5ac00149     	rbit	w9, w10
ffffffc0082cc7b0: 5ac01129     	clz	w9, w9
ffffffc0082cc7b4: 7100193f     	cmp	w9, #0x6
ffffffc0082cc7b8: 540001c8     	b.hi	0xffffffc0082cc7f0 <do_futex+0x128>
ffffffc0082cc7bc: 11000529     	add	w9, w9, #0x1
ffffffc0082cc7c0: 1400000d     	b	0xffffffc0082cc7f4 <do_futex+0x12c>
ffffffc0082cc7c4: d354ff49     	lsr	x9, x26, #20
ffffffc0082cc7c8: d0015a8b     	adrp	x11, 0xffffffc00ae1e000 <hash_table.13018+0x3360>
ffffffc0082cc7cc: d27e0129     	eor	x9, x9, #0x4
ffffffc0082cc7d0: 913c416b     	add	x11, x11, #0xf10
ffffffc0082cc7d4: b869696c     	ldr	w12, [x11, x9]
ffffffc0082cc7d8: 1100058c     	add	w12, w12, #0x1
ffffffc0082cc7dc: b829696c     	str	w12, [x11, x9]
ffffffc0082cc7e0: 120062a5     	and	w5, w21, #0x1ffffff
ffffffc0082cc7e4: 35fffe4a     	cbnz	w10, 0xffffffc0082cc7ac <do_futex+0xe4>
ffffffc0082cc7e8: 2a1f03e9     	mov	w9, wzr
ffffffc0082cc7ec: 14000002     	b	0xffffffc0082cc7f4 <do_futex+0x12c>
ffffffc0082cc7f0: 52800109     	mov	w9, #0x8        // =8
ffffffc0082cc7f4: d356ff4a     	lsr	x10, x26, #22
ffffffc0082cc7f8: f0015a8b     	adrp	x11, 0xffffffc00ae1f000 <rsc_lock_boost_trace+0xe8>
ffffffc0082cc7fc: 9104916b     	add	x11, x11, #0x124
ffffffc0082cc800: d240014a     	eor	x10, x10, #0x1
ffffffc0082cc804: 8b294d6b     	add	x11, x11, w9, uxtw #3
ffffffc0082cc808: d37ef54a     	lsl	x10, x10, #2
ffffffc0082cc80c: b86a696c     	ldr	w12, [x11, x10]
ffffffc0082cc810: 1100058c     	add	w12, w12, #0x1
ffffffc0082cc814: b82a696c     	str	w12, [x11, x10]
ffffffc0082cc818: b40003c8     	cbz	x8, 0xffffffc0082cc890 <do_futex+0x1c8>
ffffffc0082cc81c: 37380099     	tbnz	w25, #0x7, 0xffffffc0082cc82c <do_futex+0x164>
ffffffc0082cc820: b85f03a8     	ldur	w8, [x29, #-0x10]
ffffffc0082cc824: 32000108     	orr	w8, w8, #0x1
ffffffc0082cc828: b81f03a8     	stur	w8, [x29, #-0x10]
ffffffc0082cc82c: 36400119     	tbz	w25, #0x8, 0xffffffc0082cc84c <do_futex+0x184>
ffffffc0082cc830: b85f03a8     	ldur	w8, [x29, #-0x10]
ffffffc0082cc834: 12803049     	mov	w9, #-0x183     // =-387
ffffffc0082cc838: 0a090329     	and	w9, w25, w9
ffffffc0082cc83c: 7100253f     	cmp	w9, #0x9
ffffffc0082cc840: 321f0108     	orr	w8, w8, #0x2
ffffffc0082cc844: b81f03a8     	stur	w8, [x29, #-0x10]
ffffffc0082cc848: 54000201     	b.ne	0xffffffc0082cc888 <do_futex+0x1c0>
ffffffc0082cc84c: d503201f     	nop
ffffffc0082cc850: 7100331f     	cmp	w24, #0xc
ffffffc0082cc854: 928004a0     	mov	x0, #-0x26      // =-38
ffffffc0082cc858: 54000d48     	b.hi	0xffffffc0082cca00 <do_futex+0x338>
ffffffc0082cc85c: b0010969     	adrp	x9, 0xffffffc00a3f9000 <f_midi_longname+0x2bc5f>
ffffffc0082cc860: 2a1803e8     	mov	w8, w24
ffffffc0082cc864: 91172129     	add	x9, x9, #0x5c8
ffffffc0082cc868: 1000000a     	adr	x10, 0xffffffc0082cc868 <do_futex+0x1a0>
ffffffc0082cc86c: b8a8792b     	ldrsw	x11, [x9, x8, lsl #2]
ffffffc0082cc870: 8b0b014a     	add	x10, x10, x11
ffffffc0082cc874: d61f0140     	br	x10
ffffffc0082cc878: d503249f     	bti	j
ffffffc0082cc87c: 12800004     	mov	w4, #-0x1       // =-1
ffffffc0082cc880: b81f43a4     	stur	w4, [x29, #-0xc]
ffffffc0082cc884: 14000059     	b	0xffffffc0082cc9e8 <do_futex+0x320>
ffffffc0082cc888: 928004a0     	mov	x0, #-0x26      // =-38
ffffffc0082cc88c: 1400005d     	b	0xffffffc0082cca00 <do_futex+0x338>
ffffffc0082cc890: 2a0903e8     	mov	w8, w9
ffffffc0082cc894: f0015a89     	adrp	x9, 0xffffffc00ae1f000 <rsc_lock_boost_trace+0xe8>
ffffffc0082cc898: 9105b129     	add	x9, x9, #0x16c
ffffffc0082cc89c: 8b080d28     	add	x8, x9, x8, lsl #3
ffffffc0082cc8a0: b86a6909     	ldr	w9, [x8, x10]
ffffffc0082cc8a4: 11000529     	add	w9, w9, #0x1
ffffffc0082cc8a8: b82a6909     	str	w9, [x8, x10]
ffffffc0082cc8ac: 373ffc19     	tbnz	w25, #0x7, 0xffffffc0082cc82c <do_futex+0x164>
ffffffc0082cc8b0: 17ffffdc     	b	0xffffffc0082cc820 <do_futex+0x158>
ffffffc0082cc8b4: d503249f     	bti	j
ffffffc0082cc8b8: b85f03a1     	ldur	w1, [x29, #-0x10]
ffffffc0082cc8bc: 12800008     	mov	w8, #-0x1       // =-1
ffffffc0082cc8c0: aa1403e0     	mov	x0, x20
ffffffc0082cc8c4: 2a1303e2     	mov	w2, w19
ffffffc0082cc8c8: aa1703e3     	mov	x3, x23
ffffffc0082cc8cc: aa1503e4     	mov	x4, x21
ffffffc0082cc8d0: b81f43a8     	stur	w8, [x29, #-0xc]
ffffffc0082cc8d4: 94001d24     	bl	0xffffffc0082d3d64 <futex_wait_requeue_pi>
ffffffc0082cc8d8: 14000049     	b	0xffffffc0082cc9fc <do_futex+0x334>
ffffffc0082cc8dc: d503249f     	bti	j
ffffffc0082cc8e0: b85f03a1     	ldur	w1, [x29, #-0x10]
ffffffc0082cc8e4: aa1403e0     	mov	x0, x20
ffffffc0082cc8e8: aa1503e2     	mov	x2, x21
ffffffc0082cc8ec: 2a1303e3     	mov	w3, w19
ffffffc0082cc8f0: 2a1603e4     	mov	w4, w22
ffffffc0082cc8f4: aa1f03e5     	mov	x5, xzr
ffffffc0082cc8f8: 14000028     	b	0xffffffc0082cc998 <do_futex+0x2d0>
ffffffc0082cc8fc: d503249f     	bti	j
ffffffc0082cc900: b85f03a1     	ldur	w1, [x29, #-0x10]
ffffffc0082cc904: aa1403e0     	mov	x0, x20
ffffffc0082cc908: aa1703e2     	mov	x2, x23
ffffffc0082cc90c: 2a1f03e3     	mov	w3, wzr
ffffffc0082cc910: 94001788     	bl	0xffffffc0082d2730 <futex_lock_pi>
ffffffc0082cc914: 1400003a     	b	0xffffffc0082cc9fc <do_futex+0x334>
ffffffc0082cc918: d503249f     	bti	j
ffffffc0082cc91c: b85f03a1     	ldur	w1, [x29, #-0x10]
ffffffc0082cc920: d10033a5     	sub	x5, x29, #0xc
ffffffc0082cc924: 52800026     	mov	w6, #0x1        // =1
ffffffc0082cc928: aa1403e0     	mov	x0, x20
ffffffc0082cc92c: aa1503e2     	mov	x2, x21
ffffffc0082cc930: 2a1303e3     	mov	w3, w19
ffffffc0082cc934: 2a1603e4     	mov	w4, w22
ffffffc0082cc938: 14000019     	b	0xffffffc0082cc99c <do_futex+0x2d4>
ffffffc0082cc93c: d503249f     	bti	j
ffffffc0082cc940: 12800003     	mov	w3, #-0x1       // =-1
ffffffc0082cc944: b81f43a3     	stur	w3, [x29, #-0xc]
ffffffc0082cc948: 14000021     	b	0xffffffc0082cc9cc <do_futex+0x304>
ffffffc0082cc94c: d503249f     	bti	j
ffffffc0082cc950: b85f03a1     	ldur	w1, [x29, #-0x10]
ffffffc0082cc954: aa1403e0     	mov	x0, x20
ffffffc0082cc958: 94001a35     	bl	0xffffffc0082d322c <futex_unlock_pi>
ffffffc0082cc95c: 14000028     	b	0xffffffc0082cc9fc <do_futex+0x334>
ffffffc0082cc960: d503249f     	bti	j
ffffffc0082cc964: b85f03a1     	ldur	w1, [x29, #-0x10]
ffffffc0082cc968: 52800023     	mov	w3, #0x1        // =1
ffffffc0082cc96c: aa1403e0     	mov	x0, x20
ffffffc0082cc970: aa1f03e2     	mov	x2, xzr
ffffffc0082cc974: 9400176f     	bl	0xffffffc0082d2730 <futex_lock_pi>
ffffffc0082cc978: 14000021     	b	0xffffffc0082cc9fc <do_futex+0x334>
ffffffc0082cc97c: d503249f     	bti	j
ffffffc0082cc980: b85f03a1     	ldur	w1, [x29, #-0x10]
ffffffc0082cc984: d10033a5     	sub	x5, x29, #0xc
ffffffc0082cc988: aa1403e0     	mov	x0, x20
ffffffc0082cc98c: aa1503e2     	mov	x2, x21
ffffffc0082cc990: 2a1303e3     	mov	w3, w19
ffffffc0082cc994: 2a1603e4     	mov	w4, w22
ffffffc0082cc998: 2a1f03e6     	mov	w6, wzr
ffffffc0082cc99c: 94000772     	bl	0xffffffc0082ce764 <futex_requeue>
ffffffc0082cc9a0: 14000017     	b	0xffffffc0082cc9fc <do_futex+0x334>
ffffffc0082cc9a4: d503249f     	bti	j
ffffffc0082cc9a8: 297e17a1     	ldp	w1, w5, [x29, #-0x10]
ffffffc0082cc9ac: aa1403e0     	mov	x0, x20
ffffffc0082cc9b0: aa1503e2     	mov	x2, x21
ffffffc0082cc9b4: 2a1303e3     	mov	w3, w19
ffffffc0082cc9b8: 2a1603e4     	mov	w4, w22
ffffffc0082cc9bc: 94000ff2     	bl	0xffffffc0082d0984 <futex_wake_op>
ffffffc0082cc9c0: 1400000f     	b	0xffffffc0082cc9fc <do_futex+0x334>
ffffffc0082cc9c4: d503249f     	bti	j
ffffffc0082cc9c8: b85f43a3     	ldur	w3, [x29, #-0xc]
ffffffc0082cc9cc: b85f03a1     	ldur	w1, [x29, #-0x10]
ffffffc0082cc9d0: aa1403e0     	mov	x0, x20
ffffffc0082cc9d4: 2a1303e2     	mov	w2, w19
ffffffc0082cc9d8: 94000367     	bl	0xffffffc0082cd774 <futex_wake>
ffffffc0082cc9dc: 14000008     	b	0xffffffc0082cc9fc <do_futex+0x334>
ffffffc0082cc9e0: d503249f     	bti	j
ffffffc0082cc9e4: b85f43a4     	ldur	w4, [x29, #-0xc]
ffffffc0082cc9e8: b85f03a1     	ldur	w1, [x29, #-0x10]
ffffffc0082cc9ec: aa1403e0     	mov	x0, x20
ffffffc0082cc9f0: 2a1303e2     	mov	w2, w19
ffffffc0082cc9f4: aa1703e3     	mov	x3, x23
ffffffc0082cc9f8: 9400008b     	bl	0xffffffc0082ccc24 <futex_wait>
ffffffc0082cc9fc: 93407c00     	sxtw	x0, w0
ffffffc0082cca00: d503249f     	bti	j
ffffffc0082cca04: f0011849     	adrp	x9, 0xffffffc00a5d7000 <idle_sched_class+0x20>
ffffffc0082cca08: f85f83a8     	ldur	x8, [x29, #-0x8]
ffffffc0082cca0c: f9426929     	ldr	x9, [x9, #0x4d0]
ffffffc0082cca10: eb08013f     	cmp	x9, x8
ffffffc0082cca14: 54000721     	b.ne	0xffffffc0082ccaf8 <do_futex+0x430>
ffffffc0082cca18: a9467bfd     	ldp	x29, x30, [sp, #0x60]
ffffffc0082cca1c: a94b4ff4     	ldp	x20, x19, [sp, #0xb0]
ffffffc0082cca20: a94a57f6     	ldp	x22, x21, [sp, #0xa0]
ffffffc0082cca24: a9495ff8     	ldp	x24, x23, [sp, #0x90]
ffffffc0082cca28: a94867fa     	ldp	x26, x25, [sp, #0x80]
ffffffc0082cca2c: a9476ffc     	ldp	x28, x27, [sp, #0x70]
ffffffc0082cca30: f85f8e5e     	ldr	x30, [x18, #-0x8]!
ffffffc0082cca34: 910303ff     	add	sp, sp, #0xc0
ffffffc0082cca38: d50323bf     	autiasp
ffffffc0082cca3c: d65f03c0     	ret
ffffffc0082cca40: 2a0b03ea     	mov	w10, w11
ffffffc0082cca44: f0015a8b     	adrp	x11, 0xffffffc00ae1f000 <rsc_lock_boost_trace+0xe8>
ffffffc0082cca48: b940d96c     	ldr	w12, [x11, #0xd8]
ffffffc0082cca4c: 9136e10d     	add	x13, x8, #0xdb8
ffffffc0082cca50: 911e4102     	add	x2, x8, #0x790
ffffffc0082cca54: f001066e     	adrp	x14, 0xffffffc00a39b000 <f_midi_shortname+0x456d>
ffffffc0082cca58: 1100058c     	add	w12, w12, #0x1
ffffffc0082cca5c: b900d96c     	str	w12, [x11, #0xd8]
ffffffc0082cca60: f943c10b     	ldr	x11, [x8, #0x780]
ffffffc0082cca64: f943050c     	ldr	x12, [x8, #0x608]
ffffffc0082cca68: b945c903     	ldr	w3, [x8, #0x5c8]
ffffffc0082cca6c: 3975b506     	ldrb	w6, [x8, #0xd6d]
ffffffc0082cca70: b9400561     	ldr	w1, [x11, #0x4]
ffffffc0082cca74: b945c985     	ldr	w5, [x12, #0x5c8]
ffffffc0082cca78: c8dffda7     	ldar	x7, [x13]
ffffffc0082cca7c: f940010b     	ldr	x11, [x8]
ffffffc0082cca80: 3975b908     	ldrb	w8, [x8, #0xd6e]
ffffffc0082cca84: d00102cd     	adrp	x13, 0xffffffc00a326000 <hci_reset_dev.hw_err+0x21c63>
ffffffc0082cca88: 910a65ce     	add	x14, x14, #0x299
ffffffc0082cca8c: 91068dad     	add	x13, x13, #0x1a3
ffffffc0082cca90: f26a017f     	tst	x11, #0x400000
ffffffc0082cca94: b00101c0     	adrp	x0, 0xffffffc00a305000 <hci_reset_dev.hw_err+0xc63>
ffffffc0082cca98: 911e4184     	add	x4, x12, #0x790
ffffffc0082cca9c: 9a8e01ab     	csel	x11, x13, x14, eq
ffffffc0082ccaa0: 530f3eac     	ubfx	w12, w21, #15, #1
ffffffc0082ccaa4: 91134c00     	add	x0, x0, #0x4d3
ffffffc0082ccaa8: b9004be9     	str	w9, [sp, #0x48]
ffffffc0082ccaac: b90043f6     	str	w22, [sp, #0x40]
ffffffc0082ccab0: b9003bf3     	str	w19, [sp, #0x38]
ffffffc0082ccab4: b90033f9     	str	w25, [sp, #0x30]
ffffffc0082ccab8: a90257f4     	stp	x20, x21, [sp, #0x20]
ffffffc0082ccabc: b9001bec     	str	w12, [sp, #0x18]
ffffffc0082ccac0: f9000bea     	str	x10, [sp, #0x10]
ffffffc0082ccac4: b9000be8     	str	w8, [sp, #0x8]
ffffffc0082ccac8: f90003eb     	str	x11, [sp]
ffffffc0082ccacc: 97fd974f     	bl	0xffffffc008232808 <printk>
ffffffc0082ccad0: d353ff48     	lsr	x8, x26, #19
ffffffc0082ccad4: d0015a89     	adrp	x9, 0xffffffc00ae1e000 <hash_table.13018+0x3360>
ffffffc0082ccad8: d27d0108     	eor	x8, x8, #0x8
ffffffc0082ccadc: 913be129     	add	x9, x9, #0xef8
ffffffc0082ccae0: f868692a     	ldr	x10, [x9, x8]
ffffffc0082ccae4: 2a1f03e5     	mov	w5, wzr
ffffffc0082ccae8: 9100054a     	add	x10, x10, #0x1
ffffffc0082ccaec: f828692a     	str	x10, [x9, x8]
ffffffc0082ccaf0: 363fe999     	tbz	w25, #0x7, 0xffffffc0082cc820 <do_futex+0x158>
ffffffc0082ccaf4: 17ffff4e     	b	0xffffffc0082cc82c <do_futex+0x164>
ffffffc0082ccaf8: 9455b257     	bl	0xffffffc009839454 <__stack_chk_fail>
ffffffc0082ccafc: d503249f     	bti	j
ffffffc0082ccb00: f0013ec9     	adrp	x9, 0xffffffc00aaa7000 <this_cpu_vector>
ffffffc0082ccb04: d538d088     	mrs	x8, TPIDR_EL1
ffffffc0082ccb08: 91002129     	add	x9, x9, #0x8
ffffffc0082ccb0c: b8696908     	ldr	w8, [x8, x9]
ffffffc0082ccb10: b001406a     	adrp	x10, 0xffffffc00aad9000 <nf_conntrack_locks+0x6c0>
ffffffc0082ccb14: 9138614a     	add	x10, x10, #0xe18
ffffffc0082ccb18: 1100fd09     	add	w9, w8, #0x3f
ffffffc0082ccb1c: 7100011f     	cmp	w8, #0x0
ffffffc0082ccb20: 1a88b129     	csel	w9, w9, w8, lt
ffffffc0082ccb24: 13067d29     	asr	w9, w9, #6
ffffffc0082ccb28: f869d949     	ldr	x9, [x10, w9, sxtw #3]
ffffffc0082ccb2c: 9ac82528     	lsr	x8, x9, x8
ffffffc0082ccb30: 3607e908     	tbz	w8, #0x0, 0xffffffc0082cc850 <do_futex+0x188>
ffffffc0082ccb34: d538411a     	mrs	x26, SP_EL0
ffffffc0082ccb38: 9100635b     	add	x27, x26, #0x18
ffffffc0082ccb3c: 88dfff68     	ldar	w8, [x27]
ffffffc0082ccb40: 11000508     	add	w8, w8, #0x1
ffffffc0082ccb44: b9001b48     	str	w8, [x26, #0x18]
ffffffc0082ccb48: f0015008     	adrp	x8, 0xffffffc00accf000 <__tracepoint_android_vh_check_uninterruptible_tasks+0x40>
ffffffc0082ccb4c: 91252108     	add	x8, x8, #0x948
ffffffc0082ccb50: c8dffd08     	ldar	x8, [x8]
ffffffc0082ccb54: 2a0503f9     	mov	w25, w5
ffffffc0082ccb58: b4000188     	cbz	x8, 0xffffffc0082ccb88 <do_futex+0x4c0>
ffffffc0082ccb5c: f0015008     	adrp	x8, 0xffffffc00accf000 <__tracepoint_android_vh_check_uninterruptible_tasks+0x40>
ffffffc0082ccb60: 91252108     	add	x8, x8, #0x948
ffffffc0082ccb64: c8dffd1c     	ldar	x28, [x8]
ffffffc0082ccb68: b400011c     	cbz	x28, 0xffffffc0082ccb88 <do_futex+0x4c0>
ffffffc0082ccb6c: a9400388     	ldp	x8, x0, [x28]
ffffffc0082ccb70: d10043a2     	sub	x2, x29, #0x10
ffffffc0082ccb74: 2a1803e1     	mov	w1, w24
ffffffc0082ccb78: aa1503e3     	mov	x3, x21
ffffffc0082ccb7c: d63f0100     	blr	x8
ffffffc0082ccb80: f8418f88     	ldr	x8, [x28, #0x18]!
ffffffc0082ccb84: b5ffff48     	cbnz	x8, 0xffffffc0082ccb6c <do_futex+0x4a4>
ffffffc0082ccb88: c8dfff68     	ldar	x8, [x27]
ffffffc0082ccb8c: f1000508     	subs	x8, x8, #0x1
ffffffc0082ccb90: 2a1903e5     	mov	w5, w25
ffffffc0082ccb94: b9001b48     	str	w8, [x26, #0x18]
ffffffc0082ccb98: 54000080     	b.eq	0xffffffc0082ccba8 <do_futex+0x4e0>
ffffffc0082ccb9c: 91006348     	add	x8, x26, #0x18
ffffffc0082ccba0: c8dffd08     	ldar	x8, [x8]
ffffffc0082ccba4: b5ffe568     	cbnz	x8, 0xffffffc0082cc850 <do_futex+0x188>
ffffffc0082ccba8: 91006348     	add	x8, x26, #0x18
ffffffc0082ccbac: 88dffd08     	ldar	w8, [x8]
ffffffc0082ccbb0: 35ffe508     	cbnz	w8, 0xffffffc0082cc850 <do_futex+0x188>
ffffffc0082ccbb4: d53b4228     	mrs	x8, DAIF
ffffffc0082ccbb8: 12190109     	and	w9, w8, #0x80
ffffffc0082ccbbc: 35ffe4a9     	cbnz	w9, 0xffffffc0082cc850 <do_futex+0x188>
ffffffc0082ccbc0: 9100635b     	add	x27, x26, #0x18
ffffffc0082ccbc4: 88dfff68     	ldar	w8, [x27]
ffffffc0082ccbc8: 11000508     	add	w8, w8, #0x1
ffffffc0082ccbcc: b9001b48     	str	w8, [x26, #0x18]
ffffffc0082ccbd0: 52800020     	mov	w0, #0x1        // =1
ffffffc0082ccbd4: 9464d4a1     	bl	0xffffffc009c01e58 <__schedule>
ffffffc0082ccbd8: 88dfff68     	ldar	w8, [x27]
ffffffc0082ccbdc: 51000508     	sub	w8, w8, #0x1
ffffffc0082ccbe0: b9001b48     	str	w8, [x26, #0x18]
ffffffc0082ccbe4: f9400348     	ldr	x8, [x26]
ffffffc0082ccbe8: 2a1903e5     	mov	w5, w25
ffffffc0082ccbec: 370ffea8     	tbnz	w8, #0x1, 0xffffffc0082ccbc0 <do_futex+0x4f8>
ffffffc0082ccbf0: 17ffff18     	b	0xffffffc0082cc850 <do_futex+0x188>
ffffffc0082ccbf4: f8bfc1a7     	ldapr	x7, [x13]
ffffffc0082ccbf8: d53cd048     	mrs	x8, TPIDR_EL2
ffffffc0082ccbfc: b8bfc368     	ldapr	w8, [x27]
ffffffc0082ccc00: f8bfc108     	ldapr	x8, [x8]
ffffffc0082ccc04: f8bfc11c     	ldapr	x28, [x8]
ffffffc0082ccc08: f8bfc368     	ldapr	x8, [x27]
ffffffc0082ccc0c: f8bfc108     	ldapr	x8, [x8]
ffffffc0082ccc10: b8bfc108     	ldapr	w8, [x8]
ffffffc0082ccc14: d5384608     	mrs	x8, ICC_PMR_EL1
ffffffc0082ccc18: 521b0909     	eor	w9, w8, #0xe0
ffffffc0082ccc1c: b8bfc368     	ldapr	w8, [x27]
ffffffc0082ccc20: b8bfc368     	ldapr	w8, [x27]
