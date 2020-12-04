	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 11, 0	sdk_version 11, 0
	.p2align	2               ; -- Begin function -[Hi components:splitInto:]
"-[Hi components:splitInto:]":          ; @"\01-[Hi components:splitInto:]"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #48             ; =48
	stp	x29, x30, [sp, #32]     ; 16-byte Folded Spill
	add	x29, sp, #32            ; =32
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	stur	x0, [x29, #-8]
	str	x1, [sp, #16]
	str	x2, [sp, #8]
	str	x3, [sp]
	ldr	x0, [sp, #8]
	ldr	x2, [sp]
	adrp	x8, _OBJC_SELECTOR_REFERENCES_@PAGE
	add	x8, x8, _OBJC_SELECTOR_REFERENCES_@PAGEOFF
	ldr	x1, [x8]
	bl	_objc_msgSend
	ldp	x29, x30, [sp, #32]     ; 16-byte Folded Reload
	add	sp, sp, #48             ; =48
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2               ; -- Begin function -[Hi lines:]
"-[Hi lines:]":                         ; @"\01-[Hi lines:]"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #48             ; =48
	stp	x29, x30, [sp, #32]     ; 16-byte Folded Spill
	add	x29, sp, #32            ; =32
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	stur	x0, [x29, #-8]
	str	x1, [sp, #16]
	str	x2, [sp, #8]
	ldur	x0, [x29, #-8]
	ldr	x2, [sp, #8]
	adrp	x8, _OBJC_SELECTOR_REFERENCES_.2@PAGE
	add	x8, x8, _OBJC_SELECTOR_REFERENCES_.2@PAGEOFF
	ldr	x1, [x8]
	adrp	x3, l__unnamed_cfstring_@PAGE
	add	x3, x3, l__unnamed_cfstring_@PAGEOFF
	bl	_objc_msgSend
	ldp	x29, x30, [sp, #32]     ; 16-byte Folded Reload
	add	sp, sp, #48             ; =48
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2               ; -- Begin function -[Hi double:]
"-[Hi double:]":                        ; @"\01-[Hi double:]"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #32             ; =32
	.cfi_def_cfa_offset 32
	str	x0, [sp, #24]
	str	x1, [sp, #16]
	str	w2, [sp, #12]
	ldr	w8, [sp, #12]
	lsl	w0, w8, #1
	add	sp, sp, #32             ; =32
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2               ; -- Begin function -[Hi mulByAddition:factor:]
"-[Hi mulByAddition:factor:]":          ; @"\01-[Hi mulByAddition:factor:]"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #32             ; =32
	.cfi_def_cfa_offset 32
	str	x0, [sp, #24]
	str	x1, [sp, #16]
	str	w2, [sp, #12]
	str	w3, [sp, #8]
	str	wzr, [sp, #4]
LBB3_1:                                 ; =>This Inner Loop Header: Depth=1
	ldr	w8, [sp, #4]
	ldr	w9, [sp, #8]
	cmp	w8, w9
	b.ge	LBB3_4
; %bb.2:                                ;   in Loop: Header=BB3_1 Depth=1
	ldr	w8, [sp, #8]
	ldr	w9, [sp, #12]
	add	w8, w9, w8
	str	w8, [sp, #12]
; %bb.3:                                ;   in Loop: Header=BB3_1 Depth=1
	ldr	w8, [sp, #4]
	add	w8, w8, #1              ; =1
	str	w8, [sp, #4]
	b	LBB3_1
LBB3_4:
	ldr	w0, [sp, #12]
	add	sp, sp, #32             ; =32
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2               ; -- Begin function -[Hi mulByAddition:]
"-[Hi mulByAddition:]":                 ; @"\01-[Hi mulByAddition:]"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #48             ; =48
	stp	x29, x30, [sp, #32]     ; 16-byte Folded Spill
	add	x29, sp, #32            ; =32
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	stur	x0, [x29, #-8]
	str	x1, [sp, #16]
	str	w2, [sp, #12]
	ldur	x0, [x29, #-8]
	ldr	w2, [sp, #12]
	ldur	x8, [x29, #-8]
	ldr	w3, [x8, #8]
	adrp	x8, _OBJC_SELECTOR_REFERENCES_.4@PAGE
	add	x8, x8, _OBJC_SELECTOR_REFERENCES_.4@PAGEOFF
	ldr	x1, [x8]
	bl	_objc_msgSend
	ldp	x29, x30, [sp, #32]     ; 16-byte Folded Reload
	add	sp, sp, #48             ; =48
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2               ; -- Begin function -[Hi mulNSNumberBy3:]
"-[Hi mulNSNumberBy3:]":                ; @"\01-[Hi mulNSNumberBy3:]"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #64             ; =64
	stp	x29, x30, [sp, #48]     ; 16-byte Folded Spill
	add	x29, sp, #48            ; =48
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	stur	x0, [x29, #-8]
	stur	x1, [x29, #-16]
	str	x2, [sp, #24]
	ldr	x0, [sp, #24]
	adrp	x8, _OBJC_CLASSLIST_REFERENCES_$_@PAGE
	add	x8, x8, _OBJC_CLASSLIST_REFERENCES_$_@PAGEOFF
	ldr	x8, [x8]
	adrp	x9, _OBJC_SELECTOR_REFERENCES_.6@PAGE
	add	x9, x9, _OBJC_SELECTOR_REFERENCES_.6@PAGEOFF
	ldr	x1, [x9]
	str	x0, [sp, #16]           ; 8-byte Folded Spill
	mov	x0, x8
	mov	w2, #3
	bl	_objc_msgSend
	adrp	x8, _OBJC_SELECTOR_REFERENCES_.8@PAGE
	add	x8, x8, _OBJC_SELECTOR_REFERENCES_.8@PAGEOFF
	ldr	x1, [x8]
	ldr	x8, [sp, #16]           ; 8-byte Folded Reload
	str	x0, [sp, #8]            ; 8-byte Folded Spill
	mov	x0, x8
	ldr	x2, [sp, #8]            ; 8-byte Folded Reload
	bl	_objc_msgSend
	ldp	x29, x30, [sp, #48]     ; 16-byte Folded Reload
	add	sp, sp, #64             ; =64
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2               ; -- Begin function -[Hi makeNumber:]
"-[Hi makeNumber:]":                    ; @"\01-[Hi makeNumber:]"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #48             ; =48
	stp	x29, x30, [sp, #32]     ; 16-byte Folded Spill
	add	x29, sp, #32            ; =32
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	stur	x0, [x29, #-8]
	str	x1, [sp, #16]
	str	w2, [sp, #12]
	adrp	x8, _OBJC_CLASSLIST_REFERENCES_$_@PAGE
	add	x8, x8, _OBJC_CLASSLIST_REFERENCES_$_@PAGEOFF
	ldr	x0, [x8]
	ldr	w2, [sp, #12]
	adrp	x8, _OBJC_SELECTOR_REFERENCES_.6@PAGE
	add	x8, x8, _OBJC_SELECTOR_REFERENCES_.6@PAGEOFF
	ldr	x1, [x8]
	bl	_objc_msgSend
	ldp	x29, x30, [sp, #32]     ; 16-byte Folded Reload
	add	sp, sp, #48             ; =48
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2               ; -- Begin function -[Hi makeNumber3]
"-[Hi makeNumber3]":                    ; @"\01-[Hi makeNumber3]"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #32             ; =32
	stp	x29, x30, [sp, #16]     ; 16-byte Folded Spill
	add	x29, sp, #16            ; =16
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	str	x0, [sp, #8]
	str	x1, [sp]
	adrp	x8, _OBJC_CLASSLIST_REFERENCES_$_@PAGE
	add	x8, x8, _OBJC_CLASSLIST_REFERENCES_$_@PAGEOFF
	ldr	x0, [x8]
	adrp	x8, _OBJC_SELECTOR_REFERENCES_.6@PAGE
	add	x8, x8, _OBJC_SELECTOR_REFERENCES_.6@PAGEOFF
	ldr	x1, [x8]
	mov	w2, #3
	bl	_objc_msgSend
	ldp	x29, x30, [sp, #16]     ; 16-byte Folded Reload
	add	sp, sp, #32             ; =32
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2               ; -- Begin function -[Hi factor]
"-[Hi factor]":                         ; @"\01-[Hi factor]"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #16             ; =16
	.cfi_def_cfa_offset 16
	str	x0, [sp, #8]
	str	x1, [sp]
	ldr	x8, [sp, #8]
	ldr	w0, [x8, #8]
	add	sp, sp, #16             ; =16
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2               ; -- Begin function -[Hi setFactor:]
"-[Hi setFactor:]":                     ; @"\01-[Hi setFactor:]"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #32             ; =32
	.cfi_def_cfa_offset 32
	str	x0, [sp, #24]
	str	x1, [sp, #16]
	str	w2, [sp, #12]
	ldr	x8, [sp, #24]
	ldr	w9, [sp, #12]
	str	w9, [x8, #8]
	add	sp, sp, #32             ; =32
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2               ; -- Begin function -[Hi someProperty]
"-[Hi someProperty]":                   ; @"\01-[Hi someProperty]"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #16             ; =16
	.cfi_def_cfa_offset 16
	str	x0, [sp, #8]
	str	x1, [sp]
	ldr	x8, [sp, #8]
	ldr	x0, [x8, #16]
	add	sp, sp, #16             ; =16
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2               ; -- Begin function -[Hi setSomeProperty:]
"-[Hi setSomeProperty:]":               ; @"\01-[Hi setSomeProperty:]"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #48             ; =48
	stp	x29, x30, [sp, #32]     ; 16-byte Folded Spill
	add	x29, sp, #32            ; =32
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	stur	x0, [x29, #-8]
	str	x1, [sp, #16]
	str	x2, [sp, #8]
	ldr	x1, [sp, #16]
	ldur	x0, [x29, #-8]
	ldr	x2, [sp, #8]
	mov	x3, #16
	bl	_objc_setProperty_nonatomic
	ldp	x29, x30, [sp, #32]     ; 16-byte Folded Reload
	add	sp, sp, #48             ; =48
	ret
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_:                  ; @OBJC_METH_VAR_NAME_
	.asciz	"componentsSeparatedByString:"

	.section	__DATA,__objc_selrefs,literal_pointers,no_dead_strip
	.p2align	3               ; @OBJC_SELECTOR_REFERENCES_
_OBJC_SELECTOR_REFERENCES_:
	.quad	l_OBJC_METH_VAR_NAME_

	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"\n"

	.section	__DATA,__cfstring
	.p2align	3               ; @_unnamed_cfstring_
l__unnamed_cfstring_:
	.quad	___CFConstantStringClassReference
	.long	1992                    ; 0x7c8
	.space	4
	.quad	l_.str
	.quad	1                       ; 0x1

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_.1:                ; @OBJC_METH_VAR_NAME_.1
	.asciz	"components:splitInto:"

	.section	__DATA,__objc_selrefs,literal_pointers,no_dead_strip
	.p2align	3               ; @OBJC_SELECTOR_REFERENCES_.2
_OBJC_SELECTOR_REFERENCES_.2:
	.quad	l_OBJC_METH_VAR_NAME_.1

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_.3:                ; @OBJC_METH_VAR_NAME_.3
	.asciz	"mulByAddition:factor:"

	.section	__DATA,__objc_selrefs,literal_pointers,no_dead_strip
	.p2align	3               ; @OBJC_SELECTOR_REFERENCES_.4
_OBJC_SELECTOR_REFERENCES_.4:
	.quad	l_OBJC_METH_VAR_NAME_.3

	.section	__DATA,__objc_classrefs,regular,no_dead_strip
	.p2align	3               ; @"OBJC_CLASSLIST_REFERENCES_$_"
_OBJC_CLASSLIST_REFERENCES_$_:
	.quad	_OBJC_CLASS_$_NSNumber

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_.5:                ; @OBJC_METH_VAR_NAME_.5
	.asciz	"numberWithInt:"

	.section	__DATA,__objc_selrefs,literal_pointers,no_dead_strip
	.p2align	3               ; @OBJC_SELECTOR_REFERENCES_.6
_OBJC_SELECTOR_REFERENCES_.6:
	.quad	l_OBJC_METH_VAR_NAME_.5

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_.7:                ; @OBJC_METH_VAR_NAME_.7
	.asciz	"mul:"

	.section	__DATA,__objc_selrefs,literal_pointers,no_dead_strip
	.p2align	3               ; @OBJC_SELECTOR_REFERENCES_.8
_OBJC_SELECTOR_REFERENCES_.8:
	.quad	l_OBJC_METH_VAR_NAME_.7

	.section	__TEXT,__objc_classname,cstring_literals
l_OBJC_CLASS_NAME_:                     ; @OBJC_CLASS_NAME_
	.asciz	"Hi"

	.section	__DATA,__objc_const
	.p2align	3               ; @"_OBJC_METACLASS_RO_$_Hi"
__OBJC_METACLASS_RO_$_Hi:
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
	.globl	_OBJC_METACLASS_$_Hi    ; @"OBJC_METACLASS_$_Hi"
	.p2align	3
_OBJC_METACLASS_$_Hi:
	.quad	_OBJC_METACLASS_$_NSObject
	.quad	_OBJC_METACLASS_$_NSObject
	.quad	__objc_empty_cache
	.quad	0
	.quad	__OBJC_METACLASS_RO_$_Hi

	.section	__TEXT,__objc_methtype,cstring_literals
l_OBJC_METH_VAR_TYPE_:                  ; @OBJC_METH_VAR_TYPE_
	.asciz	"@32@0:8@16@24"

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_.9:                ; @OBJC_METH_VAR_NAME_.9
	.asciz	"lines:"

	.section	__TEXT,__objc_methtype,cstring_literals
l_OBJC_METH_VAR_TYPE_.10:               ; @OBJC_METH_VAR_TYPE_.10
	.asciz	"@24@0:8@16"

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_.11:               ; @OBJC_METH_VAR_NAME_.11
	.asciz	"double:"

	.section	__TEXT,__objc_methtype,cstring_literals
l_OBJC_METH_VAR_TYPE_.12:               ; @OBJC_METH_VAR_TYPE_.12
	.asciz	"i20@0:8i16"

l_OBJC_METH_VAR_TYPE_.13:               ; @OBJC_METH_VAR_TYPE_.13
	.asciz	"i24@0:8i16i20"

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_.14:               ; @OBJC_METH_VAR_NAME_.14
	.asciz	"mulByAddition:"

l_OBJC_METH_VAR_NAME_.15:               ; @OBJC_METH_VAR_NAME_.15
	.asciz	"mulNSNumberBy3:"

l_OBJC_METH_VAR_NAME_.16:               ; @OBJC_METH_VAR_NAME_.16
	.asciz	"makeNumber:"

	.section	__TEXT,__objc_methtype,cstring_literals
l_OBJC_METH_VAR_TYPE_.17:               ; @OBJC_METH_VAR_TYPE_.17
	.asciz	"@20@0:8i16"

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_.18:               ; @OBJC_METH_VAR_NAME_.18
	.asciz	"makeNumber3"

	.section	__TEXT,__objc_methtype,cstring_literals
l_OBJC_METH_VAR_TYPE_.19:               ; @OBJC_METH_VAR_TYPE_.19
	.asciz	"@16@0:8"

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_.20:               ; @OBJC_METH_VAR_NAME_.20
	.asciz	"factor"

	.section	__TEXT,__objc_methtype,cstring_literals
l_OBJC_METH_VAR_TYPE_.21:               ; @OBJC_METH_VAR_TYPE_.21
	.asciz	"i16@0:8"

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_.22:               ; @OBJC_METH_VAR_NAME_.22
	.asciz	"setFactor:"

	.section	__TEXT,__objc_methtype,cstring_literals
l_OBJC_METH_VAR_TYPE_.23:               ; @OBJC_METH_VAR_TYPE_.23
	.asciz	"v20@0:8i16"

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_.24:               ; @OBJC_METH_VAR_NAME_.24
	.asciz	"someProperty"

l_OBJC_METH_VAR_NAME_.25:               ; @OBJC_METH_VAR_NAME_.25
	.asciz	"setSomeProperty:"

	.section	__TEXT,__objc_methtype,cstring_literals
l_OBJC_METH_VAR_TYPE_.26:               ; @OBJC_METH_VAR_TYPE_.26
	.asciz	"v24@0:8@16"

	.section	__DATA,__objc_const
	.p2align	3               ; @"_OBJC_$_INSTANCE_METHODS_Hi"
__OBJC_$_INSTANCE_METHODS_Hi:
	.long	24                      ; 0x18
	.long	12                      ; 0xc
	.quad	l_OBJC_METH_VAR_NAME_.1
	.quad	l_OBJC_METH_VAR_TYPE_
	.quad	"-[Hi components:splitInto:]"
	.quad	l_OBJC_METH_VAR_NAME_.9
	.quad	l_OBJC_METH_VAR_TYPE_.10
	.quad	"-[Hi lines:]"
	.quad	l_OBJC_METH_VAR_NAME_.11
	.quad	l_OBJC_METH_VAR_TYPE_.12
	.quad	"-[Hi double:]"
	.quad	l_OBJC_METH_VAR_NAME_.3
	.quad	l_OBJC_METH_VAR_TYPE_.13
	.quad	"-[Hi mulByAddition:factor:]"
	.quad	l_OBJC_METH_VAR_NAME_.14
	.quad	l_OBJC_METH_VAR_TYPE_.12
	.quad	"-[Hi mulByAddition:]"
	.quad	l_OBJC_METH_VAR_NAME_.15
	.quad	l_OBJC_METH_VAR_TYPE_.10
	.quad	"-[Hi mulNSNumberBy3:]"
	.quad	l_OBJC_METH_VAR_NAME_.16
	.quad	l_OBJC_METH_VAR_TYPE_.17
	.quad	"-[Hi makeNumber:]"
	.quad	l_OBJC_METH_VAR_NAME_.18
	.quad	l_OBJC_METH_VAR_TYPE_.19
	.quad	"-[Hi makeNumber3]"
	.quad	l_OBJC_METH_VAR_NAME_.20
	.quad	l_OBJC_METH_VAR_TYPE_.21
	.quad	"-[Hi factor]"
	.quad	l_OBJC_METH_VAR_NAME_.22
	.quad	l_OBJC_METH_VAR_TYPE_.23
	.quad	"-[Hi setFactor:]"
	.quad	l_OBJC_METH_VAR_NAME_.24
	.quad	l_OBJC_METH_VAR_TYPE_.19
	.quad	"-[Hi someProperty]"
	.quad	l_OBJC_METH_VAR_NAME_.25
	.quad	l_OBJC_METH_VAR_TYPE_.26
	.quad	"-[Hi setSomeProperty:]"

	.section	__DATA,__objc_ivar
	.globl	_OBJC_IVAR_$_Hi.factor  ; @"OBJC_IVAR_$_Hi.factor"
	.p2align	2
_OBJC_IVAR_$_Hi.factor:
	.long	8                       ; 0x8

	.section	__TEXT,__objc_methtype,cstring_literals
l_OBJC_METH_VAR_TYPE_.27:               ; @OBJC_METH_VAR_TYPE_.27
	.asciz	"i"

	.private_extern	_OBJC_IVAR_$_Hi._someProperty ; @"OBJC_IVAR_$_Hi._someProperty"
	.section	__DATA,__objc_ivar
	.globl	_OBJC_IVAR_$_Hi._someProperty
	.p2align	2
_OBJC_IVAR_$_Hi._someProperty:
	.long	16                      ; 0x10

	.section	__TEXT,__objc_methname,cstring_literals
l_OBJC_METH_VAR_NAME_.28:               ; @OBJC_METH_VAR_NAME_.28
	.asciz	"_someProperty"

	.section	__TEXT,__objc_methtype,cstring_literals
l_OBJC_METH_VAR_TYPE_.29:               ; @OBJC_METH_VAR_TYPE_.29
	.asciz	"@"

	.section	__DATA,__objc_const
	.p2align	3               ; @"_OBJC_$_INSTANCE_VARIABLES_Hi"
__OBJC_$_INSTANCE_VARIABLES_Hi:
	.long	32                      ; 0x20
	.long	2                       ; 0x2
	.quad	_OBJC_IVAR_$_Hi.factor
	.quad	l_OBJC_METH_VAR_NAME_.20
	.quad	l_OBJC_METH_VAR_TYPE_.27
	.long	2                       ; 0x2
	.long	4                       ; 0x4
	.quad	_OBJC_IVAR_$_Hi._someProperty
	.quad	l_OBJC_METH_VAR_NAME_.28
	.quad	l_OBJC_METH_VAR_TYPE_.29
	.long	3                       ; 0x3
	.long	8                       ; 0x8

	.section	__TEXT,__cstring,cstring_literals
l_OBJC_PROP_NAME_ATTR_:                 ; @OBJC_PROP_NAME_ATTR_
	.asciz	"factor"

l_OBJC_PROP_NAME_ATTR_.30:              ; @OBJC_PROP_NAME_ATTR_.30
	.asciz	"Ti,Vfactor"

l_OBJC_PROP_NAME_ATTR_.31:              ; @OBJC_PROP_NAME_ATTR_.31
	.asciz	"someProperty"

l_OBJC_PROP_NAME_ATTR_.32:              ; @OBJC_PROP_NAME_ATTR_.32
	.asciz	"T@,&,N,V_someProperty"

	.section	__DATA,__objc_const
	.p2align	3               ; @"_OBJC_$_PROP_LIST_Hi"
__OBJC_$_PROP_LIST_Hi:
	.long	16                      ; 0x10
	.long	2                       ; 0x2
	.quad	l_OBJC_PROP_NAME_ATTR_
	.quad	l_OBJC_PROP_NAME_ATTR_.30
	.quad	l_OBJC_PROP_NAME_ATTR_.31
	.quad	l_OBJC_PROP_NAME_ATTR_.32

	.p2align	3               ; @"_OBJC_CLASS_RO_$_Hi"
__OBJC_CLASS_RO_$_Hi:
	.long	0                       ; 0x0
	.long	8                       ; 0x8
	.long	24                      ; 0x18
	.space	4
	.quad	0
	.quad	l_OBJC_CLASS_NAME_
	.quad	__OBJC_$_INSTANCE_METHODS_Hi
	.quad	0
	.quad	__OBJC_$_INSTANCE_VARIABLES_Hi
	.quad	0
	.quad	__OBJC_$_PROP_LIST_Hi

	.section	__DATA,__objc_data
	.globl	_OBJC_CLASS_$_Hi        ; @"OBJC_CLASS_$_Hi"
	.p2align	3
_OBJC_CLASS_$_Hi:
	.quad	_OBJC_METACLASS_$_Hi
	.quad	_OBJC_CLASS_$_NSObject
	.quad	__objc_empty_cache
	.quad	0
	.quad	__OBJC_CLASS_RO_$_Hi

	.section	__DATA,__objc_classlist,regular,no_dead_strip
	.p2align	3               ; @"OBJC_LABEL_CLASS_$"
l_OBJC_LABEL_CLASS_$:
	.quad	_OBJC_CLASS_$_Hi

	.section	__DATA,__objc_imageinfo,regular,no_dead_strip
L_OBJC_IMAGE_INFO:
	.long	0
	.long	64

.subsections_via_symbols
