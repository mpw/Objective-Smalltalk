	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 11, 0	sdk_version 11, 0
	.section	__TEXT,__objc_classname,cstring_literals
l_OBJC_CLASS_NAME_:                     ; @OBJC_CLASS_NAME_
	.asciz	"EmptyCodeGenTestClass01"

	.section	__DATA,__objc_const
	.p2align	3               ; @"_OBJC_METACLASS_RO_$_EmptyCodeGenTestClass01"
__OBJC_METACLASS_RO_$_EmptyCodeGenTestClass01:
	.long	1                       ; 0x1
	.long	40                      ; 0x28
	.long	40                      ; 0x28
	.space	4
	.quad	0
	.quad	l_OBJC_CLASS_NAME_
	.quad	0
	.quad	0
	.quad	0
	.quad	0
	.quad	0

	.section	__DATA,__objc_data
	.globl	_OBJC_METACLASS_$_EmptyCodeGenTestClass01 ; @"OBJC_METACLASS_$_EmptyCodeGenTestClass01"
	.p2align	3
_OBJC_METACLASS_$_EmptyCodeGenTestClass01:
	.quad	_OBJC_METACLASS_$_NSObject
	.quad	_OBJC_METACLASS_$_NSObject
	.quad	__objc_empty_cache
	.quad	0
	.quad	__OBJC_METACLASS_RO_$_EmptyCodeGenTestClass01

	.section	__DATA,__objc_const
	.p2align	3               ; @"_OBJC_CLASS_RO_$_EmptyCodeGenTestClass01"
__OBJC_CLASS_RO_$_EmptyCodeGenTestClass01:
	.long	0                       ; 0x0
	.long	8                       ; 0x8
	.long	8                       ; 0x8
	.space	4
	.quad	0
	.quad	l_OBJC_CLASS_NAME_
	.quad	0
	.quad	0
	.quad	0
	.quad	0
	.quad	0

	.section	__DATA,__objc_data
	.globl	_OBJC_CLASS_$_EmptyCodeGenTestClass01 ; @"OBJC_CLASS_$_EmptyCodeGenTestClass01"
	.p2align	3
_OBJC_CLASS_$_EmptyCodeGenTestClass01:
	.quad	_OBJC_METACLASS_$_EmptyCodeGenTestClass01
	.quad	_OBJC_CLASS_$_NSObject
	.quad	__objc_empty_cache
	.quad	0
	.quad	__OBJC_CLASS_RO_$_EmptyCodeGenTestClass01

	.section	__DATA,__objc_classlist,regular,no_dead_strip
	.p2align	3               ; @"OBJC_LABEL_CLASS_$"
l_OBJC_LABEL_CLASS_$:
	.quad	_OBJC_CLASS_$_EmptyCodeGenTestClass01

	.section	__DATA,__objc_imageinfo,regular,no_dead_strip
L_OBJC_IMAGE_INFO:
	.long	0
	.long	64

.subsections_via_symbols
