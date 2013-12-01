	.section	__TEXT,__text,regular,pure_instructions
	.globl	_fn
	.align	4, 0x90
_fn:                                    ## @fn
	.cfi_startproc
## BB#0:
	movq	%rdi, -8(%rsp)
	movq	%rdi, %rax
	ret
	.cfi_endproc

	.section	__DATA,__objc_imageinfo,regular,no_dead_strip
L_OBJC_IMAGE_INFO:
	.long	0
	.long	0


.subsections_via_symbols
