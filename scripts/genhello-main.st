#!env stsh
#-gen:msg

messageLabel ← 'message'.
main ← '_main'.

framework:ObjSTNative load
arm := MPWARMAssemblyGenerator stream 
arm global: main;
    align:2;
    label:main;
    mov:0 value:1;
    adr:1 address:messageLabel;
    mov:2 value: msg length;
    mov:16 value:4;
    svc: 128;
    mov:0 value:0;
    ret;
    label:messageLabel;
    asciiz:msg.

file:hello-main.s := arm target 

