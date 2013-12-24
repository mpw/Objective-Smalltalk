#!/bin/bash
base=`basename $1 .s`
llc -filetype=obj  $base.s  -o $base.o
ld  -macosx_version_min 10.8 -dylib -o $base.dylib $base.o -framework Foundation 
