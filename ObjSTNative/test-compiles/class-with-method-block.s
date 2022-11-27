	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 12, 3	sdk_version 12, 3
	.p2align	2                               ; -- Begin function -[Hi onLine:execute:]
"-[Hi onLine:execute:]":                ; @"\01-[Hi onLine:execute:]"
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	mov	x0, x3
	mov	x1, x2
	ldr	x8, [x3, #16]
	blr	x8
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function -[Hi noCaptureBlockUse:]
"-[Hi noCaptureBlockUse:]":             ; @"\01-[Hi noCaptureBlockUse:]"
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
Lloh0:
	adrp	x3, ___block_literal_global@PAGE
Lloh1:
	add	x3, x3, ___block_literal_global@PAGEOFF
	bl	"_objc_msgSend$onLine:execute:"
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.loh AdrpAdd	Lloh0, Lloh1
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function __24-[Hi noCaptureBlockUse:]_block_invoke
"___24-[Hi noCaptureBlockUse:]_block_invoke": ; @"__24-[Hi noCaptureBlockUse:]_block_invoke"
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	mov	x0, x1
	bl	_objc_msgSend$uppercaseString
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function -[Hi lines:]
"-[Hi lines:]":                         ; @"\01-[Hi lines:]"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #80
	stp	x20, x19, [sp, #48]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #64]             ; 16-byte Folded Spill
	add	x29, sp, #64
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	mov	x19, x2
Lloh2:
	adrp	x8, _OBJC_CLASSLIST_REFERENCES_$_@PAGE
Lloh3:
	ldr	x0, [x8, _OBJC_CLASSLIST_REFERENCES_$_@PAGEOFF]
	bl	_objc_msgSend$array
	mov	x20, x0
Lloh4:
	adrp	x8, __NSConcreteStackBlock@GOTPAGE
Lloh5:
	ldr	x8, [x8, __NSConcreteStackBlock@GOTPAGEOFF]
	mov	w9, #-1040187392
Lloh6:
	adrp	x10, "___12-[Hi lines:]_block_invoke"@PAGE
Lloh7:
	add	x10, x10, "___12-[Hi lines:]_block_invoke"@PAGEOFF
	stp	x8, x9, [sp, #8]
Lloh8:
	adrp	x8, "___block_descriptor_40_e8_32o_e22_v24?0\"NSString\"8^B16l"@PAGE
Lloh9:
	add	x8, x8, "___block_descriptor_40_e8_32o_e22_v24?0\"NSString\"8^B16l"@PAGEOFF
	stp	x10, x8, [sp, #24]
	str	x0, [sp, #40]
	add	x2, sp, #8
	mov	x0, x19
	bl	"_objc_msgSend$enumerateLinesUsingBlock:"
	mov	x0, x20
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #48]             ; 16-byte Folded Reload
	add	sp, sp, #80
	ret
	.loh AdrpAdd	Lloh8, Lloh9
	.loh AdrpAdd	Lloh6, Lloh7
	.loh AdrpLdrGot	Lloh4, Lloh5
	.loh AdrpLdr	Lloh2, Lloh3
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function __12-[Hi lines:]_block_invoke
"___12-[Hi lines:]_block_invoke":       ; @"__12-[Hi lines:]_block_invoke"
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	ldr	x0, [x0, #32]
	mov	x2, x1
	bl	"_objc_msgSend$addObject:"
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
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
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"@\"NSString\"16@?0@\"NSString\"8"

	.private_extern	"___block_descriptor_32_e28_\"NSString\"16?0\"NSString\"8l" ; @"__block_descriptor_32_e28_\01\22NSString\2216\01?0\01\22NSString\228l"
	.section	__DATA,__const
	.globl	"___block_descriptor_32_e28_\"NSString\"16?0\"NSString\"8l"
	.weak_def_can_be_hidden	"___block_descriptor_32_e28_\"NSString\"16?0\"NSString\"8l"
	.p2align	3
"___block_descriptor_32_e28_\"NSString\"16?0\"NSString\"8l":
	.quad	0                               ; 0x0
	.quad	32                              ; 0x20
	.quad	l_.str
	.quad	0

	.p2align	3                               ; @__block_literal_global
___block_literal_global:
	.quad	__NSConcreteGlobalBlock
	.long	1342177280                      ; 0x50000000
	.long	0                               ; 0x0
	.quad	"___24-[Hi noCaptureBlockUse:]_block_invoke"
	.quad	"___block_descriptor_32_e28_\"NSString\"16?0\"NSString\"8l"

	.section	__DATA,__objc_classrefs,regular,no_dead_strip
	.p2align	3                               ; @"OBJC_CLASSLIST_REFERENCES_$_"
_OBJC_CLASSLIST_REFERENCES_$_:
	.quad	_OBJC_CLASS_$_NSMutableArray

	.section	__TEXT,__cstring,cstring_literals
l_.str.1:                               ; @.str.1
	.asciz	"v24@?0@\"NSString\"8^B16"

	.private_extern	"___block_descriptor_40_e8_32o_e22_v24?0\"NSString\"8^B16l" ; @"__block_descriptor_40_e8_32o_e22_v24\01?0\01\22NSString\228^B16l"
	.section	__DATA,__const
	.globl	"___block_descriptor_40_e8_32o_e22_v24?0\"NSString\"8^B16l"
	.weak_def_can_be_hidden	"___block_descriptor_40_e8_32o_e22_v24?0\"NSString\"8^B16l"
	.p2align	3
"___block_descriptor_40_e8_32o_e22_v24?0\"NSString\"8^B16l":
	.quad	0                               ; 0x0
	.quad	40                              ; 0x28
	.quad	___copy_helper_block_e8_32o
	.quad	___destroy_helper_block_e8_32o
	.quad	l_.str.1
	.quad	256                             ; 0x100

	.section	__TEXT,__objc_classname,cstring_literals
l_OBJC_CLASS_NAME_:                     ; @OBJC_CLASS_NAME_
	.asciz	"Hi"

	.section	__DATA,__objc_const
	.p2align	3                               ; @"_OBJC_METACLASS_RO_$_Hi"
__OBJC_METACLASS_RO_$_Hi:
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
	.globl	_OBJC_METACLASS_$_Hi            ; @"OBJC_METACLASS_$_Hi"
	.p2align	3
_OBJC_METACLASS_$_Hi:
	.quad	_OBJC_METACLASS_$_NSObject
	.quad	_OBJC_METACLASS_$_NSObject
	.quad	__objc_empty_cache
	.quad	0
	.quad	__OBJC_METACLASS_RO_$_Hi

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_:                  ; @OBJC_METH_VAR_NAME_
	.asciz	"onLine:execute:"

	.section	__TEXT,__objc_methtype,cstring_literals
l_OBJC_METH_VAR_TYPE_:                  ; @OBJC_METH_VAR_TYPE_
	.asciz	"@32@0:8@16@?24"

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_.2:                ; @OBJC_METH_VAR_NAME_.2
	.asciz	"noCaptureBlockUse:"

	.section	__TEXT,__objc_methtype,cstring_literals
l_OBJC_METH_VAR_TYPE_.3:                ; @OBJC_METH_VAR_TYPE_.3
	.asciz	"@24@0:8@16"

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_.4:                ; @OBJC_METH_VAR_NAME_.4
	.asciz	"lines:"

	.section	__DATA,__objc_const
	.p2align	3                               ; @"_OBJC_$_INSTANCE_METHODS_Hi"
__OBJC_$_INSTANCE_METHODS_Hi:
	.long	24                              ; 0x18
	.long	3                               ; 0x3
	.quad	l_OBJC_METH_VAR_NAME_
	.quad	l_OBJC_METH_VAR_TYPE_
	.quad	"-[Hi onLine:execute:]"
	.quad	l_OBJC_METH_VAR_NAME_.2
	.quad	l_OBJC_METH_VAR_TYPE_.3
	.quad	"-[Hi noCaptureBlockUse:]"
	.quad	l_OBJC_METH_VAR_NAME_.4
	.quad	l_OBJC_METH_VAR_TYPE_.3
	.quad	"-[Hi lines:]"

	.p2align	3                               ; @"_OBJC_CLASS_RO_$_Hi"
__OBJC_CLASS_RO_$_Hi:
	.long	0                               ; 0x0
	.long	8                               ; 0x8
	.long	8                               ; 0x8
	.space	4
	.quad	0
	.quad	l_OBJC_CLASS_NAME_
	.quad	__OBJC_$_INSTANCE_METHODS_Hi
	.quad	0
	.quad	0
	.quad	0
	.quad	0

	.section	__DATA,__objc_data
	.globl	_OBJC_CLASS_$_Hi                ; @"OBJC_CLASS_$_Hi"
	.p2align	3
_OBJC_CLASS_$_Hi:
	.quad	_OBJC_METACLASS_$_Hi
	.quad	_OBJC_CLASS_$_NSObject
	.quad	__objc_empty_cache
	.quad	0
	.quad	__OBJC_CLASS_RO_$_Hi

	.section	__DATA,__objc_classlist,regular,no_dead_strip
	.p2align	3                               ; @"OBJC_LABEL_CLASS_$"
l_OBJC_LABEL_CLASS_$:
	.quad	_OBJC_CLASS_$_Hi

	.section	__DATA,__objc_imageinfo,regular,no_dead_strip
L_OBJC_IMAGE_INFO:
	.long	0
	.long	64

.subsections_via_symbols
