	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 11, 0	sdk_version 11, 0
	.p2align	2               ; -- Begin function -[NSObject(empty) empty:]
"-[NSObject(empty) empty:]":            ; @"\01-[NSObject(empty) empty:]"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #32             ; =32
	.cfi_def_cfa_offset 32
	str	x0, [sp, #24]
	str	x1, [sp, #16]
	str	x2, [sp, #8]
	ldr	x0, [sp, #8]
	add	sp, sp, #32             ; =32
	ret
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__objc_classname,cstring_literals
l_OBJC_CLASS_NAME_:                     ; @OBJC_CLASS_NAME_
	.asciz	"empty"

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_:                  ; @OBJC_METH_VAR_NAME_
	.asciz	"empty:"

	.section	__TEXT,__objc_methtype,cstring_literals
l_OBJC_METH_VAR_TYPE_:                  ; @OBJC_METH_VAR_TYPE_
	.asciz	"@24@0:8@16"

	.section	__DATA,__objc_const
	.p2align	3               ; @"_OBJC_$_CATEGORY_INSTANCE_METHODS_NSObject_$_empty"
__OBJC_$_CATEGORY_INSTANCE_METHODS_NSObject_$_empty:
	.long	24                      ; 0x18
	.long	1                       ; 0x1
	.quad	l_OBJC_METH_VAR_NAME_
	.quad	l_OBJC_METH_VAR_TYPE_
	.quad	"-[NSObject(empty) empty:]"

	.p2align	3               ; @"_OBJC_$_CATEGORY_NSObject_$_empty"
__OBJC_$_CATEGORY_NSObject_$_empty:
	.quad	l_OBJC_CLASS_NAME_
	.quad	_OBJC_CLASS_$_NSObject
	.quad	__OBJC_$_CATEGORY_INSTANCE_METHODS_NSObject_$_empty
	.quad	0
	.quad	0
	.quad	0
	.quad	0
	.long	64                      ; 0x40
	.space	4

	.section	__DATA,__objc_catlist,regular,no_dead_strip
	.p2align	3               ; @"OBJC_LABEL_CATEGORY_$"
l_OBJC_LABEL_CATEGORY_$:
	.quad	__OBJC_$_CATEGORY_NSObject_$_empty

	.section	__DATA,__objc_imageinfo,regular,no_dead_strip
L_OBJC_IMAGE_INFO:
	.long	0
	.long	64

.subsections_via_symbols
