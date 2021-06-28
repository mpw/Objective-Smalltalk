#!env stsh
#-gen:msg

messageLabel ← 'message'.

framework:ObjSTNative load
true
arm := MPWARMAssemblyGenerator stream 
arm global:'_main'.
arm align:2
arm label:'_main'.
arm mov:0 value:1
arm adr:1 address:messageLabel.
arm mov:2 value: msg length.
arm mov:16 value:4
arm svc: 128
arm ret.
arm label:messageLabel.
arm asciiz:msg.

file:hello-main.s := arm target 

# how to assemble and link:
#  as -o hello.o hello.s 
#  ld -o hello hello.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _start -arch arm64  
#
