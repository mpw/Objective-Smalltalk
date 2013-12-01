	.section	__TEXT,__text,regular,pure_instructions
	.align	4, 0x90
"-[Hi components:splitInto:]":          ## @"\01-[Hi components:splitInto:]"
	.cfi_startproc
## BB#0:
	subq	$40, %rsp
Ltmp1:
	.cfi_def_cfa_offset 48
	movq	%rdi, 32(%rsp)
	movq	%rsi, 24(%rsp)
	movq	%rdx, 16(%rsp)
	movq	%rcx, 8(%rsp)
	movq	L_OBJC_SELECTOR_REFERENCES_(%rip), %rsi
	movq	16(%rsp), %rdi
	movq	%rcx, %rdx
	callq	*_objc_msgSend@GOTPCREL(%rip)
	addq	$40, %rsp
	ret
	.cfi_endproc

	.align	4, 0x90
"-[Hi double:]":                        ## @"\01-[Hi double:]"
	.cfi_startproc
## BB#0:
                                        ## kill: EDX<def> EDX<kill> RDX<def>
	movq	%rdi, -8(%rsp)
	movq	%rsi, -16(%rsp)
	movl	%edx, -20(%rsp)
	leal	(%rdx,%rdx), %eax
	ret
	.cfi_endproc

	.align	4, 0x90
"-[Hi mulByAddition:factor:]":          ## @"\01-[Hi mulByAddition:factor:]"
	.cfi_startproc
## BB#0:
	movq	%rdi, -8(%rsp)
	movq	%rsi, -16(%rsp)
	movl	%edx, -20(%rsp)
	movl	%ecx, -24(%rsp)
	movl	$0, -28(%rsp)
	jmp	LBB2_1
	.align	4, 0x90
LBB2_2:                                 ##   in Loop: Header=BB2_1 Depth=1
	movl	-24(%rsp), %eax
	addl	%eax, -20(%rsp)
	incl	-28(%rsp)
LBB2_1:                                 ## =>This Inner Loop Header: Depth=1
	movl	-28(%rsp), %eax
	cmpl	-24(%rsp), %eax
	jl	LBB2_2
## BB#3:
	movl	-20(%rsp), %eax
	ret
	.cfi_endproc

	.align	4, 0x90
"-[Hi mulByAddition:]":                 ## @"\01-[Hi mulByAddition:]"
	.cfi_startproc
## BB#0:
	subq	$24, %rsp
Ltmp3:
	.cfi_def_cfa_offset 32
	movq	%rdi, 16(%rsp)
	movq	%rsi, 8(%rsp)
	movl	%edx, 4(%rsp)
	movq	_OBJC_IVAR_$_Hi.factor(%rip), %rax
	movq	16(%rsp), %rdi
	movl	(%rdi,%rax), %ecx
	movq	L_OBJC_SELECTOR_REFERENCES_2(%rip), %rsi
	callq	*_objc_msgSend@GOTPCREL(%rip)
	addq	$24, %rsp
	ret
	.cfi_endproc

	.align	4, 0x90
"-[Hi factor]":                         ## @"\01-[Hi factor]"
	.cfi_startproc
## BB#0:
	movq	%rdi, -8(%rsp)
	movq	%rsi, -16(%rsp)
	movq	_OBJC_IVAR_$_Hi.factor(%rip), %rax
	movq	-8(%rsp), %rcx
	movl	(%rcx,%rax), %eax
	ret
	.cfi_endproc

	.align	4, 0x90
"-[Hi setFactor:]":                     ## @"\01-[Hi setFactor:]"
	.cfi_startproc
## BB#0:
	movq	%rdi, -8(%rsp)
	movq	%rsi, -16(%rsp)
	movl	%edx, -20(%rsp)
	movq	_OBJC_IVAR_$_Hi.factor(%rip), %rax
	movq	-8(%rsp), %rcx
	movl	%edx, (%rcx,%rax)
	ret
	.cfi_endproc

	.align	4, 0x90
"-[Hi someProperty]":                   ## @"\01-[Hi someProperty]"
	.cfi_startproc
## BB#0:
	movq	%rdi, -8(%rsp)
	movq	%rsi, -16(%rsp)
	movq	_OBJC_IVAR_$_Hi._someProperty(%rip), %rax
	movq	-8(%rsp), %rcx
	movq	(%rcx,%rax), %rax
	ret
	.cfi_endproc

	.align	4, 0x90
"-[Hi setSomeProperty:]":               ## @"\01-[Hi setSomeProperty:]"
	.cfi_startproc
## BB#0:
	subq	$24, %rsp
Ltmp5:
	.cfi_def_cfa_offset 32
	movq	%rdi, 16(%rsp)
	movq	%rsi, 8(%rsp)
	movq	%rdx, (%rsp)
	movq	_OBJC_IVAR_$_Hi._someProperty(%rip), %rcx
	movq	16(%rsp), %rdi
	movq	8(%rsp), %rsi
	callq	_objc_setProperty_nonatomic
	addq	$24, %rsp
	ret
	.cfi_endproc

	.section	__TEXT,__objc_methname,cstring_literals
L_OBJC_METH_VAR_NAME_:                  ## @"\01L_OBJC_METH_VAR_NAME_"
	.asciz	 "componentsSeparatedByString:"

	.section	__DATA,__objc_selrefs,literal_pointers,no_dead_strip
	.align	3                       ## @"\01L_OBJC_SELECTOR_REFERENCES_"
L_OBJC_SELECTOR_REFERENCES_:
	.quad	L_OBJC_METH_VAR_NAME_

	.section	__DATA,__objc_ivar
	.globl	_OBJC_IVAR_$_Hi.factor  ## @"OBJC_IVAR_$_Hi.factor"
	.align	3
_OBJC_IVAR_$_Hi.factor:
	.quad	8                       ## 0x8

	.section	__TEXT,__objc_methname,cstring_literals
L_OBJC_METH_VAR_NAME_1:                 ## @"\01L_OBJC_METH_VAR_NAME_1"
	.asciz	 "mulByAddition:factor:"

	.section	__DATA,__objc_selrefs,literal_pointers,no_dead_strip
	.align	3                       ## @"\01L_OBJC_SELECTOR_REFERENCES_2"
L_OBJC_SELECTOR_REFERENCES_2:
	.quad	L_OBJC_METH_VAR_NAME_1

	.private_extern	_OBJC_IVAR_$_Hi._someProperty ## @"OBJC_IVAR_$_Hi._someProperty"
	.section	__DATA,__objc_ivar
	.globl	_OBJC_IVAR_$_Hi._someProperty
	.align	3
_OBJC_IVAR_$_Hi._someProperty:
	.quad	16                      ## 0x10

	.section	__TEXT,__objc_classname,cstring_literals
L_OBJC_CLASS_NAME_:                     ## @"\01L_OBJC_CLASS_NAME_"
	.asciz	 "Hi"

	.section	__DATA,__objc_const
	.align	3                       ## @"\01l_OBJC_METACLASS_RO_$_Hi"
l_OBJC_METACLASS_RO_$_Hi:
	.long	1                       ## 0x1
	.long	40                      ## 0x28
	.long	40                      ## 0x28
	.space	4
	.quad	0
	.quad	L_OBJC_CLASS_NAME_
	.quad	0
	.quad	0
	.quad	0
	.quad	0
	.quad	0

	.section	__DATA,__objc_data
	.globl	_OBJC_METACLASS_$_Hi    ## @"OBJC_METACLASS_$_Hi"
	.align	3
_OBJC_METACLASS_$_Hi:
	.quad	_OBJC_METACLASS_$_NSObject
	.quad	_OBJC_METACLASS_$_NSObject
	.quad	__objc_empty_cache
	.quad	__objc_empty_vtable
	.quad	l_OBJC_METACLASS_RO_$_Hi

	.section	__TEXT,__objc_methname,cstring_literals
L_OBJC_METH_VAR_NAME_3:                 ## @"\01L_OBJC_METH_VAR_NAME_3"
	.asciz	 "components:splitInto:"

	.section	__TEXT,__objc_methtype,cstring_literals
L_OBJC_METH_VAR_TYPE_:                  ## @"\01L_OBJC_METH_VAR_TYPE_"
	.asciz	 "@32@0:8@16@24"

	.section	__TEXT,__objc_methname,cstring_literals
L_OBJC_METH_VAR_NAME_4:                 ## @"\01L_OBJC_METH_VAR_NAME_4"
	.asciz	 "double:"

	.section	__TEXT,__objc_methtype,cstring_literals
L_OBJC_METH_VAR_TYPE_5:                 ## @"\01L_OBJC_METH_VAR_TYPE_5"
	.asciz	 "i20@0:8i16"

L_OBJC_METH_VAR_TYPE_6:                 ## @"\01L_OBJC_METH_VAR_TYPE_6"
	.asciz	 "i24@0:8i16i20"

	.section	__TEXT,__objc_methname,cstring_literals
L_OBJC_METH_VAR_NAME_7:                 ## @"\01L_OBJC_METH_VAR_NAME_7"
	.asciz	 "mulByAddition:"

L_OBJC_METH_VAR_NAME_8:                 ## @"\01L_OBJC_METH_VAR_NAME_8"
	.asciz	 "factor"

	.section	__TEXT,__objc_methtype,cstring_literals
L_OBJC_METH_VAR_TYPE_9:                 ## @"\01L_OBJC_METH_VAR_TYPE_9"
	.asciz	 "i16@0:8"

	.section	__TEXT,__objc_methname,cstring_literals
L_OBJC_METH_VAR_NAME_10:                ## @"\01L_OBJC_METH_VAR_NAME_10"
	.asciz	 "setFactor:"

	.section	__TEXT,__objc_methtype,cstring_literals
L_OBJC_METH_VAR_TYPE_11:                ## @"\01L_OBJC_METH_VAR_TYPE_11"
	.asciz	 "v20@0:8i16"

	.section	__TEXT,__objc_methname,cstring_literals
L_OBJC_METH_VAR_NAME_12:                ## @"\01L_OBJC_METH_VAR_NAME_12"
	.asciz	 "someProperty"

	.section	__TEXT,__objc_methtype,cstring_literals
L_OBJC_METH_VAR_TYPE_13:                ## @"\01L_OBJC_METH_VAR_TYPE_13"
	.asciz	 "@16@0:8"

	.section	__TEXT,__objc_methname,cstring_literals
L_OBJC_METH_VAR_NAME_14:                ## @"\01L_OBJC_METH_VAR_NAME_14"
	.asciz	 "setSomeProperty:"

	.section	__TEXT,__objc_methtype,cstring_literals
L_OBJC_METH_VAR_TYPE_15:                ## @"\01L_OBJC_METH_VAR_TYPE_15"
	.asciz	 "v24@0:8@16"

	.section	__DATA,__objc_const
	.align	3                       ## @"\01l_OBJC_$_INSTANCE_METHODS_Hi"
l_OBJC_$_INSTANCE_METHODS_Hi:
	.long	24                      ## 0x18
	.long	8                       ## 0x8
	.quad	L_OBJC_METH_VAR_NAME_3
	.quad	L_OBJC_METH_VAR_TYPE_
	.quad	"-[Hi components:splitInto:]"
	.quad	L_OBJC_METH_VAR_NAME_4
	.quad	L_OBJC_METH_VAR_TYPE_5
	.quad	"-[Hi double:]"
	.quad	L_OBJC_METH_VAR_NAME_1
	.quad	L_OBJC_METH_VAR_TYPE_6
	.quad	"-[Hi mulByAddition:factor:]"
	.quad	L_OBJC_METH_VAR_NAME_7
	.quad	L_OBJC_METH_VAR_TYPE_5
	.quad	"-[Hi mulByAddition:]"
	.quad	L_OBJC_METH_VAR_NAME_8
	.quad	L_OBJC_METH_VAR_TYPE_9
	.quad	"-[Hi factor]"
	.quad	L_OBJC_METH_VAR_NAME_10
	.quad	L_OBJC_METH_VAR_TYPE_11
	.quad	"-[Hi setFactor:]"
	.quad	L_OBJC_METH_VAR_NAME_12
	.quad	L_OBJC_METH_VAR_TYPE_13
	.quad	"-[Hi someProperty]"
	.quad	L_OBJC_METH_VAR_NAME_14
	.quad	L_OBJC_METH_VAR_TYPE_15
	.quad	"-[Hi setSomeProperty:]"

	.section	__TEXT,__objc_methtype,cstring_literals
L_OBJC_METH_VAR_TYPE_16:                ## @"\01L_OBJC_METH_VAR_TYPE_16"
	.asciz	 "i"

	.section	__TEXT,__objc_methname,cstring_literals
L_OBJC_METH_VAR_NAME_17:                ## @"\01L_OBJC_METH_VAR_NAME_17"
	.asciz	 "_someProperty"

	.section	__TEXT,__objc_methtype,cstring_literals
L_OBJC_METH_VAR_TYPE_18:                ## @"\01L_OBJC_METH_VAR_TYPE_18"
	.asciz	 "@"

	.section	__DATA,__objc_const
	.align	3                       ## @"\01l_OBJC_$_INSTANCE_VARIABLES_Hi"
l_OBJC_$_INSTANCE_VARIABLES_Hi:
	.long	32                      ## 0x20
	.long	2                       ## 0x2
	.quad	_OBJC_IVAR_$_Hi.factor
	.quad	L_OBJC_METH_VAR_NAME_8
	.quad	L_OBJC_METH_VAR_TYPE_16
	.long	2                       ## 0x2
	.long	4                       ## 0x4
	.quad	_OBJC_IVAR_$_Hi._someProperty
	.quad	L_OBJC_METH_VAR_NAME_17
	.quad	L_OBJC_METH_VAR_TYPE_18
	.long	3                       ## 0x3
	.long	8                       ## 0x8

	.section	__TEXT,__cstring,cstring_literals
L_OBJC_PROP_NAME_ATTR_:                 ## @"\01L_OBJC_PROP_NAME_ATTR_"
	.asciz	 "factor"

L_OBJC_PROP_NAME_ATTR_19:               ## @"\01L_OBJC_PROP_NAME_ATTR_19"
	.asciz	 "Ti,Vfactor"

L_OBJC_PROP_NAME_ATTR_20:               ## @"\01L_OBJC_PROP_NAME_ATTR_20"
	.asciz	 "someProperty"

L_OBJC_PROP_NAME_ATTR_21:               ## @"\01L_OBJC_PROP_NAME_ATTR_21"
	.asciz	 "T@,&,N,V_someProperty"

	.section	__DATA,__objc_const
	.align	3                       ## @"\01l_OBJC_$_PROP_LIST_Hi"
l_OBJC_$_PROP_LIST_Hi:
	.long	16                      ## 0x10
	.long	2                       ## 0x2
	.quad	L_OBJC_PROP_NAME_ATTR_
	.quad	L_OBJC_PROP_NAME_ATTR_19
	.quad	L_OBJC_PROP_NAME_ATTR_20
	.quad	L_OBJC_PROP_NAME_ATTR_21

	.align	3                       ## @"\01l_OBJC_CLASS_RO_$_Hi"
l_OBJC_CLASS_RO_$_Hi:
	.long	0                       ## 0x0
	.long	8                       ## 0x8
	.long	24                      ## 0x18
	.space	4
	.quad	0
	.quad	L_OBJC_CLASS_NAME_
	.quad	l_OBJC_$_INSTANCE_METHODS_Hi
	.quad	0
	.quad	l_OBJC_$_INSTANCE_VARIABLES_Hi
	.quad	0
	.quad	l_OBJC_$_PROP_LIST_Hi

	.section	__DATA,__objc_data
	.globl	_OBJC_CLASS_$_Hi        ## @"OBJC_CLASS_$_Hi"
	.align	3
_OBJC_CLASS_$_Hi:
	.quad	_OBJC_METACLASS_$_Hi
	.quad	_OBJC_CLASS_$_NSObject
	.quad	__objc_empty_cache
	.quad	__objc_empty_vtable
	.quad	l_OBJC_CLASS_RO_$_Hi

	.section	__DATA,__objc_classlist,regular,no_dead_strip
	.align	3                       ## @"\01L_OBJC_LABEL_CLASS_$"
L_OBJC_LABEL_CLASS_$:
	.quad	_OBJC_CLASS_$_Hi

	.section	__DATA,__objc_imageinfo,regular,no_dead_strip
L_OBJC_IMAGE_INFO:
	.long	0
	.long	0


.subsections_via_symbols
