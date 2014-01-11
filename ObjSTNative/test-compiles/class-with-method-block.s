; ModuleID = 'class-with-method-block.m'
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.9.0"

%0 = type opaque
%1 = type opaque
%2 = type opaque
%3 = type opaque
%struct.__block_descriptor = type { i64, i64 }
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
%struct.__block_literal_generic = type { i8*, i32, i32, i8*, %struct.__block_descriptor* }

@"\01L_OBJC_METH_VAR_NAME_" = internal global [16 x i8] c"uppercaseString\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_SELECTOR_REFERENCES_" = internal externally_initialized global i8* getelementptr inbounds ([16 x i8]* @"\01L_OBJC_METH_VAR_NAME_", i64 0, i64 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip"
@_NSConcreteGlobalBlock = external global i8*
@.str = private unnamed_addr constant [29 x i8] c"@\22NSString\2216@?0@\22NSString\228\00", align 1
@__block_descriptor_tmp = internal constant { i64, i64, i8*, i8* } { i64 0, i64 32, i8* getelementptr inbounds ([29 x i8]* @.str, i32 0, i32 0), i8* null }
@__block_literal_global = internal constant { i8**, i32, i32, i8*, %struct.__block_descriptor* } { i8** @_NSConcreteGlobalBlock, i32 1342177280, i32 0, i8* bitcast (%0* (i8*, %0*)* @"__24-[Hi noCaptureBlockUse:]_block_invoke" to i8*), %struct.__block_descriptor* bitcast ({ i64, i64, i8*, i8* }* @__block_descriptor_tmp to %struct.__block_descriptor*) }, align 8
@"\01L_OBJC_METH_VAR_NAME_1" = internal global [16 x i8] c"onLine:execute:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_SELECTOR_REFERENCES_2" = internal externally_initialized global i8* getelementptr inbounds ([16 x i8]* @"\01L_OBJC_METH_VAR_NAME_1", i64 0, i64 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip"
@"OBJC_CLASS_$_NSMutableArray" = external global %struct._class_t
@"\01L_OBJC_CLASSLIST_REFERENCES_$_" = internal global %struct._class_t* @"OBJC_CLASS_$_NSMutableArray", section "__DATA, __objc_classrefs, regular, no_dead_strip", align 8
@"\01L_OBJC_METH_VAR_NAME_3" = internal global [6 x i8] c"array\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_SELECTOR_REFERENCES_4" = internal externally_initialized global i8* getelementptr inbounds ([6 x i8]* @"\01L_OBJC_METH_VAR_NAME_3", i64 0, i64 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip"
@"\01L_OBJC_METH_VAR_NAME_5" = internal global [11 x i8] c"addObject:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_SELECTOR_REFERENCES_6" = internal externally_initialized global i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_NAME_5", i64 0, i64 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip"
@_NSConcreteStackBlock = external global i8*
@.str7 = private unnamed_addr constant [23 x i8] c"v24@?0@\22NSString\228^c16\00", align 1
@__block_descriptor_tmp8 = internal constant { i64, i64, i8*, i8*, i8*, i64 } { i64 0, i64 40, i8* bitcast (void (i8*, i8*)* @__copy_helper_block_ to i8*), i8* bitcast (void (i8*)* @__destroy_helper_block_ to i8*), i8* getelementptr inbounds ([23 x i8]* @.str7, i32 0, i32 0), i64 256 }
@"\01L_OBJC_METH_VAR_NAME_9" = internal global [26 x i8] c"enumerateLinesUsingBlock:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_SELECTOR_REFERENCES_10" = internal externally_initialized global i8* getelementptr inbounds ([26 x i8]* @"\01L_OBJC_METH_VAR_NAME_9", i64 0, i64 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip"
@_objc_empty_cache = external global %struct._objc_cache
@_objc_empty_vtable = external global i8* (i8*, i8*)*
@"OBJC_METACLASS_$_NSObject" = external global %struct._class_t
@"\01L_OBJC_CLASS_NAME_" = internal global [3 x i8] c"Hi\00", section "__TEXT,__objc_classname,cstring_literals", align 1
@"\01l_OBJC_METACLASS_RO_$_Hi" = internal global %struct._class_ro_t { i32 1, i32 40, i32 40, i8* null, i8* getelementptr inbounds ([3 x i8]* @"\01L_OBJC_CLASS_NAME_", i32 0, i32 0), %struct.__method_list_t* null, %struct._objc_protocol_list* null, %struct._ivar_list_t* null, i8* null, %struct._prop_list_t* null }, section "__DATA, __objc_const", align 8
@"OBJC_METACLASS_$_Hi" = global %struct._class_t { %struct._class_t* @"OBJC_METACLASS_$_NSObject", %struct._class_t* @"OBJC_METACLASS_$_NSObject", %struct._objc_cache* @_objc_empty_cache, i8* (i8*, i8*)** @_objc_empty_vtable, %struct._class_ro_t* @"\01l_OBJC_METACLASS_RO_$_Hi" }, section "__DATA, __objc_data", align 8
@"OBJC_CLASS_$_NSObject" = external global %struct._class_t
@"\01L_OBJC_METH_VAR_TYPE_" = internal global [15 x i8] c"@32@0:8@16@?24\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_NAME_11" = internal global [19 x i8] c"noCaptureBlockUse:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_TYPE_12" = internal global [11 x i8] c"@24@0:8@16\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_NAME_13" = internal global [7 x i8] c"lines:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01l_OBJC_$_INSTANCE_METHODS_Hi" = internal global { i32, i32, [3 x %struct._objc_method] } { i32 24, i32 3, [3 x %struct._objc_method] [%struct._objc_method { i8* getelementptr inbounds ([16 x i8]* @"\01L_OBJC_METH_VAR_NAME_1", i32 0, i32 0), i8* getelementptr inbounds ([15 x i8]* @"\01L_OBJC_METH_VAR_TYPE_", i32 0, i32 0), i8* bitcast (%0* (%1*, i8*, %0*, %0* (%0*)*)* @"\01-[Hi onLine:execute:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([19 x i8]* @"\01L_OBJC_METH_VAR_NAME_11", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_12", i32 0, i32 0), i8* bitcast (%0* (%1*, i8*, %0*)* @"\01-[Hi noCaptureBlockUse:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([7 x i8]* @"\01L_OBJC_METH_VAR_NAME_13", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_12", i32 0, i32 0), i8* bitcast (%2* (%1*, i8*, %0*)* @"\01-[Hi lines:]" to i8*) }] }, section "__DATA, __objc_const", align 8
@"\01l_OBJC_CLASS_RO_$_Hi" = internal global %struct._class_ro_t { i32 0, i32 8, i32 8, i8* null, i8* getelementptr inbounds ([3 x i8]* @"\01L_OBJC_CLASS_NAME_", i32 0, i32 0), %struct.__method_list_t* bitcast ({ i32, i32, [3 x %struct._objc_method] }* @"\01l_OBJC_$_INSTANCE_METHODS_Hi" to %struct.__method_list_t*), %struct._objc_protocol_list* null, %struct._ivar_list_t* null, i8* null, %struct._prop_list_t* null }, section "__DATA, __objc_const", align 8
@"OBJC_CLASS_$_Hi" = global %struct._class_t { %struct._class_t* @"OBJC_METACLASS_$_Hi", %struct._class_t* @"OBJC_CLASS_$_NSObject", %struct._objc_cache* @_objc_empty_cache, i8* (i8*, i8*)** @_objc_empty_vtable, %struct._class_ro_t* @"\01l_OBJC_CLASS_RO_$_Hi" }, section "__DATA, __objc_data", align 8
@"\01L_OBJC_LABEL_CLASS_$" = internal global [1 x i8*] [i8* bitcast (%struct._class_t* @"OBJC_CLASS_$_Hi" to i8*)], section "__DATA, __objc_classlist, regular, no_dead_strip", align 8
@llvm.used = appending global [18 x i8*] [i8* getelementptr inbounds ([16 x i8]* @"\01L_OBJC_METH_VAR_NAME_", i32 0, i32 0), i8* bitcast (i8** @"\01L_OBJC_SELECTOR_REFERENCES_" to i8*), i8* getelementptr inbounds ([16 x i8]* @"\01L_OBJC_METH_VAR_NAME_1", i32 0, i32 0), i8* bitcast (i8** @"\01L_OBJC_SELECTOR_REFERENCES_2" to i8*), i8* bitcast (%struct._class_t** @"\01L_OBJC_CLASSLIST_REFERENCES_$_" to i8*), i8* getelementptr inbounds ([6 x i8]* @"\01L_OBJC_METH_VAR_NAME_3", i32 0, i32 0), i8* bitcast (i8** @"\01L_OBJC_SELECTOR_REFERENCES_4" to i8*), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_NAME_5", i32 0, i32 0), i8* bitcast (i8** @"\01L_OBJC_SELECTOR_REFERENCES_6" to i8*), i8* getelementptr inbounds ([26 x i8]* @"\01L_OBJC_METH_VAR_NAME_9", i32 0, i32 0), i8* bitcast (i8** @"\01L_OBJC_SELECTOR_REFERENCES_10" to i8*), i8* getelementptr inbounds ([3 x i8]* @"\01L_OBJC_CLASS_NAME_", i32 0, i32 0), i8* getelementptr inbounds ([15 x i8]* @"\01L_OBJC_METH_VAR_TYPE_", i32 0, i32 0), i8* getelementptr inbounds ([19 x i8]* @"\01L_OBJC_METH_VAR_NAME_11", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_12", i32 0, i32 0), i8* getelementptr inbounds ([7 x i8]* @"\01L_OBJC_METH_VAR_NAME_13", i32 0, i32 0), i8* bitcast ({ i32, i32, [3 x %struct._objc_method] }* @"\01l_OBJC_$_INSTANCE_METHODS_Hi" to i8*), i8* bitcast ([1 x i8*]* @"\01L_OBJC_LABEL_CLASS_$" to i8*)], section "llvm.metadata"

define internal %0* @"\01-[Hi onLine:execute:]"(%1* nocapture %self, i8* nocapture %_cmd, %0* %line, %0* (%0*)* %block) optsize ssp uwtable {
  %1 = bitcast %0* (%0*)* %block to %struct.__block_literal_generic*
  %2 = getelementptr inbounds %struct.__block_literal_generic* %1, i64 0, i32 3
  %3 = bitcast %0* (%0*)* %block to i8*
  %4 = load i8** %2, align 8
  %5 = bitcast i8* %4 to %0* (i8*, %0*)*
  %6 = tail call %0* %5(i8* %3, %0* %line) optsize
  ret %0* %6
}

define internal %0* @"\01-[Hi noCaptureBlockUse:]"(%1* %self, i8* nocapture %_cmd, %0* %s) optsize ssp uwtable {
  %1 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_2", align 8, !invariant.load !4
  %2 = bitcast %1* %self to i8*
  %3 = tail call %0* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %0* (i8*, i8*, %0*, %0* (%0*)*)*)(i8* %2, i8* %1, %0* %s, %0* (%0*)* bitcast ({ i8**, i32, i32, i8*, %struct.__block_descriptor* }* @__block_literal_global to %0* (%0*)*)) optsize
  ret %0* %3
}

define internal %0* @"__24-[Hi noCaptureBlockUse:]_block_invoke"(i8* nocapture %.block_descriptor, %0* %s) optsize ssp uwtable {
  %1 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_", align 8, !invariant.load !4
  %2 = bitcast %0* %s to i8*
  %3 = tail call %0* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %0* (i8*, i8*)*)(i8* %2, i8* %1) optsize
  ret %0* %3
}

declare i8* @objc_msgSend(i8*, i8*, ...) nonlazybind

define internal %2* @"\01-[Hi lines:]"(%1* nocapture %self, i8* nocapture %_cmd, %0* %s) optsize ssp uwtable {
  %1 = alloca <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>, align 8
  %2 = load %struct._class_t** @"\01L_OBJC_CLASSLIST_REFERENCES_$_", align 8
  %3 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_4", align 8, !invariant.load !4
  %4 = bitcast %struct._class_t* %2 to i8*
  %5 = call i8* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to i8* (i8*, i8*)*)(i8* %4, i8* %3) optsize
  %6 = bitcast i8* %5 to %3*
  %7 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %1, i64 0, i32 0
  store i8* bitcast (i8** @_NSConcreteStackBlock to i8*), i8** %7, align 8
  %8 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %1, i64 0, i32 1
  store i32 -1040187392, i32* %8, align 8
  %9 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %1, i64 0, i32 2
  store i32 0, i32* %9, align 4
  %10 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %1, i64 0, i32 3
  store i8* bitcast (void (i8*, %0*, i8*)* @"__12-[Hi lines:]_block_invoke" to i8*), i8** %10, align 8
  %11 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %1, i64 0, i32 4
  store %struct.__block_descriptor* bitcast ({ i64, i64, i8*, i8*, i8*, i64 }* @__block_descriptor_tmp8 to %struct.__block_descriptor*), %struct.__block_descriptor** %11, align 8
  %12 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %1, i64 0, i32 5
  store %3* %6, %3** %12, align 8, !tbaa !5
  %13 = bitcast <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %1 to void (%0*, i8*)*
  %14 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_10", align 8, !invariant.load !4
  %15 = bitcast %0* %s to i8*
  call void bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to void (i8*, i8*, void (%0*, i8*)*)*)(i8* %15, i8* %14, void (%0*, i8*)* %13) optsize
  %16 = bitcast i8* %5 to %2*
  ret %2* %16
}

define internal void @"__12-[Hi lines:]_block_invoke"(i8* nocapture %.block_descriptor, %0* %line, i8* nocapture %stop) optsize ssp uwtable {
  %1 = getelementptr inbounds i8* %.block_descriptor, i64 32
  %2 = bitcast i8* %1 to %3**
  %3 = load %3** %2, align 8, !tbaa !5
  %4 = bitcast %0* %line to i8*
  %5 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_6", align 8, !invariant.load !4
  %6 = bitcast %3* %3 to i8*
  tail call void bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to void (i8*, i8*, i8*)*)(i8* %6, i8* %5, i8* %4) optsize
  ret void
}

define internal void @__copy_helper_block_(i8*, i8* nocapture) nounwind {
  %3 = getelementptr inbounds i8* %1, i64 32
  %4 = bitcast i8* %3 to %3**
  %5 = getelementptr inbounds i8* %0, i64 32
  %6 = load %3** %4, align 8
  %7 = bitcast %3* %6 to i8*
  tail call void @_Block_object_assign(i8* %5, i8* %7, i32 3) nounwind
  ret void
}

declare void @_Block_object_assign(i8*, i8*, i32)

define internal void @__destroy_helper_block_(i8* nocapture) nounwind {
  %2 = getelementptr inbounds i8* %0, i64 32
  %3 = bitcast i8* %2 to %3**
  %4 = load %3** %3, align 8
  %5 = bitcast %3* %4 to i8*
  tail call void @_Block_object_dispose(i8* %5, i32 3) nounwind
  ret void
}

declare void @_Block_object_dispose(i8*, i32)

!llvm.module.flags = !{!0, !1, !2, !3}

!0 = metadata !{i32 1, metadata !"Objective-C Version", i32 2}
!1 = metadata !{i32 1, metadata !"Objective-C Image Info Version", i32 0}
!2 = metadata !{i32 1, metadata !"Objective-C Image Info Section", metadata !"__DATA, __objc_imageinfo, regular, no_dead_strip"}
!3 = metadata !{i32 4, metadata !"Objective-C Garbage Collection", i32 0}
!4 = metadata !{}
!5 = metadata !{metadata !"omnipotent char", metadata !6}
!6 = metadata !{metadata !"Simple C/C++ TBAA"}
