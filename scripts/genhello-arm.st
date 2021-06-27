#!env stsh

framework:ObjSTNative load
true
arm := MPWARMAssemblyGenerator stream 
arm global:'_start'.
arm align:2
arm label:'_start'.
arm mov:0 value:1
arm adr:1 address:'helloworld'
arm mov:2 value:13
arm mov:16 value:4
arm svc: 128
arm mov:0 value:0
arm mov:16 value:1
arm svc: 128 
arm label:'helloworld'
arm asciiz:'Hello World!!!'

file:hello.s := arm target 

# how to assemble and link:
#  as -o hello.o hello.s 
#  ld -o hello hello.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _start -arch arm64  
#
