; ModuleID = 'method-returning-arg-category.m'
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.8.0"

%0 = type opaque
%struct._class_t = type { %struct._class_t*, %struct._class_t*, %struct._objc_cache*, i8* (i8*, i8*)**, %struct._class_ro_t* }
%struct._objc_cache = type opaque
%struct._class_ro_t = type { i32, i32, i32, i8*, i8*, %struct.__method_list_t*, %struct._objc_protocol_list*, %struct._ivar_list_t*, i8*, %struct._prop_list_t* }
%struct.__method_list_t = type { i32, i32, [0 x %struct._objc_method] }
%struct._objc_method = type { i8*, i8*, i8* }
%struct._objc_protocol_list = type { i64, [0 x %struct._protocol_t*] }
%struct._protocol_t = type { i8*, i8*, %struct._objc_protocol_list*, %struct.__method_list_t*, %struct.__method_list_t*, %struct.__method_list_t*, %struct.__method_list_t*, %struct._prop_list_t*, i32, i32, i8** }
%struct._prop_list_t = type { i32, i32, [0 x %struct._prop_t] }
%struct._prop_t = type { i8*, i8* }
%struct._ivar_list_t = type { i32, i32, [0 x %struct._ivar_t] }
%struct._ivar_t = type { i64*, i8*, i8*, i32, i32 }
%struct._category_t = type { i8*, %struct._class_t*, %struct.__method_list_t*, %struct.__method_list_t*, %struct._objc_protocol_list*, %struct._prop_list_t* }

@"\01L_OBJC_CLASS_NAME_" = internal global [6 x i8] c"empty\00", section "__TEXT,__objc_classname,cstring_literals", align 1
@"OBJC_CLASS_$_NSObject" = external global %struct._class_t
@"\01L_OBJC_METH_VAR_NAME_" = internal global [7 x i8] c"empty:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_TYPE_" = internal global [11 x i8] c"@24@0:8@16\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01l_OBJC_$_CATEGORY_INSTANCE_METHODS_NSObject_$_empty" = internal global { i32, i32, [1 x %struct._objc_method] } { i32 24, i32 1, [1 x %struct._objc_method] [%struct._objc_method { i8* getelementptr inbounds ([7 x i8]* @"\01L_OBJC_METH_VAR_NAME_", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_", i32 0, i32 0), i8* bitcast (i8* (%0*, i8*, i8*)* @"\01-[NSObject(empty) empty:]" to i8*) }] }, section "__DATA, __objc_const", align 8
@"\01l_OBJC_$_CATEGORY_NSObject_$_empty" = internal global %struct._category_t { i8* getelementptr inbounds ([6 x i8]* @"\01L_OBJC_CLASS_NAME_", i32 0, i32 0), %struct._class_t* @"OBJC_CLASS_$_NSObject", %struct.__method_list_t* bitcast ({ i32, i32, [1 x %struct._objc_method] }* @"\01l_OBJC_$_CATEGORY_INSTANCE_METHODS_NSObject_$_empty" to %struct.__method_list_t*), %struct.__method_list_t* null, %struct._objc_protocol_list* null, %struct._prop_list_t* null }, section "__DATA, __objc_const", align 8
@"\01L_OBJC_LABEL_CATEGORY_$" = internal global [1 x i8*] [i8* bitcast (%struct._category_t* @"\01l_OBJC_$_CATEGORY_NSObject_$_empty" to i8*)], section "__DATA, __objc_catlist, regular, no_dead_strip", align 8
@llvm.used = appending global [6 x i8*] [i8* getelementptr inbounds ([6 x i8]* @"\01L_OBJC_CLASS_NAME_", i32 0, i32 0), i8* getelementptr inbounds ([7 x i8]* @"\01L_OBJC_METH_VAR_NAME_", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_", i32 0, i32 0), i8* bitcast ({ i32, i32, [1 x %struct._objc_method] }* @"\01l_OBJC_$_CATEGORY_INSTANCE_METHODS_NSObject_$_empty" to i8*), i8* bitcast (%struct._category_t* @"\01l_OBJC_$_CATEGORY_NSObject_$_empty" to i8*), i8* bitcast ([1 x i8*]* @"\01L_OBJC_LABEL_CATEGORY_$" to i8*)], section "llvm.metadata"

define internal i8* @"\01-[NSObject(empty) empty:]"(%0* %self, i8* %_cmd, i8* %arg) uwtable ssp {
  %1 = alloca %0*, align 8
  %2 = alloca i8*, align 8
  %3 = alloca i8*, align 8
  store %0* %self, %0** %1, align 8
  store i8* %_cmd, i8** %2, align 8
  store i8* %arg, i8** %3, align 8
  %4 = load i8** %3, align 8
  ret i8* %4
}

!llvm.module.flags = !{!0, !1, !2, !3}

!0 = metadata !{i32 1, metadata !"Objective-C Version", i32 2}
!1 = metadata !{i32 1, metadata !"Objective-C Image Info Version", i32 0}
!2 = metadata !{i32 1, metadata !"Objective-C Image Info Section", metadata !"__DATA, __objc_imageinfo, regular, no_dead_strip"}
!3 = metadata !{i32 4, metadata !"Objective-C Garbage Collection", i32 0}
