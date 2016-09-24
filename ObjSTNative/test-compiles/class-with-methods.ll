; ModuleID = 'class-with-methods.m'
source_filename = "class-with-methods.m"
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.12.0"

%0 = type opaque
%1 = type opaque
%2 = type opaque
%3 = type opaque
%struct.__NSConstantString_tag = type { i32*, i32, i8*, i64 }
%struct._class_t = type { %struct._class_t*, %struct._class_t*, %struct._objc_cache*, i8* (i8*, i8*)**, %struct._class_ro_t* }
%struct._objc_cache = type opaque
%struct._class_ro_t = type { i32, i32, i32, i8*, i8*, %struct.__method_list_t*, %struct._objc_protocol_list*, %struct._ivar_list_t*, i8*, %struct._prop_list_t* }
%struct.__method_list_t = type { i32, i32, [0 x %struct._objc_method] }
%struct._objc_method = type { i8*, i8*, i8* }
%struct._objc_protocol_list = type { i64, [0 x %struct._protocol_t*] }
%struct._protocol_t = type { i8*, i8*, %struct._objc_protocol_list*, %struct.__method_list_t*, %struct.__method_list_t*, %struct.__method_list_t*, %struct.__method_list_t*, %struct._prop_list_t*, i32, i32, i8**, i8*, %struct._prop_list_t* }
%struct._ivar_list_t = type { i32, i32, [0 x %struct._ivar_t] }
%struct._ivar_t = type { i64*, i8*, i8*, i32, i32 }
%struct._prop_list_t = type { i32, i32, [0 x %struct._prop_t] }
%struct._prop_t = type { i8*, i8* }

@OBJC_METH_VAR_NAME_ = private global [29 x i8] c"componentsSeparatedByString:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_SELECTOR_REFERENCES_ = private externally_initialized global i8* getelementptr inbounds ([29 x i8], [29 x i8]* @OBJC_METH_VAR_NAME_, i32 0, i32 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip", align 8
@__CFConstantStringClassReference = external global [0 x i32]
@.str = private unnamed_addr constant [2 x i8] c"\0A\00", section "__TEXT,__cstring,cstring_literals", align 1
@_unnamed_cfstring_ = private constant %struct.__NSConstantString_tag { i32* getelementptr inbounds ([0 x i32], [0 x i32]* @__CFConstantStringClassReference, i32 0, i32 0), i32 1992, i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str, i32 0, i32 0), i64 1 }, section "__DATA,__cfstring", align 8
@OBJC_METH_VAR_NAME_.1 = private global [22 x i8] c"components:splitInto:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_SELECTOR_REFERENCES_.2 = private externally_initialized global i8* getelementptr inbounds ([22 x i8], [22 x i8]* @OBJC_METH_VAR_NAME_.1, i32 0, i32 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip", align 8
@"OBJC_IVAR_$_Hi.factor" = global i64 8, section "__DATA, __objc_ivar", align 8
@OBJC_METH_VAR_NAME_.3 = private global [22 x i8] c"mulByAddition:factor:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_SELECTOR_REFERENCES_.4 = private externally_initialized global i8* getelementptr inbounds ([22 x i8], [22 x i8]* @OBJC_METH_VAR_NAME_.3, i32 0, i32 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip", align 8
@"OBJC_CLASS_$_NSNumber" = external global %struct._class_t
@"OBJC_CLASSLIST_REFERENCES_$_" = private global %struct._class_t* @"OBJC_CLASS_$_NSNumber", section "__DATA, __objc_classrefs, regular, no_dead_strip", align 8
@OBJC_METH_VAR_NAME_.5 = private global [15 x i8] c"numberWithInt:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_SELECTOR_REFERENCES_.6 = private externally_initialized global i8* getelementptr inbounds ([15 x i8], [15 x i8]* @OBJC_METH_VAR_NAME_.5, i32 0, i32 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip", align 8
@OBJC_METH_VAR_NAME_.7 = private global [5 x i8] c"mul:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_SELECTOR_REFERENCES_.8 = private externally_initialized global i8* getelementptr inbounds ([5 x i8], [5 x i8]* @OBJC_METH_VAR_NAME_.7, i32 0, i32 0), section "__DATA, __objc_selrefs, literal_pointers, no_dead_strip", align 8
@"OBJC_IVAR_$_Hi._someProperty" = hidden global i64 16, section "__DATA, __objc_ivar", align 8
@_objc_empty_cache = external global %struct._objc_cache
@"OBJC_METACLASS_$_NSObject" = external global %struct._class_t
@OBJC_CLASS_NAME_ = private global [3 x i8] c"Hi\00", section "__TEXT,__objc_classname,cstring_literals", align 1
@"\01l_OBJC_METACLASS_RO_$_Hi" = private global %struct._class_ro_t { i32 1, i32 40, i32 40, i8* null, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @OBJC_CLASS_NAME_, i32 0, i32 0), %struct.__method_list_t* null, %struct._objc_protocol_list* null, %struct._ivar_list_t* null, i8* null, %struct._prop_list_t* null }, section "__DATA, __objc_const", align 8
@"OBJC_METACLASS_$_Hi" = global %struct._class_t { %struct._class_t* @"OBJC_METACLASS_$_NSObject", %struct._class_t* @"OBJC_METACLASS_$_NSObject", %struct._objc_cache* @_objc_empty_cache, i8* (i8*, i8*)** null, %struct._class_ro_t* @"\01l_OBJC_METACLASS_RO_$_Hi" }, section "__DATA, __objc_data", align 8
@"OBJC_CLASS_$_NSObject" = external global %struct._class_t
@OBJC_METH_VAR_TYPE_ = private global [14 x i8] c"@32@0:8@16@24\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@OBJC_METH_VAR_NAME_.9 = private global [7 x i8] c"lines:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_METH_VAR_TYPE_.10 = private global [11 x i8] c"@24@0:8@16\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@OBJC_METH_VAR_NAME_.11 = private global [8 x i8] c"double:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_METH_VAR_TYPE_.12 = private global [11 x i8] c"i20@0:8i16\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@OBJC_METH_VAR_TYPE_.13 = private global [14 x i8] c"i24@0:8i16i20\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@OBJC_METH_VAR_NAME_.14 = private global [15 x i8] c"mulByAddition:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_METH_VAR_NAME_.15 = private global [16 x i8] c"mulNSNumberBy3:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_METH_VAR_NAME_.16 = private global [12 x i8] c"makeNumber:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_METH_VAR_TYPE_.17 = private global [11 x i8] c"@20@0:8i16\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@OBJC_METH_VAR_NAME_.18 = private global [12 x i8] c"makeNumber3\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_METH_VAR_TYPE_.19 = private global [8 x i8] c"@16@0:8\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@OBJC_METH_VAR_NAME_.20 = private global [7 x i8] c"factor\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_METH_VAR_TYPE_.21 = private global [8 x i8] c"i16@0:8\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@OBJC_METH_VAR_NAME_.22 = private global [11 x i8] c"setFactor:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_METH_VAR_TYPE_.23 = private global [11 x i8] c"v20@0:8i16\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@OBJC_METH_VAR_NAME_.24 = private global [13 x i8] c"someProperty\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_METH_VAR_NAME_.25 = private global [17 x i8] c"setSomeProperty:\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_METH_VAR_TYPE_.26 = private global [11 x i8] c"v24@0:8@16\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01l_OBJC_$_INSTANCE_METHODS_Hi" = private global { i32, i32, [12 x %struct._objc_method] } { i32 24, i32 12, [12 x %struct._objc_method] [%struct._objc_method { i8* getelementptr inbounds ([22 x i8], [22 x i8]* @OBJC_METH_VAR_NAME_.1, i32 0, i32 0), i8* getelementptr inbounds ([14 x i8], [14 x i8]* @OBJC_METH_VAR_TYPE_, i32 0, i32 0), i8* bitcast (%0* (%1*, i8*, %2*, %2*)* @"\01-[Hi components:splitInto:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([7 x i8], [7 x i8]* @OBJC_METH_VAR_NAME_.9, i32 0, i32 0), i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_METH_VAR_TYPE_.10, i32 0, i32 0), i8* bitcast (%0* (%1*, i8*, %2*)* @"\01-[Hi lines:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([8 x i8], [8 x i8]* @OBJC_METH_VAR_NAME_.11, i32 0, i32 0), i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_METH_VAR_TYPE_.12, i32 0, i32 0), i8* bitcast (i32 (%1*, i8*, i32)* @"\01-[Hi double:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([22 x i8], [22 x i8]* @OBJC_METH_VAR_NAME_.3, i32 0, i32 0), i8* getelementptr inbounds ([14 x i8], [14 x i8]* @OBJC_METH_VAR_TYPE_.13, i32 0, i32 0), i8* bitcast (i32 (%1*, i8*, i32, i32)* @"\01-[Hi mulByAddition:factor:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([15 x i8], [15 x i8]* @OBJC_METH_VAR_NAME_.14, i32 0, i32 0), i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_METH_VAR_TYPE_.12, i32 0, i32 0), i8* bitcast (i32 (%1*, i8*, i32)* @"\01-[Hi mulByAddition:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([16 x i8], [16 x i8]* @OBJC_METH_VAR_NAME_.15, i32 0, i32 0), i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_METH_VAR_TYPE_.10, i32 0, i32 0), i8* bitcast (%3* (%1*, i8*, %3*)* @"\01-[Hi mulNSNumberBy3:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([12 x i8], [12 x i8]* @OBJC_METH_VAR_NAME_.16, i32 0, i32 0), i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_METH_VAR_TYPE_.17, i32 0, i32 0), i8* bitcast (%3* (%1*, i8*, i32)* @"\01-[Hi makeNumber:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([12 x i8], [12 x i8]* @OBJC_METH_VAR_NAME_.18, i32 0, i32 0), i8* getelementptr inbounds ([8 x i8], [8 x i8]* @OBJC_METH_VAR_TYPE_.19, i32 0, i32 0), i8* bitcast (%3* (%1*, i8*)* @"\01-[Hi makeNumber3]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([7 x i8], [7 x i8]* @OBJC_METH_VAR_NAME_.20, i32 0, i32 0), i8* getelementptr inbounds ([8 x i8], [8 x i8]* @OBJC_METH_VAR_TYPE_.21, i32 0, i32 0), i8* bitcast (i32 (%1*, i8*)* @"\01-[Hi factor]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_METH_VAR_NAME_.22, i32 0, i32 0), i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_METH_VAR_TYPE_.23, i32 0, i32 0), i8* bitcast (void (%1*, i8*, i32)* @"\01-[Hi setFactor:]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([13 x i8], [13 x i8]* @OBJC_METH_VAR_NAME_.24, i32 0, i32 0), i8* getelementptr inbounds ([8 x i8], [8 x i8]* @OBJC_METH_VAR_TYPE_.19, i32 0, i32 0), i8* bitcast (i8* (%1*, i8*)* @"\01-[Hi someProperty]" to i8*) }, %struct._objc_method { i8* getelementptr inbounds ([17 x i8], [17 x i8]* @OBJC_METH_VAR_NAME_.25, i32 0, i32 0), i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_METH_VAR_TYPE_.26, i32 0, i32 0), i8* bitcast (void (%1*, i8*, i8*)* @"\01-[Hi setSomeProperty:]" to i8*) }] }, section "__DATA, __objc_const", align 8
@OBJC_METH_VAR_TYPE_.27 = private global [2 x i8] c"i\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@OBJC_METH_VAR_NAME_.28 = private global [14 x i8] c"_someProperty\00", section "__TEXT,__objc_methname,cstring_literals", align 1
@OBJC_METH_VAR_TYPE_.29 = private global [2 x i8] c"@\00", section "__TEXT,__objc_methtype,cstring_literals", align 1
@"\01l_OBJC_$_INSTANCE_VARIABLES_Hi" = private global { i32, i32, [2 x %struct._ivar_t] } { i32 32, i32 2, [2 x %struct._ivar_t] [%struct._ivar_t { i64* @"OBJC_IVAR_$_Hi.factor", i8* getelementptr inbounds ([7 x i8], [7 x i8]* @OBJC_METH_VAR_NAME_.20, i32 0, i32 0), i8* getelementptr inbounds ([2 x i8], [2 x i8]* @OBJC_METH_VAR_TYPE_.27, i32 0, i32 0), i32 2, i32 4 }, %struct._ivar_t { i64* @"OBJC_IVAR_$_Hi._someProperty", i8* getelementptr inbounds ([14 x i8], [14 x i8]* @OBJC_METH_VAR_NAME_.28, i32 0, i32 0), i8* getelementptr inbounds ([2 x i8], [2 x i8]* @OBJC_METH_VAR_TYPE_.29, i32 0, i32 0), i32 3, i32 8 }] }, section "__DATA, __objc_const", align 8
@OBJC_PROP_NAME_ATTR_ = private global [7 x i8] c"factor\00", section "__TEXT,__cstring,cstring_literals", align 1
@OBJC_PROP_NAME_ATTR_.30 = private global [11 x i8] c"Ti,Vfactor\00", section "__TEXT,__cstring,cstring_literals", align 1
@OBJC_PROP_NAME_ATTR_.31 = private global [13 x i8] c"someProperty\00", section "__TEXT,__cstring,cstring_literals", align 1
@OBJC_PROP_NAME_ATTR_.32 = private global [22 x i8] c"T@,&,N,V_someProperty\00", section "__TEXT,__cstring,cstring_literals", align 1
@"\01l_OBJC_$_PROP_LIST_Hi" = private global { i32, i32, [2 x %struct._prop_t] } { i32 16, i32 2, [2 x %struct._prop_t] [%struct._prop_t { i8* getelementptr inbounds ([7 x i8], [7 x i8]* @OBJC_PROP_NAME_ATTR_, i32 0, i32 0), i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_PROP_NAME_ATTR_.30, i32 0, i32 0) }, %struct._prop_t { i8* getelementptr inbounds ([13 x i8], [13 x i8]* @OBJC_PROP_NAME_ATTR_.31, i32 0, i32 0), i8* getelementptr inbounds ([22 x i8], [22 x i8]* @OBJC_PROP_NAME_ATTR_.32, i32 0, i32 0) }] }, section "__DATA, __objc_const", align 8
@"\01l_OBJC_CLASS_RO_$_Hi" = private global %struct._class_ro_t { i32 0, i32 8, i32 24, i8* null, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @OBJC_CLASS_NAME_, i32 0, i32 0), %struct.__method_list_t* bitcast ({ i32, i32, [12 x %struct._objc_method] }* @"\01l_OBJC_$_INSTANCE_METHODS_Hi" to %struct.__method_list_t*), %struct._objc_protocol_list* null, %struct._ivar_list_t* bitcast ({ i32, i32, [2 x %struct._ivar_t] }* @"\01l_OBJC_$_INSTANCE_VARIABLES_Hi" to %struct._ivar_list_t*), i8* null, %struct._prop_list_t* bitcast ({ i32, i32, [2 x %struct._prop_t] }* @"\01l_OBJC_$_PROP_LIST_Hi" to %struct._prop_list_t*) }, section "__DATA, __objc_const", align 8
@"OBJC_CLASS_$_Hi" = global %struct._class_t { %struct._class_t* @"OBJC_METACLASS_$_Hi", %struct._class_t* @"OBJC_CLASS_$_NSObject", %struct._objc_cache* @_objc_empty_cache, i8* (i8*, i8*)** null, %struct._class_ro_t* @"\01l_OBJC_CLASS_RO_$_Hi" }, section "__DATA, __objc_data", align 8
@"OBJC_LABEL_CLASS_$" = private global [1 x i8*] [i8* bitcast (%struct._class_t* @"OBJC_CLASS_$_Hi" to i8*)], section "__DATA, __objc_classlist, regular, no_dead_strip", align 8
@llvm.compiler.used = appending global [42 x i8*] [i8* getelementptr inbounds ([29 x i8], [29 x i8]* @OBJC_METH_VAR_NAME_, i32 0, i32 0), i8* bitcast (i8** @OBJC_SELECTOR_REFERENCES_ to i8*), i8* getelementptr inbounds ([22 x i8], [22 x i8]* @OBJC_METH_VAR_NAME_.1, i32 0, i32 0), i8* bitcast (i8** @OBJC_SELECTOR_REFERENCES_.2 to i8*), i8* getelementptr inbounds ([22 x i8], [22 x i8]* @OBJC_METH_VAR_NAME_.3, i32 0, i32 0), i8* bitcast (i8** @OBJC_SELECTOR_REFERENCES_.4 to i8*), i8* bitcast (%struct._class_t** @"OBJC_CLASSLIST_REFERENCES_$_" to i8*), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @OBJC_METH_VAR_NAME_.5, i32 0, i32 0), i8* bitcast (i8** @OBJC_SELECTOR_REFERENCES_.6 to i8*), i8* getelementptr inbounds ([5 x i8], [5 x i8]* @OBJC_METH_VAR_NAME_.7, i32 0, i32 0), i8* bitcast (i8** @OBJC_SELECTOR_REFERENCES_.8 to i8*), i8* getelementptr inbounds ([3 x i8], [3 x i8]* @OBJC_CLASS_NAME_, i32 0, i32 0), i8* getelementptr inbounds ([14 x i8], [14 x i8]* @OBJC_METH_VAR_TYPE_, i32 0, i32 0), i8* getelementptr inbounds ([7 x i8], [7 x i8]* @OBJC_METH_VAR_NAME_.9, i32 0, i32 0), i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_METH_VAR_TYPE_.10, i32 0, i32 0), i8* getelementptr inbounds ([8 x i8], [8 x i8]* @OBJC_METH_VAR_NAME_.11, i32 0, i32 0), i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_METH_VAR_TYPE_.12, i32 0, i32 0), i8* getelementptr inbounds ([14 x i8], [14 x i8]* @OBJC_METH_VAR_TYPE_.13, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @OBJC_METH_VAR_NAME_.14, i32 0, i32 0), i8* getelementptr inbounds ([16 x i8], [16 x i8]* @OBJC_METH_VAR_NAME_.15, i32 0, i32 0), i8* getelementptr inbounds ([12 x i8], [12 x i8]* @OBJC_METH_VAR_NAME_.16, i32 0, i32 0), i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_METH_VAR_TYPE_.17, i32 0, i32 0), i8* getelementptr inbounds ([12 x i8], [12 x i8]* @OBJC_METH_VAR_NAME_.18, i32 0, i32 0), i8* getelementptr inbounds ([8 x i8], [8 x i8]* @OBJC_METH_VAR_TYPE_.19, i32 0, i32 0), i8* getelementptr inbounds ([7 x i8], [7 x i8]* @OBJC_METH_VAR_NAME_.20, i32 0, i32 0), i8* getelementptr inbounds ([8 x i8], [8 x i8]* @OBJC_METH_VAR_TYPE_.21, i32 0, i32 0), i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_METH_VAR_NAME_.22, i32 0, i32 0), i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_METH_VAR_TYPE_.23, i32 0, i32 0), i8* getelementptr inbounds ([13 x i8], [13 x i8]* @OBJC_METH_VAR_NAME_.24, i32 0, i32 0), i8* getelementptr inbounds ([17 x i8], [17 x i8]* @OBJC_METH_VAR_NAME_.25, i32 0, i32 0), i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_METH_VAR_TYPE_.26, i32 0, i32 0), i8* bitcast ({ i32, i32, [12 x %struct._objc_method] }* @"\01l_OBJC_$_INSTANCE_METHODS_Hi" to i8*), i8* getelementptr inbounds ([2 x i8], [2 x i8]* @OBJC_METH_VAR_TYPE_.27, i32 0, i32 0), i8* getelementptr inbounds ([14 x i8], [14 x i8]* @OBJC_METH_VAR_NAME_.28, i32 0, i32 0), i8* getelementptr inbounds ([2 x i8], [2 x i8]* @OBJC_METH_VAR_TYPE_.29, i32 0, i32 0), i8* bitcast ({ i32, i32, [2 x %struct._ivar_t] }* @"\01l_OBJC_$_INSTANCE_VARIABLES_Hi" to i8*), i8* getelementptr inbounds ([7 x i8], [7 x i8]* @OBJC_PROP_NAME_ATTR_, i32 0, i32 0), i8* getelementptr inbounds ([11 x i8], [11 x i8]* @OBJC_PROP_NAME_ATTR_.30, i32 0, i32 0), i8* getelementptr inbounds ([13 x i8], [13 x i8]* @OBJC_PROP_NAME_ATTR_.31, i32 0, i32 0), i8* getelementptr inbounds ([22 x i8], [22 x i8]* @OBJC_PROP_NAME_ATTR_.32, i32 0, i32 0), i8* bitcast ({ i32, i32, [2 x %struct._prop_t] }* @"\01l_OBJC_$_PROP_LIST_Hi" to i8*), i8* bitcast ([1 x i8*]* @"OBJC_LABEL_CLASS_$" to i8*)], section "llvm.metadata"

; Function Attrs: ssp uwtable
define internal %0* @"\01-[Hi components:splitInto:]"(%1*, i8*, %2*, %2*) #0 {
  %5 = alloca %1*, align 8
  %6 = alloca i8*, align 8
  %7 = alloca %2*, align 8
  %8 = alloca %2*, align 8
  store %1* %0, %1** %5, align 8
  store i8* %1, i8** %6, align 8
  store %2* %2, %2** %7, align 8
  store %2* %3, %2** %8, align 8
  %9 = load %2*, %2** %7, align 8
  %10 = load %2*, %2** %8, align 8
  %11 = load i8*, i8** @OBJC_SELECTOR_REFERENCES_, align 8, !invariant.load !7
  %12 = bitcast %2* %9 to i8*
  %13 = call %0* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %0* (i8*, i8*, %2*)*)(i8* %12, i8* %11, %2* %10)
  ret %0* %13
}

; Function Attrs: nonlazybind
declare i8* @objc_msgSend(i8*, i8*, ...) #1

; Function Attrs: ssp uwtable
define internal %0* @"\01-[Hi lines:]"(%1*, i8*, %2*) #0 {
  %4 = alloca %1*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca %2*, align 8
  store %1* %0, %1** %4, align 8
  store i8* %1, i8** %5, align 8
  store %2* %2, %2** %6, align 8
  %7 = load %1*, %1** %4, align 8
  %8 = load %2*, %2** %6, align 8
  %9 = load i8*, i8** @OBJC_SELECTOR_REFERENCES_.2, align 8, !invariant.load !7
  %10 = bitcast %1* %7 to i8*
  %11 = call %0* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %0* (i8*, i8*, %2*, %2*)*)(i8* %10, i8* %9, %2* %8, %2* bitcast (%struct.__NSConstantString_tag* @_unnamed_cfstring_ to %2*))
  ret %0* %11
}

; Function Attrs: ssp uwtable
define internal i32 @"\01-[Hi double:]"(%1*, i8*, i32) #0 {
  %4 = alloca %1*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca i32, align 4
  store %1* %0, %1** %4, align 8
  store i8* %1, i8** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load i32, i32* %6, align 4
  %8 = mul nsw i32 %7, 2
  ret i32 %8
}

; Function Attrs: ssp uwtable
define internal i32 @"\01-[Hi mulByAddition:factor:]"(%1*, i8*, i32, i32) #0 {
  %5 = alloca %1*, align 8
  %6 = alloca i8*, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store %1* %0, %1** %5, align 8
  store i8* %1, i8** %6, align 8
  store i32 %2, i32* %7, align 4
  store i32 %3, i32* %8, align 4
  store i32 0, i32* %9, align 4
  br label %10

; <label>:10                                      ; preds = %18, %4
  %11 = load i32, i32* %9, align 4
  %12 = load i32, i32* %8, align 4
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %14, label %21

; <label>:14                                      ; preds = %10
  %15 = load i32, i32* %8, align 4
  %16 = load i32, i32* %7, align 4
  %17 = add nsw i32 %16, %15
  store i32 %17, i32* %7, align 4
  br label %18

; <label>:18                                      ; preds = %14
  %19 = load i32, i32* %9, align 4
  %20 = add nsw i32 %19, 1
  store i32 %20, i32* %9, align 4
  br label %10

; <label>:21                                      ; preds = %10
  %22 = load i32, i32* %7, align 4
  ret i32 %22
}

; Function Attrs: ssp uwtable
define internal i32 @"\01-[Hi mulByAddition:]"(%1*, i8*, i32) #0 {
  %4 = alloca %1*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca i32, align 4
  store %1* %0, %1** %4, align 8
  store i8* %1, i8** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %1*, %1** %4, align 8
  %8 = load i32, i32* %6, align 4
  %9 = load %1*, %1** %4, align 8
  %10 = load i64, i64* @"OBJC_IVAR_$_Hi.factor", align 8, !invariant.load !7
  %11 = bitcast %1* %9 to i8*
  %12 = getelementptr inbounds i8, i8* %11, i64 %10
  %13 = bitcast i8* %12 to i32*
  %14 = load i32, i32* %13, align 4
  %15 = load i8*, i8** @OBJC_SELECTOR_REFERENCES_.4, align 8, !invariant.load !7
  %16 = bitcast %1* %7 to i8*
  %17 = call i32 bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to i32 (i8*, i8*, i32, i32)*)(i8* %16, i8* %15, i32 %8, i32 %14)
  ret i32 %17
}

; Function Attrs: ssp uwtable
define internal %3* @"\01-[Hi mulNSNumberBy3:]"(%1*, i8*, %3*) #0 {
  %4 = alloca %1*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca %3*, align 8
  store %1* %0, %1** %4, align 8
  store i8* %1, i8** %5, align 8
  store %3* %2, %3** %6, align 8
  %7 = load %3*, %3** %6, align 8
  %8 = load %struct._class_t*, %struct._class_t** @"OBJC_CLASSLIST_REFERENCES_$_", align 8
  %9 = load i8*, i8** @OBJC_SELECTOR_REFERENCES_.6, align 8, !invariant.load !7
  %10 = bitcast %struct._class_t* %8 to i8*
  %11 = call %3* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %3* (i8*, i8*, i32)*)(i8* %10, i8* %9, i32 3)
  %12 = load i8*, i8** @OBJC_SELECTOR_REFERENCES_.8, align 8, !invariant.load !7
  %13 = bitcast %3* %7 to i8*
  %14 = call i8* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to i8* (i8*, i8*, %3*)*)(i8* %13, i8* %12, %3* %11)
  %15 = bitcast i8* %14 to %3*
  ret %3* %15
}

; Function Attrs: ssp uwtable
define internal %3* @"\01-[Hi makeNumber:]"(%1*, i8*, i32) #0 {
  %4 = alloca %1*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca i32, align 4
  store %1* %0, %1** %4, align 8
  store i8* %1, i8** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %struct._class_t*, %struct._class_t** @"OBJC_CLASSLIST_REFERENCES_$_", align 8
  %8 = load i32, i32* %6, align 4
  %9 = load i8*, i8** @OBJC_SELECTOR_REFERENCES_.6, align 8, !invariant.load !7
  %10 = bitcast %struct._class_t* %7 to i8*
  %11 = call %3* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %3* (i8*, i8*, i32)*)(i8* %10, i8* %9, i32 %8)
  ret %3* %11
}

; Function Attrs: ssp uwtable
define internal %3* @"\01-[Hi makeNumber3]"(%1*, i8*) #0 {
  %3 = alloca %1*, align 8
  %4 = alloca i8*, align 8
  store %1* %0, %1** %3, align 8
  store i8* %1, i8** %4, align 8
  %5 = load %struct._class_t*, %struct._class_t** @"OBJC_CLASSLIST_REFERENCES_$_", align 8
  %6 = load i8*, i8** @OBJC_SELECTOR_REFERENCES_.6, align 8, !invariant.load !7
  %7 = bitcast %struct._class_t* %5 to i8*
  %8 = call %3* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %3* (i8*, i8*, i32)*)(i8* %7, i8* %6, i32 3)
  ret %3* %8
}

; Function Attrs: ssp uwtable
define internal i32 @"\01-[Hi factor]"(%1*, i8*) #0 {
  %3 = alloca %1*, align 8
  %4 = alloca i8*, align 8
  store %1* %0, %1** %3, align 8
  store i8* %1, i8** %4, align 8
  %5 = load %1*, %1** %3, align 8
  %6 = load i64, i64* @"OBJC_IVAR_$_Hi.factor", align 8, !invariant.load !7
  %7 = bitcast %1* %5 to i8*
  %8 = getelementptr inbounds i8, i8* %7, i64 %6
  %9 = bitcast i8* %8 to i32*
  %10 = load atomic i32, i32* %9 unordered, align 4
  ret i32 %10
}

; Function Attrs: ssp uwtable
define internal void @"\01-[Hi setFactor:]"(%1*, i8*, i32) #0 {
  %4 = alloca %1*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca i32, align 4
  store %1* %0, %1** %4, align 8
  store i8* %1, i8** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %1*, %1** %4, align 8
  %8 = load i64, i64* @"OBJC_IVAR_$_Hi.factor", align 8, !invariant.load !7
  %9 = bitcast %1* %7 to i8*
  %10 = getelementptr inbounds i8, i8* %9, i64 %8
  %11 = bitcast i8* %10 to i32*
  %12 = load i32, i32* %6, align 4
  store atomic i32 %12, i32* %11 unordered, align 4
  ret void
}

; Function Attrs: ssp uwtable
define internal i8* @"\01-[Hi someProperty]"(%1*, i8*) #0 {
  %3 = alloca %1*, align 8
  %4 = alloca i8*, align 8
  store %1* %0, %1** %3, align 8
  store i8* %1, i8** %4, align 8
  %5 = load %1*, %1** %3, align 8
  %6 = load i64, i64* @"OBJC_IVAR_$_Hi._someProperty", align 8, !invariant.load !7
  %7 = bitcast %1* %5 to i8*
  %8 = getelementptr inbounds i8, i8* %7, i64 %6
  %9 = bitcast i8* %8 to i8**
  %10 = load i8*, i8** %9, align 8
  ret i8* %10
}

; Function Attrs: ssp uwtable
define internal void @"\01-[Hi setSomeProperty:]"(%1*, i8*, i8*) #0 {
  %4 = alloca %1*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca i8*, align 8
  store %1* %0, %1** %4, align 8
  store i8* %1, i8** %5, align 8
  store i8* %2, i8** %6, align 8
  %7 = load i8*, i8** %5, align 8
  %8 = load %1*, %1** %4, align 8
  %9 = bitcast %1* %8 to i8*
  %10 = load i64, i64* @"OBJC_IVAR_$_Hi._someProperty", align 8, !invariant.load !7
  %11 = load i8*, i8** %6, align 8
  call void @objc_setProperty_nonatomic(i8* %9, i8* %7, i8* %11, i64 %10)
  ret void
}

declare void @objc_setProperty_nonatomic(i8*, i8*, i8*, i64)

attributes #0 = { ssp uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+fxsr,+mmx,+sse,+sse2,+sse3,+sse4.1,+ssse3" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nonlazybind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5}
!llvm.ident = !{!6}

!0 = !{i32 1, !"Objective-C Version", i32 2}
!1 = !{i32 1, !"Objective-C Image Info Version", i32 0}
!2 = !{i32 1, !"Objective-C Image Info Section", !"__DATA, __objc_imageinfo, regular, no_dead_strip"}
!3 = !{i32 4, !"Objective-C Garbage Collection", i32 0}
!4 = !{i32 1, !"Objective-C Class Properties", i32 64}
!5 = !{i32 1, !"PIC Level", i32 2}
!6 = !{!"Apple LLVM version 8.0.0 (clang-800.0.38)"}
!7 = !{}
