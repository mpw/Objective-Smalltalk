	.section	__TEXT,__text,regular,pure_instructions
	.align	4, 0x90
"-[NSObject(empty) empty:]":            ## @"\01-[NSObject(empty) empty:]"
	.cfi_startproc
## BB#0:
	movq	%rdi, -8(%rsp)
	movq	%rsi, -16(%rsp)
	movq	%rdx, -24(%rsp)
	movq	%rdx, %rax
	ret
	.cfi_endproc

	.section	__TEXT,__objc_classname,cstring_literals
L_OBJC_CLASS_NAME_:                     ## @"\01L_OBJC_CLASS_NAME_"
	.asciz	 "empty"

	.section	__TEXT,__objc_methname,cstring_literals
L_OBJC_METH_VAR_NAME_:                  ## @"\01L_OBJC_METH_VAR_NAME_"
	.asciz	 "empty:"

	.section	__TEXT,__objc_methtype,cstring_literals
L_OBJC_METH_VAR_TYPE_:                  ## @"\01L_OBJC_METH_VAR_TYPE_"
	.asciz	 "@24@0:8@16"

	.section	__DATA,__objc_const
	.align	3                       ## @"\01l_OBJC_$_CATEGORY_INSTANCE_METHODS_NSObject_$_empty"
l_OBJC_$_CATEGORY_INSTANCE_METHODS_NSObject_$_empty:
	.long	24                      ## 0x18
	.long	1                       ## 0x1
	.quad	L_OBJC_METH_VAR_NAME_
	.quad	L_OBJC_METH_VAR_TYPE_
	.quad	"-[NSObject(empty) empty:]"

	.align	3                       ## @"\01l_OBJC_$_CATEGORY_NSObject_$_empty"
l_OBJC_$_CATEGORY_NSObject_$_empty:
	.quad	L_OBJC_CLASS_NAME_
	.quad	_OBJC_CLASS_$_NSObject
	.quad	l_OBJC_$_CATEGORY_INSTANCE_METHODS_NSObject_$_empty
	.quad	0
	.quad	0
	.quad	0

	.section	__DATA,__objc_catlist,regular,no_dead_strip
	.align	3                       ## @"\01L_OBJC_LABEL_CATEGORY_$"
L_OBJC_LABEL_CATEGORY_$:
	.quad	l_OBJC_$_CATEGORY_NSObject_$_empty

	.section	__DATA,__objc_imageinfo,regular,no_dead_strip
L_OBJC_IMAGE_INFO:
	.long	0
	.long	0


.subsections_via_symbols
