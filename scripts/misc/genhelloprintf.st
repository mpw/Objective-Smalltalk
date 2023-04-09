#!env stsh
#-gen:msg

messageLabel ← 'message'.
main ← '_main'.

LR ← 30.
SP ← -1.
ZR ← -2.

framework:ObjSTNative load
arm := MPWARMAssemblyGenerator stream 
arm global: main;
    align:  2;
    label: main;
		stp:29 second:LR addressRegister:SP offset:-16;
		sub:SP sourceReg:SP sourceValue:16;
		add:29 sourceReg:SP sourceValue:0;	
		adr:0 address:messageLabel;
		bl:'_puts';
		mov:0 value:0;
		ldp:29 second:LR addressRegister:SP offset:16;
		ret;
	label:messageLabel;
		asciiz:msg.

file:hello-printf.s := arm target 

