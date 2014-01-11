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
%struct.__block_literal_generic = type { i8*, i32, i32, i8*, %struct.__block_descriptor* }
%struct.__block_descriptor = type { i64, i64 }

@"OBJC_CLASS_$_NSMutableArray" = external global %struct._class_t
@"\01L_OBJC_CLASSLIST_REFERENCES_$_" = internal global %struct._class_t* @"OBJC_CLASS_$_NSMutableArray", section "__DATA, __objc_classrefs, regular, no_dead_strip", align 8
@"\01L_OBJC_METH_VAR_NAME_" = internal global [6 x i8] c"array\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_SELECTOR_REFERENCES_" = internal externally_initialized global i8* getelementptr inbounds ([6 x i8]* @"\01L_OBJC_METH_VAR_NAME_", i64 0, i64 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip"
@"\01L_OBJC_METH_VAR_NAME_1" = internal global [11 x i8] c"addObject:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_SELECTOR_REFERENCES_2" = internal externally_initialized global i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_NAME_1", i64 0, i64 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip"
@_NSConcreteStackBlock = external global i8*
@.str = private unnamed_addr constant [23 x i8] c"v24@?0@\22NSString\228^c16\00", align 1
@__block_descriptor_tmp = internal constant { i64, i64, i8*, i8*, i8*, i64 } { i64 0, i64 40, i8* bitcast (void (i8*, i8*)* @__copy_helper_block_ to i8*), i8* bitcast (void (i8*)* @__destroy_helper_block_ to i8*), i8* getelementptr inbounds ([23 x i8]* @.str, i32 0, i32 0), i64 256 }
@"\01L_OBJC_METH_VAR_NAME_3" = internal global [26 x i8] c"enumerateLinesUsingBlock:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_SELECTOR_REFERENCES_4" = internal externally_initialized global i8* getelementptr inbounds ([26 x i8]* @"\01L_OBJC_METH_VAR_NAME_3", i64 0, i64 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip"
@_objc_empty_cache = external global %struct._objc_cache
@_objc_empty_vtable = external global i8* (i8*, i8*)*
@"OBJC_METACLASS_$_NSObject" = external global %struct._class_t
@"\01L_OBJC_CLASS_NAME_" = internal global [3 x i8] c"Hi\00", section "__TEXT,__objc_classname,cstring_literals", align 1
@"\01l_OBJC_METACLASS_RO_$_Hi" = internal global %struct._class_ro_t { i32 1, i32 40, i32 40, i8* null, i8* getelementptr inbounds ([3 x i8]* @"\01L_OBJC_CLASS_NAME_", i32 0, i32 0), %struct.__method_list_t* null, %struct._objc_protocol_list* null, %struct._ivar_list_t* null, i8* null, %struct._prop_list_t* null }, section "__DATA, __objc_const", align 8
@"OBJC_METACLASS_$_Hi" = global %struct._class_t { %struct._class_t* @"OBJC_METACLASS_$_NSObject", %struct._class_t* @"OBJC_METACLASS_$_NSObject", %struct._objc_cache* @_objc_empty_cache, i8* (i8*, i8*)** @_objc_empty_vtable, %struct._class_ro_t* @"\01l_OBJC_METACLASS_RO_$_Hi" }, section "__DATA, __objc_data", align 8
@"OBJC_CLASS_$_NSObject" = external global %struct._class_t
@"\01L_OBJC_METH_VAR_NAME_5" = internal global [16 x i8] c"onLine:execute:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_TYPE_" = internal global [15 x i8] c"@32@0:8@16@?24\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_NAME_6" = internal global [7 x i8] c"lines:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_TYPE_7" = internal global [11 x i8] c"@24@0:8@16\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01l_OBJC_$_INSTANCE_METHODS_Hi" = internal global { i32, i32, [2 x %struct._objc_method] } { i32 24, i32 2, [2 x %struct._objc_method] [%struct._objc_method { i8* getelementptr inbounds ([16 x i8]* @"\01L_OBJC_METH_VAR_NAME_5", i32 0, i32 0), i8* getelementptr inbounds ([15 x i8]* @"\01L_OBJC_METH_VAR_TYPE_", i32 0, i32 0), i8* bitcast (%0* (%1*, i8*, %0*, %0* (%0*)*)* @"\01-[Hi onLine:execute:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([7 x i8]* @"\01L_OBJC_METH_VAR_NAME_6", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_7", i32 0, i32 0), i8* bitcast (%2* (%1*, i8*, %0*)* @"\01-[Hi lines:]" to i8*) }] }, section "__DATA, __objc_const", align 8
@"\01l_OBJC_CLASS_RO_$_Hi" = internal global %struct._class_ro_t { i32 0, i32 8, i32 8, i8* null, i8* getelementptr inbounds ([3 x i8]* @"\01L_OBJC_CLASS_NAME_", i32 0, i32 0), %struct.__method_list_t* bitcast ({ i32, i32, [2 x %struct._objc_method] }* @"\01l_OBJC_$_INSTANCE_METHODS_Hi" to %struct.__method_list_t*), %struct._objc_protocol_list* null, %struct._ivar_list_t* null, i8* null, %struct._prop_list_t* null }, section "__DATA, __objc_const", align 8
@"OBJC_CLASS_$_Hi" = global %struct._class_t { %struct._class_t* @"OBJC_METACLASS_$_Hi", %struct._class_t* @"OBJC_CLASS_$_NSObject", %struct._objc_cache* @_objc_empty_cache, i8* (i8*, i8*)** @_objc_empty_vtable, %struct._class_ro_t* @"\01l_OBJC_CLASS_RO_$_Hi" }, section "__DATA, __objc_data", align 8
@"\01L_OBJC_LABEL_CLASS_$" = internal global [1 x i8*] [i8* bitcast (%struct._class_t* @"OBJC_CLASS_$_Hi" to i8*)], section "__DATA, __objc_classlist, regular, no_dead_strip", align 8
@llvm.used = appending global [14 x i8*] [i8* bitcast (%struct._class_t** @"\01L_OBJC_CLASSLIST_REFERENCES_$_" to i8*), i8* getelementptr inbounds ([6 x i8]* @"\01L_OBJC_METH_VAR_NAME_", i32 0, i32 0), i8* bitcast (i8** @"\01L_OBJC_SELECTOR_REFERENCES_" to i8*), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_NAME_1", i32 0, i32 0), i8* bitcast (i8** @"\01L_OBJC_SELECTOR_REFERENCES_2" to i8*), i8* getelementptr inbounds ([26 x i8]* @"\01L_OBJC_METH_VAR_NAME_3", i32 0, i32 0), i8* bitcast (i8** @"\01L_OBJC_SELECTOR_REFERENCES_4" to i8*), i8* getelementptr inbounds ([3 x i8]* @"\01L_OBJC_CLASS_NAME_", i32 0, i32 0), i8* getelementptr inbounds ([16 x i8]* @"\01L_OBJC_METH_VAR_NAME_5", i32 0, i32 0), i8* getelementptr inbounds ([15 x i8]* @"\01L_OBJC_METH_VAR_TYPE_", i32 0, i32 0), i8* getelementptr inbounds ([7 x i8]* @"\01L_OBJC_METH_VAR_NAME_6", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_7", i32 0, i32 0), i8* bitcast ({ i32, i32, [2 x %struct._objc_method] }* @"\01l_OBJC_$_INSTANCE_METHODS_Hi" to i8*), i8* bitcast ([1 x i8*]* @"\01L_OBJC_LABEL_CLASS_$" to i8*)], section "llvm.metadata"

define internal %0* @"\01-[Hi onLine:execute:]"(%1* nocapture %self, i8* nocapture %_cmd, %0* %line, %0* (%0*)* %block) optsize ssp uwtable {
  tail call void @llvm.dbg.value(metadata !{%1* %self}, i64 0, metadata !48), !dbg !112
  tail call void @llvm.dbg.value(metadata !{i8* %_cmd}, i64 0, metadata !50), !dbg !112
  tail call void @llvm.dbg.value(metadata !{%0* %line}, i64 0, metadata !52), !dbg !112
  tail call void @llvm.dbg.value(metadata !{%0* (%0*)* %block}, i64 0, metadata !53), !dbg !112
  %1 = bitcast %0* (%0*)* %block to %struct.__block_literal_generic*, !dbg !113
  %2 = getelementptr inbounds %struct.__block_literal_generic* %1, i64 0, i32 3, !dbg !113
  %3 = bitcast %0* (%0*)* %block to i8*, !dbg !113
  %4 = load i8** %2, align 8, !dbg !113
  %5 = bitcast i8* %4 to %0* (i8*, %0*)*, !dbg !113
  %6 = tail call %0* %5(i8* %3, %0* %line) optsize, !dbg !113
  ret %0* %6, !dbg !113
}

declare void @llvm.dbg.declare(metadata, metadata) nounwind readnone

define internal %2* @"\01-[Hi lines:]"(%1* nocapture %self, i8* nocapture %_cmd, %0* %s) optsize ssp uwtable {
  %1 = alloca <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>, align 8
  call void @llvm.dbg.value(metadata !{%1* %self}, i64 0, metadata !64), !dbg !115
  call void @llvm.dbg.value(metadata !{i8* %_cmd}, i64 0, metadata !65), !dbg !115
  call void @llvm.dbg.value(metadata !{%0* %s}, i64 0, metadata !66), !dbg !115
  %2 = load %struct._class_t** @"\01L_OBJC_CLASSLIST_REFERENCES_$_", align 8, !dbg !116
  %3 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_", align 8, !dbg !116, !invariant.load !117
  %4 = bitcast %struct._class_t* %2 to i8*, !dbg !116
  %5 = call i8* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to i8* (i8*, i8*)*)(i8* %4, i8* %3) optsize, !dbg !116
  %6 = bitcast i8* %5 to %3*, !dbg !116
  call void @llvm.dbg.value(metadata !{%3* %6}, i64 0, metadata !67), !dbg !116
  %7 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %1, i64 0, i32 0, !dbg !118
  store i8* bitcast (i8** @_NSConcreteStackBlock to i8*), i8** %7, align 8, !dbg !118
  %8 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %1, i64 0, i32 1, !dbg !118
  store i32 -1040187392, i32* %8, align 8, !dbg !118
  %9 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %1, i64 0, i32 2, !dbg !118
  store i32 0, i32* %9, align 4, !dbg !118
  %10 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %1, i64 0, i32 3, !dbg !118
  store i8* bitcast (void (i8*, %0*, i8*)* @"__12-[Hi lines:]_block_invoke" to i8*), i8** %10, align 8, !dbg !118
  %11 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %1, i64 0, i32 4, !dbg !118
  store %struct.__block_descriptor* bitcast ({ i64, i64, i8*, i8*, i8*, i64 }* @__block_descriptor_tmp to %struct.__block_descriptor*), %struct.__block_descriptor** %11, align 8, !dbg !118
  %12 = getelementptr inbounds <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %1, i64 0, i32 5, !dbg !118
  store %3* %6, %3** %12, align 8, !dbg !118, !tbaa !119
  %13 = bitcast <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, %3* }>* %1 to void (%0*, i8*)*, !dbg !118
  %14 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_4", align 8, !dbg !118, !invariant.load !117
  %15 = bitcast %0* %s to i8*, !dbg !118
  call void bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to void (i8*, i8*, void (%0*, i8*)*)*)(i8* %15, i8* %14, void (%0*, i8*)* %13) optsize, !dbg !118
  %16 = bitcast i8* %5 to %2*, !dbg !121
  ret %2* %16, !dbg !121
}

declare i8* @objc_msgSend(i8*, i8*, ...) nonlazybind

define internal void @"__12-[Hi lines:]_block_invoke"(i8* nocapture %.block_descriptor, %0* %line, i8* nocapture %stop) optsize ssp uwtable {
  tail call void @llvm.dbg.declare(metadata !{i8* %.block_descriptor}, metadata !81), !dbg !122
  tail call void @llvm.dbg.value(metadata !{%0* %line}, i64 0, metadata !93), !dbg !122
  tail call void @llvm.dbg.value(metadata !{i8* %stop}, i64 0, metadata !94), !dbg !122
  %1 = getelementptr inbounds i8* %.block_descriptor, i64 32, !dbg !123
  %2 = bitcast i8* %1 to %3**, !dbg !123
  %3 = load %3** %2, align 8, !dbg !123, !tbaa !119
  %4 = bitcast %0* %line to i8*, !dbg !123
  %5 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_2", align 8, !dbg !123, !invariant.load !117
  %6 = bitcast %3* %3 to i8*, !dbg !123
  tail call void bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to void (i8*, i8*, i8*)*)(i8* %6, i8* %5, i8* %4) optsize, !dbg !123
  ret void, !dbg !125
}

define internal void @__copy_helper_block_(i8*, i8* nocapture) nounwind {
  tail call void @llvm.dbg.value(metadata !{i8* %0}, i64 0, metadata !100), !dbg !126
  tail call void @llvm.dbg.value(metadata !{i8* %1}, i64 0, metadata !101), !dbg !126
  %3 = getelementptr inbounds i8* %1, i64 32, !dbg !126
  %4 = bitcast i8* %3 to %3**, !dbg !126
  %5 = getelementptr inbounds i8* %0, i64 32, !dbg !126
  %6 = load %3** %4, align 8, !dbg !126
  %7 = bitcast %3* %6 to i8*, !dbg !126
  tail call void @_Block_object_assign(i8* %5, i8* %7, i32 3) nounwind, !dbg !126
  ret void, !dbg !126
}

declare void @_Block_object_assign(i8*, i8*, i32)

define internal void @__destroy_helper_block_(i8* nocapture) nounwind {
  tail call void @llvm.dbg.value(metadata !{i8* %0}, i64 0, metadata !107), !dbg !127
  %2 = getelementptr inbounds i8* %0, i64 32, !dbg !127
  %3 = bitcast i8* %2 to %3**, !dbg !127
  %4 = load %3** %3, align 8, !dbg !127
  %5 = bitcast %3* %4 to i8*, !dbg !127
  tail call void @_Block_object_dispose(i8* %5, i32 3) nounwind, !dbg !127
  ret void, !dbg !127
}

declare void @_Block_object_dispose(i8*, i32)

declare void @llvm.dbg.value(metadata, i64, metadata) nounwind readnone

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!108, !109, !110, !111}

!0 = metadata !{i32 786449, i32 0, i32 16, metadata !"class-with-method-block.m", metadata !"/Users/marcel/programming/Kits/ObjectiveSmalltalk/ObjSTNative/test-compiles", metadata !"Apple LLVM version 5.0 (clang-500.2.79) (based on LLVM 3.3svn)", i1 true, i1 true, metadata !"", i32 2, metadata !1, metadata !3, metadata !16, metadata !1} ; [ DW_TAG_compile_unit ] [/Users/marcel/programming/Kits/ObjectiveSmalltalk/ObjSTNative/test-compiles/class-with-method-block.m] [DW_LANG_ObjC]
!1 = metadata !{metadata !2}
!2 = metadata !{i32 0}
!3 = metadata !{metadata !4}
!4 = metadata !{metadata !5}
!5 = metadata !{i32 786451, metadata !6, metadata !"Hi", metadata !6, i32 3, i64 64, i64 64, i32 0, i32 512, null, metadata !7, i32 16, i32 0, i32 0} ; [ DW_TAG_structure_type ] [Hi] [line 3, size 64, align 64, offset 0] [from ]
!6 = metadata !{i32 786473, metadata !"class-with-method-block.m", metadata !"/Users/marcel/programming/Kits/ObjectiveSmalltalk/ObjSTNative/test-compiles", null} ; [ DW_TAG_file_type ]
!7 = metadata !{metadata !8}
!8 = metadata !{i32 786460, metadata !5, null, metadata !6, i32 0, i64 0, i64 0, i64 0, i32 0, metadata !9} ; [ DW_TAG_inheritance ] [line 0, size 0, align 0, offset 0] [from NSObject]
!9 = metadata !{i32 786451, metadata !6, metadata !"NSObject", metadata !10, i32 50, i64 64, i64 64, i32 0, i32 0, null, metadata !11, i32 16, i32 0, i32 0} ; [ DW_TAG_structure_type ] [NSObject] [line 50, size 64, align 64, offset 0] [from ]
!10 = metadata !{i32 786473, metadata !"/usr/include/objc/NSObject.h", metadata !"/Users/marcel/programming/Kits/ObjectiveSmalltalk/ObjSTNative/test-compiles", null} ; [ DW_TAG_file_type ]
!11 = metadata !{metadata !12}
!12 = metadata !{i32 786445, metadata !10, metadata !"isa", metadata !10, i32 51, i64 64, i64 64, i64 0, i32 2, metadata !13, null} ; [ DW_TAG_member ] [isa] [line 51, size 64, align 64, offset 0] [protected] [from Class]
!13 = metadata !{i32 786454, null, metadata !"Class", metadata !6, i32 10, i64 0, i64 0, i64 0, i32 0, metadata !14} ; [ DW_TAG_typedef ] [Class] [line 10, size 0, align 0, offset 0] [from ]
!14 = metadata !{i32 786447, null, metadata !"", null, i32 0, i64 64, i64 64, i64 0, i32 0, metadata !15} ; [ DW_TAG_pointer_type ] [line 0, size 64, align 64, offset 0] [from objc_class]
!15 = metadata !{i32 786451, null, metadata !"objc_class", metadata !6, i32 0, i64 0, i64 0, i32 0, i32 4, null, null, i32 0} ; [ DW_TAG_structure_type ] [objc_class] [line 0, size 0, align 0, offset 0] [fwd] [from ]
!16 = metadata !{metadata !17}
!17 = metadata !{metadata !18, metadata !54, metadata !73, metadata !95, metadata !102}
!18 = metadata !{i32 786478, i32 0, metadata !6, metadata !"-[Hi onLine:execute:]", metadata !"-[Hi onLine:execute:]", metadata !"", metadata !6, i32 10, metadata !19, i1 true, i1 true, i32 0, i32 0, null, i32 256, i1 true, %0* (%1*, i8*, %0*, %0* (%0*)*)* @"\01-[Hi onLine:execute:]", null, null, metadata !46, i32 10} ; [ DW_TAG_subprogram ] [line 10] [local] [def] [-[Hi onLine:execute:]]
!19 = metadata !{i32 786453, i32 0, metadata !"", i32 0, i32 0, i64 0, i64 0, i64 0, i32 0, null, metadata !20, i32 0, i32 0} ; [ DW_TAG_subroutine_type ] [line 0, size 0, align 0, offset 0] [from ]
!20 = metadata !{metadata !21, metadata !26, metadata !27, metadata !21, metadata !30}
!21 = metadata !{i32 786447, null, metadata !"", null, i32 0, i64 64, i64 64, i64 0, i32 0, metadata !22} ; [ DW_TAG_pointer_type ] [line 0, size 64, align 64, offset 0] [from NSString]
!22 = metadata !{i32 786451, metadata !6, metadata !"NSString", metadata !23, i32 74, i64 64, i64 64, i32 0, i32 0, null, metadata !24, i32 16, i32 0, i32 0} ; [ DW_TAG_structure_type ] [NSString] [line 74, size 64, align 64, offset 0] [from ]
!23 = metadata !{i32 786473, metadata !"/System/Library/Frameworks/Foundation.framework/Headers/NSString.h", metadata !"/Users/marcel/programming/Kits/ObjectiveSmalltalk/ObjSTNative/test-compiles", null} ; [ DW_TAG_file_type ]
!24 = metadata !{metadata !25}
!25 = metadata !{i32 786460, metadata !22, null, metadata !23, i32 0, i64 0, i64 0, i64 0, i32 0, metadata !9} ; [ DW_TAG_inheritance ] [line 0, size 0, align 0, offset 0] [from NSObject]
!26 = metadata !{i32 786447, i32 0, metadata !"", i32 0, i32 0, i64 64, i64 64, i64 0, i32 1088, metadata !5} ; [ DW_TAG_pointer_type ] [line 0, size 64, align 64, offset 0] [artificial] [from Hi]
!27 = metadata !{i32 786454, i32 0, metadata !"SEL", metadata !6, i32 10, i64 0, i64 0, i64 0, i32 64, metadata !28} ; [ DW_TAG_typedef ] [SEL] [line 10, size 0, align 0, offset 0] [artificial] [from ]
!28 = metadata !{i32 786447, null, metadata !"", null, i32 0, i64 64, i64 64, i64 0, i32 0, metadata !29} ; [ DW_TAG_pointer_type ] [line 0, size 64, align 64, offset 0] [from objc_selector]
!29 = metadata !{i32 786451, null, metadata !"objc_selector", metadata !6, i32 0, i64 0, i64 0, i32 0, i32 4, null, null, i32 0} ; [ DW_TAG_structure_type ] [objc_selector] [line 0, size 0, align 0, offset 0] [fwd] [from ]
!30 = metadata !{i32 786447, null, metadata !"", null, i32 0, i64 64, i64 0, i64 0, i32 0, metadata !31} ; [ DW_TAG_pointer_type ] [line 0, size 64, align 0, offset 0] [from __block_literal_generic]
!31 = metadata !{i32 786451, metadata !6, metadata !"__block_literal_generic", metadata !6, i32 10, i64 256, i64 0, i32 0, i32 8, null, metadata !32, i32 0, i32 0, i32 0} ; [ DW_TAG_structure_type ] [__block_literal_generic] [line 10, size 256, align 0, offset 0] [from ]
!32 = metadata !{metadata !33, metadata !35, metadata !37, metadata !38, metadata !39}
!33 = metadata !{i32 786445, metadata !6, metadata !"__isa", metadata !6, i32 0, i64 64, i64 64, i64 0, i32 0, metadata !34} ; [ DW_TAG_member ] [__isa] [line 0, size 64, align 64, offset 0] [from ]
!34 = metadata !{i32 786447, null, metadata !"", null, i32 0, i64 64, i64 64, i64 0, i32 0, null} ; [ DW_TAG_pointer_type ] [line 0, size 64, align 64, offset 0] [from ]
!35 = metadata !{i32 786445, metadata !6, metadata !"__flags", metadata !6, i32 0, i64 32, i64 32, i64 64, i32 0, metadata !36} ; [ DW_TAG_member ] [__flags] [line 0, size 32, align 32, offset 64] [from int]
!36 = metadata !{i32 786468, null, metadata !"int", null, i32 0, i64 32, i64 32, i64 0, i32 0, i32 5} ; [ DW_TAG_base_type ] [int] [line 0, size 32, align 32, offset 0, enc DW_ATE_signed]
!37 = metadata !{i32 786445, metadata !6, metadata !"__reserved", metadata !6, i32 0, i64 32, i64 32, i64 96, i32 0, metadata !36} ; [ DW_TAG_member ] [__reserved] [line 0, size 32, align 32, offset 96] [from int]
!38 = metadata !{i32 786445, metadata !6, metadata !"__FuncPtr", metadata !6, i32 0, i64 64, i64 64, i64 128, i32 0, metadata !34} ; [ DW_TAG_member ] [__FuncPtr] [line 0, size 64, align 64, offset 128] [from ]
!39 = metadata !{i32 786445, metadata !6, metadata !"__descriptor", metadata !6, i32 10, i64 64, i64 64, i64 192, i32 0, metadata !40} ; [ DW_TAG_member ] [__descriptor] [line 10, size 64, align 64, offset 192] [from ]
!40 = metadata !{i32 786447, null, metadata !"", null, i32 0, i64 64, i64 0, i64 0, i32 0, metadata !41} ; [ DW_TAG_pointer_type ] [line 0, size 64, align 0, offset 0] [from __block_descriptor]
!41 = metadata !{i32 786451, metadata !6, metadata !"__block_descriptor", metadata !6, i32 10, i64 128, i64 0, i32 0, i32 8, null, metadata !42, i32 0, i32 0, i32 0} ; [ DW_TAG_structure_type ] [__block_descriptor] [line 10, size 128, align 0, offset 0] [from ]
!42 = metadata !{metadata !43, metadata !45}
!43 = metadata !{i32 786445, metadata !6, metadata !"reserved", metadata !6, i32 0, i64 64, i64 64, i64 0, i32 0, metadata !44} ; [ DW_TAG_member ] [reserved] [line 0, size 64, align 64, offset 0] [from long unsigned int]
!44 = metadata !{i32 786468, null, metadata !"long unsigned int", null, i32 0, i64 64, i64 64, i64 0, i32 0, i32 7} ; [ DW_TAG_base_type ] [long unsigned int] [line 0, size 64, align 64, offset 0, enc DW_ATE_unsigned]
!45 = metadata !{i32 786445, metadata !6, metadata !"Size", metadata !6, i32 0, i64 64, i64 64, i64 64, i32 0, metadata !44} ; [ DW_TAG_member ] [Size] [line 0, size 64, align 64, offset 64] [from long unsigned int]
!46 = metadata !{metadata !47}
!47 = metadata !{metadata !48, metadata !50, metadata !52, metadata !53}
!48 = metadata !{i32 786689, metadata !18, metadata !"self", metadata !6, i32 16777226, metadata !49, i32 1088, i32 0} ; [ DW_TAG_arg_variable ] [self] [line 10]
!49 = metadata !{i32 786447, null, metadata !"", null, i32 0, i64 64, i64 64, i64 0, i32 0, metadata !5} ; [ DW_TAG_pointer_type ] [line 0, size 64, align 64, offset 0] [from Hi]
!50 = metadata !{i32 786689, metadata !18, metadata !"_cmd", metadata !6, i32 33554442, metadata !51, i32 64, i32 0} ; [ DW_TAG_arg_variable ] [_cmd] [line 10]
!51 = metadata !{i32 786454, null, metadata !"SEL", metadata !6, i32 10, i64 0, i64 0, i64 0, i32 0, metadata !28} ; [ DW_TAG_typedef ] [SEL] [line 10, size 0, align 0, offset 0] [from ]
!52 = metadata !{i32 786689, metadata !18, metadata !"line", metadata !6, i32 50331658, metadata !21, i32 0, i32 0} ; [ DW_TAG_arg_variable ] [line] [line 10]
!53 = metadata !{i32 786689, metadata !18, metadata !"block", metadata !6, i32 67108874, metadata !30, i32 0, i32 0} ; [ DW_TAG_arg_variable ] [block] [line 10]
!54 = metadata !{i32 786478, i32 0, metadata !6, metadata !"-[Hi lines:]", metadata !"-[Hi lines:]", metadata !"", metadata !6, i32 16, metadata !55, i1 true, i1 true, i32 0, i32 0, null, i32 256, i1 true, %2* (%1*, i8*, %0*)* @"\01-[Hi lines:]", null, null, metadata !62, i32 16} ; [ DW_TAG_subprogram ] [line 16] [local] [def] [-[Hi lines:]]
!55 = metadata !{i32 786453, i32 0, metadata !"", i32 0, i32 0, i64 0, i64 0, i64 0, i32 0, null, metadata !56, i32 0, i32 0} ; [ DW_TAG_subroutine_type ] [line 0, size 0, align 0, offset 0] [from ]
!56 = metadata !{metadata !57, metadata !26, metadata !27, metadata !21}
!57 = metadata !{i32 786447, null, metadata !"", null, i32 0, i64 64, i64 64, i64 0, i32 0, metadata !58} ; [ DW_TAG_pointer_type ] [line 0, size 64, align 64, offset 0] [from NSArray]
!58 = metadata !{i32 786451, metadata !6, metadata !"NSArray", metadata !59, i32 14, i64 64, i64 64, i32 0, i32 0, null, metadata !60, i32 16, i32 0, i32 0} ; [ DW_TAG_structure_type ] [NSArray] [line 14, size 64, align 64, offset 0] [from ]
!59 = metadata !{i32 786473, metadata !"/System/Library/Frameworks/Foundation.framework/Headers/NSArray.h", metadata !"/Users/marcel/programming/Kits/ObjectiveSmalltalk/ObjSTNative/test-compiles", null} ; [ DW_TAG_file_type ]
!60 = metadata !{metadata !61}
!61 = metadata !{i32 786460, metadata !58, null, metadata !59, i32 0, i64 0, i64 0, i64 0, i32 0, metadata !9} ; [ DW_TAG_inheritance ] [line 0, size 0, align 0, offset 0] [from NSObject]
!62 = metadata !{metadata !63}
!63 = metadata !{metadata !64, metadata !65, metadata !66, metadata !67}
!64 = metadata !{i32 786689, metadata !54, metadata !"self", metadata !6, i32 16777232, metadata !49, i32 1088, i32 0} ; [ DW_TAG_arg_variable ] [self] [line 16]
!65 = metadata !{i32 786689, metadata !54, metadata !"_cmd", metadata !6, i32 33554448, metadata !51, i32 64, i32 0} ; [ DW_TAG_arg_variable ] [_cmd] [line 16]
!66 = metadata !{i32 786689, metadata !54, metadata !"s", metadata !6, i32 50331664, metadata !21, i32 0, i32 0} ; [ DW_TAG_arg_variable ] [s] [line 16]
!67 = metadata !{i32 786688, metadata !68, metadata !"lines", metadata !6, i32 18, metadata !69, i32 0, i32 0} ; [ DW_TAG_auto_variable ] [lines] [line 18]
!68 = metadata !{i32 786443, metadata !54, i32 17, i32 0, metadata !6, i32 1} ; [ DW_TAG_lexical_block ] [/Users/marcel/programming/Kits/ObjectiveSmalltalk/ObjSTNative/test-compiles/class-with-method-block.m]
!69 = metadata !{i32 786447, null, metadata !"", null, i32 0, i64 64, i64 64, i64 0, i32 0, metadata !70} ; [ DW_TAG_pointer_type ] [line 0, size 64, align 64, offset 0] [from NSMutableArray]
!70 = metadata !{i32 786451, metadata !6, metadata !"NSMutableArray", metadata !59, i32 116, i64 64, i64 64, i32 0, i32 0, null, metadata !71, i32 16, i32 0, i32 0} ; [ DW_TAG_structure_type ] [NSMutableArray] [line 116, size 64, align 64, offset 0] [from ]
!71 = metadata !{metadata !72}
!72 = metadata !{i32 786460, metadata !70, null, metadata !59, i32 0, i64 0, i64 0, i64 0, i32 0, metadata !58} ; [ DW_TAG_inheritance ] [line 0, size 0, align 0, offset 0] [from NSArray]
!73 = metadata !{i32 786478, i32 0, metadata !6, metadata !"__12-[Hi lines:]_block_invoke", metadata !"__12-[Hi lines:]_block_invoke", metadata !"", metadata !6, i32 19, metadata !74, i1 true, i1 true, i32 0, i32 0, null, i32 256, i1 true, void (i8*, %0*, i8*)* @"__12-[Hi lines:]_block_invoke", null, null, metadata !79, i32 19} ; [ DW_TAG_subprogram ] [line 19] [local] [def] [__12-[Hi lines:]_block_invoke]
!74 = metadata !{i32 786453, i32 0, metadata !"", i32 0, i32 0, i64 0, i64 0, i64 0, i32 0, null, metadata !75, i32 0, i32 0} ; [ DW_TAG_subroutine_type ] [line 0, size 0, align 0, offset 0] [from ]
!75 = metadata !{null, metadata !34, metadata !21, metadata !76}
!76 = metadata !{i32 786447, null, metadata !"", null, i32 0, i64 64, i64 64, i64 0, i32 0, metadata !77} ; [ DW_TAG_pointer_type ] [line 0, size 64, align 64, offset 0] [from BOOL]
!77 = metadata !{i32 786454, null, metadata !"BOOL", metadata !6, i32 61, i64 0, i64 0, i64 0, i32 0, metadata !78} ; [ DW_TAG_typedef ] [BOOL] [line 61, size 0, align 0, offset 0] [from signed char]
!78 = metadata !{i32 786468, null, metadata !"signed char", null, i32 0, i64 8, i64 8, i64 0, i32 0, i32 6} ; [ DW_TAG_base_type ] [signed char] [line 0, size 8, align 8, offset 0, enc DW_ATE_signed_char]
!79 = metadata !{metadata !80}
!80 = metadata !{metadata !81, metadata !93, metadata !94}
!81 = metadata !{i32 786689, metadata !73, metadata !".block_descriptor", metadata !6, i32 16777235, metadata !82, i32 64, i32 0} ; [ DW_TAG_arg_variable ] [.block_descriptor] [line 19]
!82 = metadata !{i32 786447, null, metadata !"", null, i32 0, i64 64, i64 0, i64 0, i32 0, metadata !83} ; [ DW_TAG_pointer_type ] [line 0, size 64, align 0, offset 0] [from __block_literal_1]
!83 = metadata !{i32 786451, metadata !6, metadata !"__block_literal_1", metadata !6, i32 19, i64 320, i64 64, i32 0, i32 0, null, metadata !84, i32 0, i32 0, i32 0} ; [ DW_TAG_structure_type ] [__block_literal_1] [line 19, size 320, align 64, offset 0] [from ]
!84 = metadata !{metadata !85, metadata !86, metadata !87, metadata !88, metadata !89, metadata !92}
!85 = metadata !{i32 786445, metadata !6, metadata !"__isa", metadata !6, i32 19, i64 64, i64 64, i64 0, i32 0, metadata !34} ; [ DW_TAG_member ] [__isa] [line 19, size 64, align 64, offset 0] [from ]
!86 = metadata !{i32 786445, metadata !6, metadata !"__flags", metadata !6, i32 19, i64 32, i64 32, i64 64, i32 0, metadata !36} ; [ DW_TAG_member ] [__flags] [line 19, size 32, align 32, offset 64] [from int]
!87 = metadata !{i32 786445, metadata !6, metadata !"__reserved", metadata !6, i32 19, i64 32, i64 32, i64 96, i32 0, metadata !36} ; [ DW_TAG_member ] [__reserved] [line 19, size 32, align 32, offset 96] [from int]
!88 = metadata !{i32 786445, metadata !6, metadata !"__FuncPtr", metadata !6, i32 19, i64 64, i64 64, i64 128, i32 0, metadata !34} ; [ DW_TAG_member ] [__FuncPtr] [line 19, size 64, align 64, offset 128] [from ]
!89 = metadata !{i32 786445, metadata !6, metadata !"__descriptor", metadata !6, i32 19, i64 64, i64 64, i64 192, i32 0, metadata !90} ; [ DW_TAG_member ] [__descriptor] [line 19, size 64, align 64, offset 192] [from ]
!90 = metadata !{i32 786447, null, metadata !"", null, i32 0, i64 64, i64 64, i64 0, i32 0, metadata !91} ; [ DW_TAG_pointer_type ] [line 0, size 64, align 64, offset 0] [from __block_descriptor_withcopydispose]
!91 = metadata !{i32 786451, null, metadata !"__block_descriptor_withcopydispose", metadata !6, i32 19, i64 0, i64 0, i32 0, i32 4, null, null, i32 0} ; [ DW_TAG_structure_type ] [__block_descriptor_withcopydispose] [line 19, size 0, align 0, offset 0] [fwd] [from ]
!92 = metadata !{i32 786445, metadata !6, metadata !"lines", metadata !6, i32 19, i64 64, i64 64, i64 256, i32 0, metadata !69} ; [ DW_TAG_member ] [lines] [line 19, size 64, align 64, offset 256] [from ]
!93 = metadata !{i32 786689, metadata !73, metadata !"line", metadata !6, i32 33554451, metadata !21, i32 0, i32 0} ; [ DW_TAG_arg_variable ] [line] [line 19]
!94 = metadata !{i32 786689, metadata !73, metadata !"stop", metadata !6, i32 50331667, metadata !76, i32 0, i32 0} ; [ DW_TAG_arg_variable ] [stop] [line 19]
!95 = metadata !{i32 786478, i32 0, metadata !6, metadata !"__copy_helper_block_", metadata !"__copy_helper_block_", metadata !"", metadata !6, i32 21, metadata !96, i1 true, i1 true, i32 0, i32 0, null, i32 0, i1 true, void (i8*, i8*)* @__copy_helper_block_, null, null, metadata !98, i32 21} ; [ DW_TAG_subprogram ] [line 21] [local] [def] [__copy_helper_block_]
!96 = metadata !{i32 786453, i32 0, metadata !"", i32 0, i32 0, i64 0, i64 0, i64 0, i32 0, null, metadata !97, i32 0, i32 0} ; [ DW_TAG_subroutine_type ] [line 0, size 0, align 0, offset 0] [from ]
!97 = metadata !{null, metadata !34, metadata !34}
!98 = metadata !{metadata !99}
!99 = metadata !{metadata !100, metadata !101}
!100 = metadata !{i32 786689, metadata !95, metadata !"", metadata !6, i32 16777237, metadata !34, i32 1088, i32 0} ; [ DW_TAG_arg_variable ] [line 21]
!101 = metadata !{i32 786689, metadata !95, metadata !"", metadata !6, i32 33554453, metadata !34, i32 64, i32 0} ; [ DW_TAG_arg_variable ] [line 21]
!102 = metadata !{i32 786478, i32 0, metadata !6, metadata !"__destroy_helper_block_", metadata !"__destroy_helper_block_", metadata !"", metadata !6, i32 21, metadata !103, i1 true, i1 true, i32 0, i32 0, null, i32 0, i1 true, void (i8*)* @__destroy_helper_block_, null, null, metadata !105, i32 21} ; [ DW_TAG_subprogram ] [line 21] [local] [def] [__destroy_helper_block_]
!103 = metadata !{i32 786453, i32 0, metadata !"", i32 0, i32 0, i64 0, i64 0, i64 0, i32 0, null, metadata !104, i32 0, i32 0} ; [ DW_TAG_subroutine_type ] [line 0, size 0, align 0, offset 0] [from ]
!104 = metadata !{null, metadata !34}
!105 = metadata !{metadata !106}
!106 = metadata !{metadata !107}
!107 = metadata !{i32 786689, metadata !102, metadata !"", metadata !6, i32 16777237, metadata !34, i32 1088, i32 0} ; [ DW_TAG_arg_variable ] [line 21]
!108 = metadata !{i32 1, metadata !"Objective-C Version", i32 2}
!109 = metadata !{i32 1, metadata !"Objective-C Image Info Version", i32 0}
!110 = metadata !{i32 1, metadata !"Objective-C Image Info Section", metadata !"__DATA, __objc_imageinfo, regular, no_dead_strip"}
!111 = metadata !{i32 4, metadata !"Objective-C Garbage Collection", i32 0}
!112 = metadata !{i32 10, i32 0, metadata !18, null}
!113 = metadata !{i32 12, i32 0, metadata !114, null}
!114 = metadata !{i32 786443, metadata !18, i32 11, i32 0, metadata !6, i32 0} ; [ DW_TAG_lexical_block ] [/Users/marcel/programming/Kits/ObjectiveSmalltalk/ObjSTNative/test-compiles/class-with-method-block.m]
!115 = metadata !{i32 16, i32 0, metadata !54, null}
!116 = metadata !{i32 18, i32 0, metadata !68, null}
!117 = metadata !{}
!118 = metadata !{i32 19, i32 0, metadata !68, null}
!119 = metadata !{metadata !"omnipotent char", metadata !120}
!120 = metadata !{metadata !"Simple C/C++ TBAA"}
!121 = metadata !{i32 22, i32 0, metadata !68, null}
!122 = metadata !{i32 19, i32 0, metadata !73, null}
!123 = metadata !{i32 20, i32 0, metadata !124, null}
!124 = metadata !{i32 786443, metadata !73, i32 19, i32 0, metadata !6, i32 2} ; [ DW_TAG_lexical_block ] [/Users/marcel/programming/Kits/ObjectiveSmalltalk/ObjSTNative/test-compiles/class-with-method-block.m]
!125 = metadata !{i32 21, i32 0, metadata !73, null}
!126 = metadata !{i32 21, i32 0, metadata !95, null}
!127 = metadata !{i32 21, i32 0, metadata !102, null}
