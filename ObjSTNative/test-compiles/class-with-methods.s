; ModuleID = 'class-with-methods.m'
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.9.0"

%0 = type opaque
%1 = type opaque
%2 = type opaque
%struct.NSConstantString = type { i32*, i32, i8*, i64 }
%struct._objc_cache = type opaque
%struct._class_t = type { %struct._class_t*, %struct._class_t*, %struct._objc_cache*, i8* (i8*, i8*)**, %struct._class_ro_t* }
%struct._class_ro_t = type { i32, i32, i32, i8*, i8*, %struct.__method_list_t*, %struct._objc_protocol_list*, %struct._ivar_list_t*, i8*, %struct._prop_list_t* }
%struct.__method_list_t = type { i32, i32, [0 x %struct._objc_method] }
%struct._objc_method = type { i8*, i8*, i8* }
%struct._objc_protocol_list = type { i64, [0 x %struct._protocol_t*] }
%struct._protocol_t = type { i8*, i8*, %struct._objc_protocol_list*, %struct.__method_list_t*, %struct.__method_list_t*, %struct.__method_list_t*, %struct.__method_list_t*, %struct._prop_list_t*, i32, i32, i8** }
%struct._prop_list_t = type { i32, i32, [0 x %struct._prop_t] }
%struct._prop_t = type { i8*, i8* }
%struct._ivar_list_t = type { i32, i32, [0 x %struct._ivar_t] }
%struct._ivar_t = type { i64*, i8*, i8*, i32, i32 }

@"\01L_OBJC_METH_VAR_NAME_" = internal global [29 x i8] c"componentsSeparatedByString:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_SELECTOR_REFERENCES_" = internal externally_initialized global i8* getelementptr inbounds ([29 x i8]* @"\01L_OBJC_METH_VAR_NAME_", i32 0, i32 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip"
@__CFConstantStringClassReference = external global [0 x i32]
@.str = linker_private unnamed_addr constant [2 x i8] c"\0A\00", align 1
@_unnamed_cfstring_ = private constant %struct.NSConstantString { i32* getelementptr inbounds ([0 x i32]* @__CFConstantStringClassReference, i32 0, i32 0), i32 1992, i8* getelementptr inbounds ([2 x i8]* @.str, i32 0, i32 0), i64 1 }, section "__DATA,__cfstring"
@"\01L_OBJC_METH_VAR_NAME_1" = internal global [22 x i8] c"components:splitInto:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_SELECTOR_REFERENCES_2" = internal externally_initialized global i8* getelementptr inbounds ([22 x i8]* @"\01L_OBJC_METH_VAR_NAME_1", i32 0, i32 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip"
@"OBJC_IVAR_$_Hi.factor" = global i64 8, section "__DATA, __objc_ivar", align 8
@"\01L_OBJC_METH_VAR_NAME_3" = internal global [22 x i8] c"mulByAddition:factor:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_SELECTOR_REFERENCES_4" = internal externally_initialized global i8* getelementptr inbounds ([22 x i8]* @"\01L_OBJC_METH_VAR_NAME_3", i32 0, i32 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip"
@"OBJC_IVAR_$_Hi._someProperty" = hidden global i64 16, section "__DATA, __objc_ivar", align 8
@_objc_empty_cache = external global %struct._objc_cache
@_objc_empty_vtable = external global i8* (i8*, i8*)*
@"OBJC_METACLASS_$_NSObject" = external global %struct._class_t
@"\01L_OBJC_CLASS_NAME_" = internal global [3 x i8] c"Hi\00", section "__TEXT,__objc_classname,cstring_literals", align 1
@"\01l_OBJC_METACLASS_RO_$_Hi" = internal global %struct._class_ro_t { i32 1, i32 40, i32 40, i8* null, i8* getelementptr inbounds ([3 x i8]* @"\01L_OBJC_CLASS_NAME_", i32 0, i32 0), %struct.__method_list_t* null, %struct._objc_protocol_list* null, %struct._ivar_list_t* null, i8* null, %struct._prop_list_t* null }, section "__DATA, __objc_const", align 8
@"OBJC_METACLASS_$_Hi" = global %struct._class_t { %struct._class_t* @"OBJC_METACLASS_$_NSObject", %struct._class_t* @"OBJC_METACLASS_$_NSObject", %struct._objc_cache* @_objc_empty_cache, i8* (i8*, i8*)** @_objc_empty_vtable, %struct._class_ro_t* @"\01l_OBJC_METACLASS_RO_$_Hi" }, section "__DATA, __objc_data", align 8
@"OBJC_CLASS_$_NSObject" = external global %struct._class_t
@"\01L_OBJC_METH_VAR_TYPE_" = internal global [14 x i8] c"@32@0:8@16@24\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_NAME_5" = internal global [7 x i8] c"lines:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_TYPE_6" = internal global [11 x i8] c"@24@0:8@16\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_NAME_7" = internal global [8 x i8] c"double:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_TYPE_8" = internal global [11 x i8] c"i20@0:8i16\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_TYPE_9" = internal global [14 x i8] c"i24@0:8i16i20\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_NAME_10" = internal global [15 x i8] c"mulByAddition:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_NAME_11" = internal global [7 x i8] c"factor\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_TYPE_12" = internal global [8 x i8] c"i16@0:8\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_NAME_13" = internal global [11 x i8] c"setFactor:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_TYPE_14" = internal global [11 x i8] c"v20@0:8i16\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_NAME_15" = internal global [13 x i8] c"someProperty\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_TYPE_16" = internal global [8 x i8] c"@16@0:8\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_NAME_17" = internal global [17 x i8] c"setSomeProperty:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_TYPE_18" = internal global [11 x i8] c"v24@0:8@16\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01l_OBJC_$_INSTANCE_METHODS_Hi" = internal global { i32, i32, [9 x %struct._objc_method] } { i32 24, i32 9, [9 x %struct._objc_method] [%struct._objc_method { i8* getelementptr inbounds ([22 x i8]* @"\01L_OBJC_METH_VAR_NAME_1", i32 0, i32 0), i8* getelementptr inbounds ([14 x i8]* @"\01L_OBJC_METH_VAR_TYPE_", i32 0, i32 0), i8* bitcast (%0* (%1*, i8*, %2*, %2*)* @"\01-[Hi components:splitInto:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([7 x i8]* @"\01L_OBJC_METH_VAR_NAME_5", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_6", i32 0, i32 0), i8* bitcast (%0* (%1*, i8*, %2*)* @"\01-[Hi lines:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([8 x i8]* @"\01L_OBJC_METH_VAR_NAME_7", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_8", i32 0, i32 0), i8* bitcast (i32 (%1*, i8*, i32)* @"\01-[Hi double:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([22 x i8]* @"\01L_OBJC_METH_VAR_NAME_3", i32 0, i32 0), i8* getelementptr inbounds ([14 x i8]* @"\01L_OBJC_METH_VAR_TYPE_9", i32 0, i32 0), i8* bitcast (i32 (%1*, i8*, i32, i32)* @"\01-[Hi mulByAddition:factor:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([15 x i8]* @"\01L_OBJC_METH_VAR_NAME_10", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_8", i32 0, i32 0), i8* bitcast (i32 (%1*, i8*, i32)* @"\01-[Hi mulByAddition:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([7 x i8]* @"\01L_OBJC_METH_VAR_NAME_11", i32 0, i32 0), i8* getelementptr inbounds ([8 x i8]* @"\01L_OBJC_METH_VAR_TYPE_12", i32 0, i32 0), i8* bitcast (i32 (%1*, i8*)* @"\01-[Hi factor]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_NAME_13", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_14", i32 0, i32 0), i8* bitcast (void (%1*, i8*, i32)* @"\01-[Hi setFactor:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([13 x i8]* @"\01L_OBJC_METH_VAR_NAME_15", i32 0, i32 0), i8* getelementptr inbounds ([8 x i8]* @"\01L_OBJC_METH_VAR_TYPE_16", i32 0, i32 0), i8* bitcast (i8* (%1*, i8*)* @"\01-[Hi someProperty]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([17 x i8]* @"\01L_OBJC_METH_VAR_NAME_17", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_18", i32 0, i32 0), i8* bitcast (void (%1*, i8*, i8*)* @"\01-[Hi setSomeProperty:]" to i8*) }] }, section "__DATA, __objc_const", align 8
@"\01L_OBJC_METH_VAR_TYPE_19" = internal global [2 x i8] c"i\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_NAME_20" = internal global [14 x i8] c"_someProperty\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@"\01L_OBJC_METH_VAR_TYPE_21" = internal global [2 x i8] c"@\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01l_OBJC_$_INSTANCE_VARIABLES_Hi" = internal global { i32, i32, [2 x %struct._ivar_t] } { i32 32, i32 2, [2 x %struct._ivar_t] [%struct._ivar_t { i64* @"OBJC_IVAR_$_Hi.factor", i8* getelementptr inbounds ([7 x i8]* @"\01L_OBJC_METH_VAR_NAME_11", i32 0, i32 0), i8* getelementptr inbounds ([2 x i8]* @"\01L_OBJC_METH_VAR_TYPE_19", i32 0, i32 0), i32 2, i32 4 }, %struct._ivar_t { i64* @"OBJC_IVAR_$_Hi._someProperty", i8* getelementptr inbounds ([14 x i8]* @"\01L_OBJC_METH_VAR_NAME_20", i32 0, i32 0), i8* getelementptr inbounds ([2 x i8]* @"\01L_OBJC_METH_VAR_TYPE_21", i32 0, i32 0), i32 3, i32 8 }] }, section "__DATA, __objc_const", align 8
@"\01L_OBJC_PROP_NAME_ATTR_" = internal global [7 x i8] c"factor\00", section "__TEXT,__cstring,cstring_literals", align 1
@"\01L_OBJC_PROP_NAME_ATTR_22" = internal global [11 x i8] c"Ti,Vfactor\00", section "__TEXT,__cstring,cstring_literals", align 1
@"\01L_OBJC_PROP_NAME_ATTR_23" = internal global [13 x i8] c"someProperty\00", section "__TEXT,__cstring,cstring_literals", align 1
@"\01L_OBJC_PROP_NAME_ATTR_24" = internal global [22 x i8] c"T@,&,N,V_someProperty\00", section "__TEXT,__cstring,cstring_literals", align 1
@"\01l_OBJC_$_PROP_LIST_Hi" = internal global { i32, i32, [2 x %struct._prop_t] } { i32 16, i32 2, [2 x %struct._prop_t] [%struct._prop_t { i8* getelementptr inbounds ([7 x i8]* @"\01L_OBJC_PROP_NAME_ATTR_", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_PROP_NAME_ATTR_22", i32 0, i32 0) }, %struct._prop_t { i8* getelementptr inbounds ([13 x i8]* @"\01L_OBJC_PROP_NAME_ATTR_23", i32 0, i32 0), i8* getelementptr inbounds ([22 x i8]* @"\01L_OBJC_PROP_NAME_ATTR_24", i32 0, i32 0) }] }, section "__DATA, __objc_const", align 8
@"\01l_OBJC_CLASS_RO_$_Hi" = internal global %struct._class_ro_t { i32 0, i32 8, i32 24, i8* null, i8* getelementptr inbounds ([3 x i8]* @"\01L_OBJC_CLASS_NAME_", i32 0, i32 0), %struct.__method_list_t* bitcast ({ i32, i32, [9 x %struct._objc_method] }* @"\01l_OBJC_$_INSTANCE_METHODS_Hi" to %struct.__method_list_t*), %struct._objc_protocol_list* null, %struct._ivar_list_t* bitcast ({ i32, i32, [2 x %struct._ivar_t] }* @"\01l_OBJC_$_INSTANCE_VARIABLES_Hi" to %struct._ivar_list_t*), i8* null, %struct._prop_list_t* bitcast ({ i32, i32, [2 x %struct._prop_t] }* @"\01l_OBJC_$_PROP_LIST_Hi" to %struct._prop_list_t*) }, section "__DATA, __objc_const", align 8
@"OBJC_CLASS_$_Hi" = global %struct._class_t { %struct._class_t* @"OBJC_METACLASS_$_Hi", %struct._class_t* @"OBJC_CLASS_$_NSObject", %struct._objc_cache* @_objc_empty_cache, i8* (i8*, i8*)** @_objc_empty_vtable, %struct._class_ro_t* @"\01l_OBJC_CLASS_RO_$_Hi" }, section "__DATA, __objc_data", align 8
@"\01L_OBJC_LABEL_CLASS_$" = internal global [1 x i8*] [i8* bitcast (%struct._class_t* @"OBJC_CLASS_$_Hi" to i8*)], section "__DATA, __objc_classlist, regular, no_dead_strip", align 8
@llvm.used = appending global [33 x i8*] [i8* getelementptr inbounds ([29 x i8]* @"\01L_OBJC_METH_VAR_NAME_", i32 0, i32 0), i8* bitcast (i8** @"\01L_OBJC_SELECTOR_REFERENCES_" to i8*), i8* getelementptr inbounds ([22 x i8]* @"\01L_OBJC_METH_VAR_NAME_1", i32 0, i32 0), i8* bitcast (i8** @"\01L_OBJC_SELECTOR_REFERENCES_2" to i8*), i8* getelementptr inbounds ([22 x i8]* @"\01L_OBJC_METH_VAR_NAME_3", i32 0, i32 0), i8* bitcast (i8** @"\01L_OBJC_SELECTOR_REFERENCES_4" to i8*), i8* getelementptr inbounds ([3 x i8]* @"\01L_OBJC_CLASS_NAME_", i32 0, i32 0), i8* getelementptr inbounds ([14 x i8]* @"\01L_OBJC_METH_VAR_TYPE_", i32 0, i32 0), i8* getelementptr inbounds ([7 x i8]* @"\01L_OBJC_METH_VAR_NAME_5", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_6", i32 0, i32 0), i8* getelementptr inbounds ([8 x i8]* @"\01L_OBJC_METH_VAR_NAME_7", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_8", i32 0, i32 0), i8* getelementptr inbounds ([14 x i8]* @"\01L_OBJC_METH_VAR_TYPE_9", i32 0, i32 0), i8* getelementptr inbounds ([15 x i8]* @"\01L_OBJC_METH_VAR_NAME_10", i32 0, i32 0), i8* getelementptr inbounds ([7 x i8]* @"\01L_OBJC_METH_VAR_NAME_11", i32 0, i32 0), i8* getelementptr inbounds ([8 x i8]* @"\01L_OBJC_METH_VAR_TYPE_12", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_NAME_13", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_14", i32 0, i32 0), i8* getelementptr inbounds ([13 x i8]* @"\01L_OBJC_METH_VAR_NAME_15", i32 0, i32 0), i8* getelementptr inbounds ([8 x i8]* @"\01L_OBJC_METH_VAR_TYPE_16", i32 0, i32 0), i8* getelementptr inbounds ([17 x i8]* @"\01L_OBJC_METH_VAR_NAME_17", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_METH_VAR_TYPE_18", i32 0, i32 0), i8* bitcast ({ i32, i32, [9 x %struct._objc_method] }* @"\01l_OBJC_$_INSTANCE_METHODS_Hi" to i8*), i8* getelementptr inbounds ([2 x i8]* @"\01L_OBJC_METH_VAR_TYPE_19", i32 0, i32 0), i8* getelementptr inbounds ([14 x i8]* @"\01L_OBJC_METH_VAR_NAME_20", i32 0, i32 0), i8* getelementptr inbounds ([2 x i8]* @"\01L_OBJC_METH_VAR_TYPE_21", i32 0, i32 0), i8* bitcast ({ i32, i32, [2 x %struct._ivar_t] }* @"\01l_OBJC_$_INSTANCE_VARIABLES_Hi" to i8*), i8* getelementptr inbounds ([7 x i8]* @"\01L_OBJC_PROP_NAME_ATTR_", i32 0, i32 0), i8* getelementptr inbounds ([11 x i8]* @"\01L_OBJC_PROP_NAME_ATTR_22", i32 0, i32 0), i8* getelementptr inbounds ([13 x i8]* @"\01L_OBJC_PROP_NAME_ATTR_23", i32 0, i32 0), i8* getelementptr inbounds ([22 x i8]* @"\01L_OBJC_PROP_NAME_ATTR_24", i32 0, i32 0), i8* bitcast ({ i32, i32, [2 x %struct._prop_t] }* @"\01l_OBJC_$_PROP_LIST_Hi" to i8*), i8* bitcast ([1 x i8*]* @"\01L_OBJC_LABEL_CLASS_$" to i8*)], section "llvm.metadata"

define internal %0* @"\01-[Hi components:splitInto:]"(%1* %self, i8* %_cmd, %2* %s, %2* %delimiter) ssp uwtable {
  %1 = alloca %1*, align 8
  %2 = alloca i8*, align 8
  %3 = alloca %2*, align 8
  %4 = alloca %2*, align 8
  store %1* %self, %1** %1, align 8
  store i8* %_cmd, i8** %2, align 8
  store %2* %s, %2** %3, align 8
  store %2* %delimiter, %2** %4, align 8
  %5 = load %2** %3, align 8
  %6 = load %2** %4, align 8
  %7 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_", !invariant.load !4
  %8 = bitcast %2* %5 to i8*
  %9 = call %0* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %0* (i8*, i8*, %2*)*)(i8* %8, i8* %7, %2* %6)
  ret %0* %9
}

declare i8* @objc_msgSend(i8*, i8*, ...) nonlazybind

define internal %0* @"\01-[Hi lines:]"(%1* %self, i8* %_cmd, %2* %s) ssp uwtable {
  %1 = alloca %1*, align 8
  %2 = alloca i8*, align 8
  %3 = alloca %2*, align 8
  store %1* %self, %1** %1, align 8
  store i8* %_cmd, i8** %2, align 8
  store %2* %s, %2** %3, align 8
  %4 = load %1** %1, align 8
  %5 = load %2** %3, align 8
  %6 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_2", !invariant.load !4
  %7 = bitcast %1* %4 to i8*
  %8 = call %0* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %0* (i8*, i8*, %2*, %2*)*)(i8* %7, i8* %6, %2* %5, %2* bitcast (%struct.NSConstantString* @_unnamed_cfstring_ to %2*))
  ret %0* %8
}

define internal i32 @"\01-[Hi double:]"(%1* %self, i8* %_cmd, i32 %input) ssp uwtable {
  %1 = alloca %1*, align 8
  %2 = alloca i8*, align 8
  %3 = alloca i32, align 4
  store %1* %self, %1** %1, align 8
  store i8* %_cmd, i8** %2, align 8
  store i32 %input, i32* %3, align 4
  %4 = load i32* %3, align 4
  %5 = mul nsw i32 %4, 2
  ret i32 %5
}

define internal i32 @"\01-[Hi mulByAddition:factor:]"(%1* %self, i8* %_cmd, i32 %input, i32 %lfactor) ssp uwtable {
  %1 = alloca %1*, align 8
  %2 = alloca i8*, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %i = alloca i32, align 4
  store %1* %self, %1** %1, align 8
  store i8* %_cmd, i8** %2, align 8
  store i32 %input, i32* %3, align 4
  store i32 %lfactor, i32* %4, align 4
  store i32 0, i32* %i, align 4
  br label %5

; <label>:5                                       ; preds = %13, %0
  %6 = load i32* %i, align 4
  %7 = load i32* %4, align 4
  %8 = icmp slt i32 %6, %7
  br i1 %8, label %9, label %16

; <label>:9                                       ; preds = %5
  %10 = load i32* %4, align 4
  %11 = load i32* %3, align 4
  %12 = add nsw i32 %11, %10
  store i32 %12, i32* %3, align 4
  br label %13

; <label>:13                                      ; preds = %9
  %14 = load i32* %i, align 4
  %15 = add nsw i32 %14, 1
  store i32 %15, i32* %i, align 4
  br label %5

; <label>:16                                      ; preds = %5
  %17 = load i32* %3, align 4
  ret i32 %17
}

define internal i32 @"\01-[Hi mulByAddition:]"(%1* %self, i8* %_cmd, i32 %input) ssp uwtable {
  %1 = alloca %1*, align 8
  %2 = alloca i8*, align 8
  %3 = alloca i32, align 4
  store %1* %self, %1** %1, align 8
  store i8* %_cmd, i8** %2, align 8
  store i32 %input, i32* %3, align 4
  %4 = load %1** %1, align 8
  %5 = load i32* %3, align 4
  %6 = load %1** %1, align 8
  %7 = load i64* @"OBJC_IVAR_$_Hi.factor", !invariant.load !4
  %8 = bitcast %1* %6 to i8*
  %9 = getelementptr inbounds i8* %8, i64 %7
  %10 = bitcast i8* %9 to i32*
  %11 = load i32* %10, align 4
  %12 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_4", !invariant.load !4
  %13 = bitcast %1* %4 to i8*
  %14 = call i32 bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to i32 (i8*, i8*, i32, i32)*)(i8* %13, i8* %12, i32 %5, i32 %11)
  ret i32 %14
}

define internal i32 @"\01-[Hi factor]"(%1* %self, i8* %_cmd) ssp uwtable {
  %1 = alloca %1*, align 8
  %2 = alloca i8*, align 8
  store %1* %self, %1** %1, align 8
  store i8* %_cmd, i8** %2, align 8
  %3 = load %1** %1, align 8
  %4 = load i64* @"OBJC_IVAR_$_Hi.factor", !invariant.load !4
  %5 = bitcast %1* %3 to i8*
  %6 = getelementptr inbounds i8* %5, i64 %4
  %7 = bitcast i8* %6 to i32*
  %8 = load atomic i32* %7 unordered, align 4
  ret i32 %8
}

define internal void @"\01-[Hi setFactor:]"(%1* %self, i8* %_cmd, i32 %factor) ssp uwtable {
  %1 = alloca %1*, align 8
  %2 = alloca i8*, align 8
  %3 = alloca i32, align 4
  store %1* %self, %1** %1, align 8
  store i8* %_cmd, i8** %2, align 8
  store i32 %factor, i32* %3, align 4
  %4 = load %1** %1, align 8
  %5 = load i64* @"OBJC_IVAR_$_Hi.factor", !invariant.load !4
  %6 = bitcast %1* %4 to i8*
  %7 = getelementptr inbounds i8* %6, i64 %5
  %8 = bitcast i8* %7 to i32*
  %9 = load i32* %3
  store atomic i32 %9, i32* %8 unordered, align 4
  ret void
}

define internal i8* @"\01-[Hi someProperty]"(%1* %self, i8* %_cmd) ssp uwtable {
  %1 = alloca %1*, align 8
  %2 = alloca i8*, align 8
  store %1* %self, %1** %1, align 8
  store i8* %_cmd, i8** %2, align 8
  %3 = load %1** %1, align 8
  %4 = load i64* @"OBJC_IVAR_$_Hi._someProperty", !invariant.load !4
  %5 = bitcast %1* %3 to i8*
  %6 = getelementptr inbounds i8* %5, i64 %4
  %7 = bitcast i8* %6 to i8**
  %8 = load i8** %7, align 8
  ret i8* %8
}

define internal void @"\01-[Hi setSomeProperty:]"(%1* %self, i8* %_cmd, i8* %someProperty) ssp uwtable {
  %1 = alloca %1*, align 8
  %2 = alloca i8*, align 8
  %3 = alloca i8*, align 8
  store %1* %self, %1** %1, align 8
  store i8* %_cmd, i8** %2, align 8
  store i8* %someProperty, i8** %3, align 8
  %4 = load i8** %2
  %5 = load %1** %1, align 8
  %6 = bitcast %1* %5 to i8*
  %7 = load i64* @"OBJC_IVAR_$_Hi._someProperty", !invariant.load !4
  %8 = load i8** %3
  call void @objc_setProperty_nonatomic(i8* %6, i8* %4, i8* %8, i64 %7)
  ret void
}

declare void @objc_setProperty_nonatomic(i8*, i8*, i8*, i64)

!llvm.module.flags = !{!0, !1, !2, !3}

!0 = metadata !{i32 1, metadata !"Objective-C Version", i32 2}
!1 = metadata !{i32 1, metadata !"Objective-C Image Info Version", i32 0}
!2 = metadata !{i32 1, metadata !"Objective-C Image Info Section", metadata !"__DATA, __objc_imageinfo, regular, no_dead_strip"}
!3 = metadata !{i32 4, metadata !"Objective-C Garbage Collection", i32 0}
!4 = metadata !{}
