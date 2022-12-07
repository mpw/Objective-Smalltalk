	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 12, 3	sdk_version 12, 3
	.globl	_bfn                            ; -- Begin function bfn
	.p2align	2
_bfn:                                   ; @bfn
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #32
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	add	x29, sp, #16
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	stur	w0, [x29, #-4]
	adrp	x0, ___block_literal_global@PAGE
	add	x0, x0, ___block_literal_global@PAGEOFF
	bl	_fn
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #32
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function __bfn_block_invoke
___bfn_block_invoke:                    ; @__bfn_block_invoke
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #32
	.cfi_def_cfa_offset 32
	mov	x8, x0
	str	x8, [sp, #24]
	str	w1, [sp, #20]
	str	x0, [sp, #8]
	ldr	w8, [sp, #20]
	add	w0, w8, #3
	add	sp, sp, #32
	ret
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"i12@?0i8"

	.private_extern	"___block_descriptor_32_e8_i12?0i8l" ; @"__block_descriptor_32_e8_i12\01?0i8l"
	.section	__DATA,__const
	.globl	"___block_descriptor_32_e8_i12?0i8l"
	.weak_def_can_be_hidden	"___block_descriptor_32_e8_i12?0i8l"
	.p2align	3
"___block_descriptor_32_e8_i12?0i8l":
	.quad	0                               ; 0x0
	.quad	32                              ; 0x20
	.quad	l_.str
	.quad	0

	.p2align	3                               ; @__block_literal_global
___block_literal_global:
	.quad	__NSConcreteGlobalBlock
	.long	1342177280                      ; 0x50000000
	.long	0                               ; 0x0
	.quad	___bfn_block_invoke
	.quad	"___block_descriptor_32_e8_i12?0i8l"

	.section	__DATA,__objc_imageinfo,regular,no_dead_strip
L_OBJC_IMAGE_INFO:
	.long	0
	.long	64

.subsections_via_symbols
