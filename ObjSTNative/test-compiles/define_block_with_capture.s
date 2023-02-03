	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 13, 0	sdk_version 13, 1
	.p2align	2                               ; -- Begin function -[IfTrueIfFalseTester tester:]
"-[IfTrueIfFalseTester tester:]":       ; @"\01-[IfTrueIfFalseTester tester:]"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #96
	stp	x29, x30, [sp, #80]             ; 16-byte Folded Spill
	add	x29, sp, #80
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	mov	x0, x2
Lloh0:
	adrp	x8, __NSConcreteStackBlock@GOTPAGE
Lloh1:
	ldr	x8, [x8, __NSConcreteStackBlock@GOTPAGEOFF]
	mov	w9, #-1040187392
	stp	x8, x9, [sp, #40]
Lloh2:
	adrp	x10, "___30-[IfTrueIfFalseTester tester:]_block_invoke"@PAGE
Lloh3:
	add	x10, x10, "___30-[IfTrueIfFalseTester tester:]_block_invoke"@PAGEOFF
Lloh4:
	adrp	x11, "___block_descriptor_40_e8_32o_e5_8?0l"@PAGE
Lloh5:
	add	x11, x11, "___block_descriptor_40_e8_32o_e5_8?0l"@PAGEOFF
	stp	x10, x11, [sp, #56]
Lloh6:
	adrp	x10, l__unnamed_nsconstantintegernumber_@PAGE
Lloh7:
	add	x10, x10, l__unnamed_nsconstantintegernumber_@PAGEOFF
	str	x10, [sp, #72]
Lloh8:
	adrp	x10, "___30-[IfTrueIfFalseTester tester:]_block_invoke.3"@PAGE
Lloh9:
	add	x10, x10, "___30-[IfTrueIfFalseTester tester:]_block_invoke.3"@PAGEOFF
	stp	x8, x9, [sp]
	stp	x10, x11, [sp, #16]
Lloh10:
	adrp	x8, l__unnamed_nsconstantintegernumber_.1@PAGE
Lloh11:
	add	x8, x8, l__unnamed_nsconstantintegernumber_.1@PAGEOFF
	str	x8, [sp, #32]
	add	x2, sp, #40
	mov	x3, sp
	bl	"_objc_msgSend$ifTrue:ifFalse:"
	ldp	x29, x30, [sp, #80]             ; 16-byte Folded Reload
	add	sp, sp, #96
	ret
	.loh AdrpAdd	Lloh10, Lloh11
	.loh AdrpAdd	Lloh8, Lloh9
	.loh AdrpAdd	Lloh6, Lloh7
	.loh AdrpAdd	Lloh4, Lloh5
	.loh AdrpAdd	Lloh2, Lloh3
	.loh AdrpLdrGot	Lloh0, Lloh1
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function __30-[IfTrueIfFalseTester tester:]_block_invoke
"___30-[IfTrueIfFalseTester tester:]_block_invoke": ; @"__30-[IfTrueIfFalseTester tester:]_block_invoke"
	.cfi_startproc
; %bb.0:
	ldr	x0, [x0, #32]
	ret
	.cfi_endproc
                                        ; -- End function
	.private_extern	___copy_helper_block_e8_32o ; -- Begin function __copy_helper_block_e8_32o
	.globl	___copy_helper_block_e8_32o
	.weak_def_can_be_hidden	___copy_helper_block_e8_32o
	.p2align	2
___copy_helper_block_e8_32o:            ; @__copy_helper_block_e8_32o
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	add	x0, x0, #32
	ldr	x1, [x1, #32]
	mov	w2, #3
	bl	__Block_object_assign
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.private_extern	___destroy_helper_block_e8_32o ; -- Begin function __destroy_helper_block_e8_32o
	.globl	___destroy_helper_block_e8_32o
	.weak_def_can_be_hidden	___destroy_helper_block_e8_32o
	.p2align	2
___destroy_helper_block_e8_32o:         ; @__destroy_helper_block_e8_32o
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	ldr	x0, [x0, #32]
	mov	w1, #3
	bl	__Block_object_dispose
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function __30-[IfTrueIfFalseTester tester:]_block_invoke.3
"___30-[IfTrueIfFalseTester tester:]_block_invoke.3": ; @"__30-[IfTrueIfFalseTester tester:]_block_invoke.3"
	.cfi_startproc
; %bb.0:
	ldr	x0, [x0, #32]
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #32
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	add	x29, sp, #16
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
Lloh12:
	adrp	x8, _OBJC_CLASSLIST_REFERENCES_$_@PAGE
Lloh13:
	ldr	x0, [x8, _OBJC_CLASSLIST_REFERENCES_$_@PAGEOFF]
	bl	_objc_opt_new
Lloh14:
	adrp	x8, _OBJC_CLASSLIST_REFERENCES_$_.4@PAGE
Lloh15:
	ldr	x0, [x8, _OBJC_CLASSLIST_REFERENCES_$_.4@PAGEOFF]
	bl	_objc_opt_new
Lloh16:
	adrp	x2, l__unnamed_nsconstantintegernumber_.5@PAGE
Lloh17:
	add	x2, x2, l__unnamed_nsconstantintegernumber_.5@PAGEOFF
	bl	"_objc_msgSend$tester:"
	str	x0, [sp]
Lloh18:
	adrp	x0, l__unnamed_cfstring_@PAGE
Lloh19:
	add	x0, x0, l__unnamed_cfstring_@PAGEOFF
	bl	_NSLog
	mov	w0, #0
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #32
	ret
	.loh AdrpAdd	Lloh18, Lloh19
	.loh AdrpAdd	Lloh16, Lloh17
	.loh AdrpLdr	Lloh14, Lloh15
	.loh AdrpLdr	Lloh12, Lloh13
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"i"

	.section	__DATA,__objc_intobj,regular,no_dead_strip
	.p2align	3                               ; @_unnamed_nsconstantintegernumber_
l__unnamed_nsconstantintegernumber_:
	.quad	_OBJC_CLASS_$_NSConstantIntegerNumber
	.quad	l_.str
	.quad	2                               ; 0x2

	.p2align	3                               ; @_unnamed_nsconstantintegernumber_.1
l__unnamed_nsconstantintegernumber_.1:
	.quad	_OBJC_CLASS_$_NSConstantIntegerNumber
	.quad	l_.str
	.quad	3                               ; 0x3

	.section	__TEXT,__cstring,cstring_literals
l_.str.2:                               ; @.str.2
	.asciz	"@8@?0"

	.private_extern	"___block_descriptor_40_e8_32o_e5_8?0l" ; @"__block_descriptor_40_e8_32o_e5_\018\01?0l"
	.section	__DATA,__const
	.globl	"___block_descriptor_40_e8_32o_e5_8?0l"
	.weak_def_can_be_hidden	"___block_descriptor_40_e8_32o_e5_8?0l"
	.p2align	3
"___block_descriptor_40_e8_32o_e5_8?0l":
	.quad	0                               ; 0x0
	.quad	40                              ; 0x28
	.quad	___copy_helper_block_e8_32o
	.quad	___destroy_helper_block_e8_32o
	.quad	l_.str.2
	.quad	256                             ; 0x100

	.section	__TEXT,__objc_classname,cstring_literals
l_OBJC_CLASS_NAME_:                     ; @OBJC_CLASS_NAME_
	.asciz	"IfTrueIfFalseTester"

	.section	__DATA,__objc_const
	.p2align	3                               ; @"_OBJC_METACLASS_RO_$_IfTrueIfFalseTester"
__OBJC_METACLASS_RO_$_IfTrueIfFalseTester:
	.long	1                               ; 0x1
	.long	40                              ; 0x28
	.long	40                              ; 0x28
	.space	4
	.quad	0
	.quad	l_OBJC_CLASS_NAME_
	.quad	0
	.quad	0
	.quad	0
	.quad	0
	.quad	0

	.section	__DATA,__objc_data
	.globl	_OBJC_METACLASS_$_IfTrueIfFalseTester ; @"OBJC_METACLASS_$_IfTrueIfFalseTester"
	.p2align	3
_OBJC_METACLASS_$_IfTrueIfFalseTester:
	.quad	_OBJC_METACLASS_$_NSObject
	.quad	_OBJC_METACLASS_$_NSObject
	.quad	__objc_empty_cache
	.quad	0
	.quad	__OBJC_METACLASS_RO_$_IfTrueIfFalseTester

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_:                  ; @OBJC_METH_VAR_NAME_
	.asciz	"tester:"

	.section	__TEXT,__objc_methtype,cstring_literals
l_OBJC_METH_VAR_TYPE_:                  ; @OBJC_METH_VAR_TYPE_
	.asciz	"@24@0:8@16"

	.section	__DATA,__objc_const
	.p2align	3                               ; @"_OBJC_$_INSTANCE_METHODS_IfTrueIfFalseTester"
__OBJC_$_INSTANCE_METHODS_IfTrueIfFalseTester:
	.long	24                              ; 0x18
	.long	1                               ; 0x1
	.quad	l_OBJC_METH_VAR_NAME_
	.quad	l_OBJC_METH_VAR_TYPE_
	.quad	"-[IfTrueIfFalseTester tester:]"

	.p2align	3                               ; @"_OBJC_CLASS_RO_$_IfTrueIfFalseTester"
__OBJC_CLASS_RO_$_IfTrueIfFalseTester:
	.long	0                               ; 0x0
	.long	8                               ; 0x8
	.long	8                               ; 0x8
	.space	4
	.quad	0
	.quad	l_OBJC_CLASS_NAME_
	.quad	__OBJC_$_INSTANCE_METHODS_IfTrueIfFalseTester
	.quad	0
	.quad	0
	.quad	0
	.quad	0

	.section	__DATA,__objc_data
	.globl	_OBJC_CLASS_$_IfTrueIfFalseTester ; @"OBJC_CLASS_$_IfTrueIfFalseTester"
	.p2align	3
_OBJC_CLASS_$_IfTrueIfFalseTester:
	.quad	_OBJC_METACLASS_$_IfTrueIfFalseTester
	.quad	_OBJC_CLASS_$_NSObject
	.quad	__objc_empty_cache
	.quad	0
	.quad	__OBJC_CLASS_RO_$_IfTrueIfFalseTester

	.section	__DATA,__objc_classrefs,regular,no_dead_strip
	.p2align	3                               ; @"OBJC_CLASSLIST_REFERENCES_$_"
_OBJC_CLASSLIST_REFERENCES_$_:
	.quad	_OBJC_CLASS_$_MPWBlockContext

	.p2align	3                               ; @"OBJC_CLASSLIST_REFERENCES_$_.4"
_OBJC_CLASSLIST_REFERENCES_$_.4:
	.quad	_OBJC_CLASS_$_IfTrueIfFalseTester

	.section	__DATA,__objc_intobj,regular,no_dead_strip
	.p2align	3                               ; @_unnamed_nsconstantintegernumber_.5
l__unnamed_nsconstantintegernumber_.5:
	.quad	_OBJC_CLASS_$_NSConstantIntegerNumber
	.quad	l_.str
	.quad	1                               ; 0x1

	.section	__TEXT,__cstring,cstring_literals
l_.str.6:                               ; @.str.6
	.asciz	"reusult: %@"

	.section	__DATA,__cfstring
	.p2align	3                               ; @_unnamed_cfstring_
l__unnamed_cfstring_:
	.quad	___CFConstantStringClassReference
	.long	1992                            ; 0x7c8
	.space	4
	.quad	l_.str.6
	.quad	11                              ; 0xb

	.section	__DATA,__objc_classlist,regular,no_dead_strip
	.p2align	3                               ; @"OBJC_LABEL_CLASS_$"
l_OBJC_LABEL_CLASS_$:
	.quad	_OBJC_CLASS_$_IfTrueIfFalseTester

	.section	__DATA,__objc_imageinfo,regular,no_dead_strip
L_OBJC_IMAGE_INFO:
	.long	0
	.long	64

.subsections_via_symbols
