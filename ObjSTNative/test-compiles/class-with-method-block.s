; ModuleID = 'class-with-method-block.m'
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.9.0"

%0 = type opaque
%1 = type opaque
%2 = type opaque
%3 = type opaque
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
%struct.__block_descriptor = type { i64, i64 }

@"OBJC_CLASS_$_NSMutableArray" = external global %struct._class_t
@"\01L_OBJC_CLASSLIST_REFERENCES_$_" = internal global %struct._class_t* @"OBJC_CLASS_$_NSMutableArray", section "__DATA, __objc_classrefs, regular, no_dead_strip", align 8
@"\01L_OBJC_METH_VAR_NAME_" = internal global [6 x i8] c"array\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_SELECTOR_REFERENCES_" = internal externally_initialized global i8* getelementptr inbounds ([6 x i8]* @"\01L_OBJC_METH_VAR_NAME_", i32 0, i32 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip"
@"\01L_OBJC_METH_VAR_NAME_1" = internal global [11 x i8] c"addObject:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_SELECTOR_REFERENCES_2" = internal externally_initialized global i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_NAME_1", i32 0, i32 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip"
@_NSConcreteStackBlock = external global i8*
@.str = private unnamed_addr constant [23 x i8] c"v24@?0@\22NSString\228^c16\00", align 1
@__block_descriptor_tmp = internal constant { i64, i64, i8*, i8*, i8*, i64 } { i64 0, i64 40, i8* bitcast (void (i8*, i8*)* @__copy_helper_block_ to i8*), i8* bitcast (void (i8*)* @__destroy_helper_block_ to i8*), i8* getelementptr inbounds ([23 x i8]* @.str, i32 0, i32 0), i64 256 }
@"\01L_OBJC_METH_VAR_NAME_3" = internal global [26 x i8] c"enumerateLinesUsingBlock:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_SELECTOR_REFERENCES_4" = internal externally_initialized global i8* getelementptr inbounds ([26 x i8]* @"\01L_OBJC_METH_VAR_NAME_3", i32 0, i32 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip"
@_objc_empty_cache = external global %struct._objc_cache
@_objc_empty_vtable = external global i8* (i8*, i8*)*
@"OBJC_METACLASS_$_NSObject" = external global %struct._class_t
@"\01L_OBJC_CLASS_NAME_" = internal global [3 x i8] c"Hi\00", section "__TEXT,__objc_classname,cstring_literals", align 1
@"\01l_OBJC_METACLASS_RO_$_Hi" = internal global %struct._class_ro_t { i32 1, i32 40, i32 40, i8* null, i8* getelementptr inbounds ([3 x i8]* @"\01L_OBJC_CLASS_NAME_", i32 0, i32 0), %struct.__method_list_t* null, %struct._objc_protocol_list* null, %struct._ivar_list_t* null, i8* null, %struct._prop_list_t* null }, section "__DATA, __objc_const", align 8
@"OBJC_METACLASS_$_Hi" = global %struct._class_t { %struct._class_t* @"OBJC_METACLASS_$_NSObject", %struct._class_t* @"OBJC_METACLASS_$_NSObject", %struct._objc_cache* @_objc_empty_cache, i8* (i8*, i8*)** @_objc_empty_vtable, %struct._class_ro_t* @"\01l_OBJC_METACLASS_RO_$_Hi" }, section "__DATA, __objc_data", align 8
@"OBJC_CLASS_$_NSObject" = external global %struct._class_t
@"\01L_OBJC_METH_VAR_NAME_5" = internal global [7 x i8] c"lines:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_TYPE_" = internal global [11 x i8] c"@24@0:8@16\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01l_OBJC_$_INSTANCE_METHODS_Hi" = internal global { i32, i32, [1 x %struct._objc_method] } { i32 24, i32 1, [1 x %struct._objc_method] [%struct._objc_method { i8* getelementptr inbounds ([7 x i8]* @"\01L_OBJC_METH_VAR_NAME_5", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_", i32 0, i32 0), i8* bitcast (%0* (%1*, i8*, %2*)* @"\01-[Hi lines:]" to i8*) }] }, section "__DATA, __objc_const", align 8
@"\01l_OBJC_CLASS_RO_$_Hi" = internal global %struct._class_ro_t { i32 0, i32 8, i32 8, i8* null, i8* getelementptr inbounds ([3 x i8]* @"\01L_OBJC_CLASS_NAME_", i32 0, i32 0), %struct.__method_list_t* bitcast ({ i32, i32, [1 x %struct._objc_method] }* @"\01l_OBJC_$_INSTANCE_METHODS_Hi" to %struct.__method_list_t*), %struct._objc_protocol_list* null, %struct._ivar_list_t* null, i8* null, %struct._prop_list_t* null }, section "__DATA, __objc_const", align 8
@"OBJC_CLASS_$_Hi" = global %struct._class_t { %struct._class_t* @"OBJC_METACLASS_$_Hi", %struct._class_t* @"OBJC_CLASS_$_NSObject", %struct._objc_cache* @_objc_empty_cache, i8* (i8*, i8*)** @_objc_empty_vtable, %struct._class_ro_t* @"\01l_OBJC_CLASS_RO_$_Hi" }, section "__DATA, __objc_data", align 8
@"\01L_OBJC_LABEL_CLASS_$" = internal global [1 x i8*] [i8* bitcast (%struct._class_t* @"OBJC_CLASS_$_Hi" to i8*)], section "__DATA, __objc_classlist, regular, no_dead_strip", align 8
@llvm.used = appending global [12 x i8*] [i8* bitcast (%struct._class_t** @"\01L_OBJC_CLASSLIST_REFERENCES_$_" to i8*), i8* getelementptr inbounds ([6 x i8]* @"\01L_OBJC_METH_VAR_NAME_", i32 0, i32 0), i8* bitcast (i8** @"\01L_OBJC_SELECTOR_REFERENCES_" to i8*), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_NAME_1", i32 0, i32 0), i8* bitcast (i8** @"\01L_OBJC_SELECTOR_REFERENCES_2" to i8*), i8* getelementptr inbounds ([26 x i8]* @"\01L_OBJC_METH_VAR_NAME_3", i32 0, i32 0), i8* bitcast (i8** @"\01L_OBJC_SELECTOR_REFERENCES_4" to i8*), i8* getelementptr inbounds ([3 x i8]* @"\01L_OBJC_CLASS_NAME_", i32 0, i32 0), i8* getelementptr inbounds ([7 x i8]* @"\01L_OBJC_METH_VAR_NAME_5", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_", i32 0, i32 0), i8* bitcast ({ i32, i32, [1 x %struct._objc_method] }* @"\01l_OBJC_$_INSTANCE_METHODS_Hi" to i8*), i8* bitcast ([1 x i8*]* @"\01L_OBJC_LABEL_CLASS_$" to i8*)], section "llvm.metadata"

define internal %0* @"\01-[Hi lines:]"(%1* %self, i8* %_cmd, %2* %s) ssp uwtable {
  %1 = alloca %1*, align 8
  %2 = alloca i8*, align 8
  %3 = alloca %2*, align 8
  %lines = alloca %3*, align 8
  %4 = alloca <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>, align 8
  store %1* %self, %1** %1, align 8
  store i8* %_cmd, i8** %2, align 8
  store %2* %s, %2** %3, align 8
  %5 = load %struct._class_t** @"\01L_OBJC_CLASSLIST_REFERENCES_$_"
  %6 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_", !invariant.load !4
  %7 = bitcast %struct._class_t* %5 to i8*
  %8 = call i8* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to i8* (i8*, i8*)*)(i8* %7, i8* %6)
  %9 = bitcast i8* %8 to %3*
  store %3* %9, %3** %lines, align 8
  %10 = load %2** %3, align 8
  %11 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %4, i32 0, i32 0
  store i8* bitcast (i8** @_NSConcreteStackBlock to i8*), i8** %11
  %12 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %4, i32 0, i32 1
  store i32 -1040187392, i32* %12
  %13 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %4, i32 0, i32 2
  store i32 0, i32* %13
  %14 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %4, i32 0, i32 3
  store i8* bitcast (void (i8*, %2*, i8*)* @"__12-[Hi lines:]_block_invoke" to i8*), i8** %14
  %15 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %4, i32 0, i32 4
  store %struct.__block_descriptor* bitcast ({ i64, i64, i8*, i8*, i8*, i64 }* @__block_descriptor_tmp to %struct.__block_descriptor*), %struct.__block_descriptor** %15
  %16 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %4, i32 0, i32 5
  %17 = load %3** %lines, align 8
  store %3* %17, %3** %16, align 8
  %18 = bitcast <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %4 to void (%2*, i8*)*
  %19 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_4", !invariant.load !4
  %20 = bitcast %2* %10 to i8*
  call void bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to void (i8*, i8*, void (%2*, i8*)*)*)(i8* %20, i8* %19, void (%2*, i8*)* %18)
  %21 = load %3** %lines, align 8
  %22 = bitcast %3* %21 to %0*
  ret %0* %22
}

declare i8* @objc_msgSend(i8*, i8*, ...) nonlazybind

define internal void @"__12-[Hi lines:]_block_invoke"(i8* %.block_descriptor, %2* %line, i8* %stop) ssp uwtable {
  %1 = alloca i8*, align 8
  %2 = alloca %2*, align 8
  %3 = alloca i8*, align 8
  %4 = alloca <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>*, align 8
  store i8* %.block_descriptor, i8** %1, align 8
  %5 = load i8** %1
  store %2* %line, %2** %2, align 8
  store i8* %stop, i8** %3, align 8
  %6 = bitcast i8* %.block_descriptor to <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>*
  store <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %6, <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>** %4, align 8
  %7 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %6, i32 0, i32 5
  %8 = load %3** %7, align 8
  %9 = load %2** %2, align 8
  %10 = bitcast %2* %9 to i8*
  %11 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_2", !invariant.load !4
  %12 = bitcast %3* %8 to i8*
  call void bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to void (i8*, i8*, i8*)*)(i8* %12, i8* %11, i8* %10)
  ret void
}

define internal void @__copy_helper_block_(i8*, i8*) {
  %3 = alloca i8*, align 8
  %4 = alloca i8*, align 8
  store i8* %0, i8** %3, align 8
  store i8* %1, i8** %4, align 8
  %5 = load i8** %4
  %6 = bitcast i8* %5 to <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>*
  %7 = load i8** %3
  %8 = bitcast i8* %7 to <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>*
  %9 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %6, i32 0, i32 5
  %10 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %8, i32 0, i32 5
  %11 = load %3** %9
  %12 = bitcast %3* %11 to i8*
  %13 = bitcast %3** %10 to i8*
  call void @_Block_object_assign(i8* %13, i8* %12, i32 3) nounwind
  ret void
}

declare void @_Block_object_assign(i8*, i8*, i32)

define internal void @__destroy_helper_block_(i8*) {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8
  %3 = load i8** %2
  %4 = bitcast i8* %3 to <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>*
  %5 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %4, i32 0, i32 5
  %6 = load %3** %5
  %7 = bitcast %3* %6 to i8*
  call void @_Block_object_dispose(i8* %7, i32 3) nounwind
  ret void
}

declare void @_Block_object_dispose(i8*, i32)

!llvm.module.flags = !{!0, !1, !2, !3}

!0 = metadata !{i32 1, metadata !"Objective-C Version", i32 2}
!1 = metadata !{i32 1, metadata !"Objective-C Image Info Version", i32 0}
!2 = metadata !{i32 1, metadata !"Objective-C Image Info Section", metadata !"__DATA, __objc_imageinfo, regular, no_dead_strip"}
!3 = metadata !{i32 4, metadata !"Objective-C Garbage Collection", i32 0}
!4 = metadata !{}
