	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 11, 0	sdk_version 11, 0
	.globl	_fn                     ; -- Begin function fn
	.p2align	2
_fn:                                    ; @fn
	.cfi_startproc
; %bb.0:
	mov	w0, #4
	ret
	.cfi_endproc
                                        ; -- End function
	.section	__DATA,__objc_imageinfo,regular,no_dead_strip
L_OBJC_IMAGE_INFO:
	.long	0
	.long	64

.subsections_via_symbols
