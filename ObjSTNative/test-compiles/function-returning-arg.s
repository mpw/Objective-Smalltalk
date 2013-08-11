; ModuleID = 'function-returning-arg.m'
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.8.0"

define i8* @fn(i8* %arg) nounwind uwtable ssp {
  %1 = alloca i8*, align 8
  store i8* %arg, i8** %1, align 8
  %2 = load i8** %1, align 8
  ret i8* %2
}

!llvm.module.flags = !{!0, !1, !2, !3}

!0 = metadata !{i32 1, metadata !"Objective-C Version", i32 2}
!1 = metadata !{i32 1, metadata !"Objective-C Image Info Version", i32 0}
!2 = metadata !{i32 1, metadata !"Objective-C Image Info Section", metadata !"__DATA, __objc_imageinfo, regular, no_dead_strip"}
!3 = metadata !{i32 4, metadata !"Objective-C Garbage Collection", i32 0}
