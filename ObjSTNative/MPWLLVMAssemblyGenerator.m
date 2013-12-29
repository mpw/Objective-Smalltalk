//
//  MPWLLVMAssemblyGenerator.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 12/26/13.
//
//

#import "MPWLLVMAssemblyGenerator.h"

@implementation MPWLLVMAssemblyGenerator

-(void)writeHeaderWithName:(NSString*)name
{
    [self printLine:@"; ModuleID = '%@'",name];
    [self printLine:@"target datalayout = \"e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128\""];
    [self printLine:@"target triple = \"x86_64-apple-macosx10.9.0\""];
 
    
    [self printLine:@"%%struct._objc_cache = type opaque"];
    [self printLine:@"%%struct._class_t = type { %%struct._class_t*, %%struct._class_t*, %%struct._objc_cache*, i8* (i8*, i8*)**, %%struct._class_ro_t* }"];
    [self printLine:@"%%struct._class_ro_t = type { i32, i32, i32, i8*, i8*, %%struct.__method_list_t*, %%struct._objc_protocol_list*, %%struct._ivar_list_t*, i8*, %%struct._prop_list_t* }"];
    [self printLine:@"%%struct.__method_list_t = type { i32, i32, [0 x %%struct._objc_method] }"];
    [self printLine:@"%%struct._objc_method = type { i8*, i8*, i8* }"];
    [self printLine:@"%%struct._objc_protocol_list = type { i64, [0 x %%struct._protocol_t*] }"];
    [self printLine:@"%%struct._protocol_t = type { i8*, i8*, %%struct._objc_protocol_list*, %%struct.__method_list_t*, %%struct.__method_list_t*, %%struct.__method_list_t*, %%struct.__method_list_t*, %%struct._prop_list_t*, i32, i32, i8** }"];
    [self printLine:@"%%struct._prop_list_t = type { i32, i32, [0 x %%struct._prop_t] }"];
    [self printLine:@"%%struct._prop_t = type { i8*, i8* }"];
    [self printLine:@"%%struct._ivar_list_t = type { i32, i32, [0 x %%struct._ivar_t] }"];
    [self printLine:@"%%struct._ivar_t = type { i64*, i8*, i8*, i32, i32 }"];

    [self printLine:@"@_objc_empty_cache = external global %%struct._objc_cache"];
    [self printLine:@"@_objc_empty_vtable = external global i8* (i8*, i8*)*"];
   
}

-(void)writeExternalReferenceWithName:(NSString*)name type:(NSString*)type
{
    [self printLine:@"@\"%@\" = external global %@",name,type];
}

-(NSString*)classSymbolForName:(NSString*)className isMeta:(BOOL)isMeta
{
    NSString* base=isMeta ? @"OBJC_METACLASS_$_" : @"OBJC_CLASS_$_";
    return [base stringByAppendingString:className];
}

-(void)writeClassStructWithLabel:(NSString*)structLabel
                       className:(NSString*)classNameSymbol
                         nameLen:(long)nameLenNull
                          param1:(int)p1
                          param2:(int)p2
                   methodListRef:(NSString*)methodListRefSymbol
{
    NSString *methodListRef= methodListRefSymbol ? [NSString stringWithFormat:@"bitcast ({ i32, i32, [1 x %%struct._objc_method] }* @\"%@\" to %%struct.__method_list_t*)",methodListRefSymbol] : @"null";
    [self printLine:@"@\"%@\" = internal global %%struct._class_ro_t { i32 %d, i32 %d, i32 %d, i8* null, i8* getelementptr inbounds ([%d x i8]* @\"%@\", i32 0, i32 0), %%struct.__method_list_t* %@, %%struct._objc_protocol_list* null, %%struct._ivar_list_t* null, i8* null, %%struct._prop_list_t* null }, section \"__DATA, __objc_const\", align 8",structLabel,p1,p2,p2,nameLenNull,classNameSymbol,methodListRef];
}

-(void)writeClassDefWithLabel:(NSString*)classSymbol
                  structLabel:(NSString*)classStructSymbol
              superClassSymbol:(NSString*)superClassSymbol
              metaClassSymbol:(NSString*)metaClassSymbol
{
    [self printLine:@"@%@ = global %%struct._class_t { %%struct._class_t* @\"%@\", %%struct._class_t* @\"%@\", %%struct._objc_cache* @_objc_empty_cache, i8* (i8*, i8*)** @_objc_empty_vtable, %%struct._class_ro_t* @\"%@\" }, section \"__DATA, __objc_data\", align 8",classSymbol,metaClassSymbol,superClassSymbol,classStructSymbol];
}

-(void)writeClassWithName:(NSString*)aName superclassName:(NSString*)superclassName instanceMethodListRef:(NSString*)instanceMethodListSymbol
{
    long nameLen=[aName length];
    long nameLenNull=nameLen+1;
    NSString *superClassSymbol = [self classSymbolForName:superclassName isMeta:NO];
    NSString *superMetaClassSymbol =[self classSymbolForName:superclassName isMeta:YES];

    NSString *classSymbol = [self classSymbolForName:aName isMeta:NO];
    NSString *metaClassSymbol =[self classSymbolForName:aName isMeta:YES];

    NSString *classNameSymbol = [@"\\01L_OBJC_CLASS_NAME_" stringByAppendingString:aName];
    NSString *metaClassStructSymbol = [@"\\01l_OBJC_METACLASS_RO_$_" stringByAppendingString:aName];
    NSString *classStructSymbol =[@"\\01l_OBJC_CLASS_RO_$_" stringByAppendingString:aName];
    NSString *classLabelSymbol =[@"\\01L_OBJC_LABEL_CLASS_$_" stringByAppendingString:aName];
    
    [self writeExternalReferenceWithName:superClassSymbol type:@"%struct._class_t"];
    [self writeExternalReferenceWithName:superMetaClassSymbol type:@"%struct._class_t"];
    
    
    [self printLine:@"@\"%@\" = internal global [%d x i8] c\"%@\\00\", section \"__TEXT,__objc_classname,cstring_literals\", align 1",classNameSymbol,nameLenNull,aName];
    
    [self writeClassStructWithLabel:metaClassStructSymbol className:classNameSymbol nameLen:nameLenNull param1:1 param2:40 methodListRef:nil];
    [self writeClassDefWithLabel:metaClassSymbol structLabel:metaClassStructSymbol superClassSymbol:superMetaClassSymbol metaClassSymbol:superClassSymbol];
    
    
    [self writeClassStructWithLabel:classStructSymbol className:classNameSymbol nameLen:nameLenNull param1:0 param2:8 methodListRef:instanceMethodListSymbol];
    [self writeClassDefWithLabel:classSymbol structLabel:classStructSymbol superClassSymbol:superClassSymbol metaClassSymbol:metaClassSymbol];
    
    [self printLine:@"@\"\%@\" = internal global [1 x i8*] [i8* bitcast (%%struct._class_t* @\"%@\" to i8*)], section \"__DATA, __objc_classlist, regular, no_dead_strip\", align 8",classLabelSymbol, classSymbol];
    [self printLine:@"@llvm.used = appending global [2 x i8*] [i8* getelementptr inbounds ([%d x i8]* @\"%@\", i32 0, i32 0), i8* bitcast ([1 x i8*]* @\"%@\" to i8*)], section \"llvm.metadata\"",nameLenNull,classNameSymbol,classLabelSymbol];
    
}

-(NSString*)writeConstMethodAndMethodList:(NSString*)className
{
    NSString *methodListSymbol=[@"\\01l_OBJC_$_INSTANCE_METHODS_" stringByAppendingString:className];

    [self printLine:@"@\"\\01L_OBJC_METH_VAR_NAME_1\" = internal global [22 x i8] c\"components:splitInto:\\00\", section \"__TEXT,__objc_methname,cstring_literals\", align 1"];
    [self printLine:@"@\"\\01L_OBJC_METH_VAR_TYPE_\" = internal global [14 x i8] c\"@32@0:8@16@24\\00\", section \"__TEXT,__objc_methtype,cstring_literals\", align 1"];

    
    [self printLine:@"@\"%@\" = internal global { i32, i32, [1 x %struct._objc_method] } { i32 24, i32 1, [1 x %struct._objc_method] [%struct._objc_method { i8* getelementptr inbounds ([22 x i8]* @\"\\01L_OBJC_METH_VAR_NAME_1\", i32 0, i32 0), i8* getelementptr inbounds ([14 x i8]* @\"\\01L_OBJC_METH_VAR_TYPE_\", i32 0, i32 0), i8* bitcast (%0* (%1*, i8*, %2*, %2*)* @\"\\01-[Hi components:splitInto:]\" to i8*) }] }, section \"__DATA, __objc_const\", align 8",methodListSymbol];
    

    
    [self printLine:@""];
    [self printLine:@"define internal %%0* @\"\\01-[Hi components:splitInto:]\"(%%1* %%self, i8* %%_cmd, %%2* %%s, %%2* %%delimiter) uwtable ssp {"];
    [self printLine:@"%%1 = alloca %%1*, align 8"];
    [self printLine:@"%%2 = alloca i8*, align 8"];
    [self printLine:@"%%3 = alloca %%2*, align 8"];
    [self printLine:@"%%4 = alloca %%2*, align 8"];
    [self printLine:@"store %%1* %%self, %%1** %%1, align 8"];
    [self printLine:@"store i8* %%_cmd, i8** %%2, align 8"];
    [self printLine:@"store %%2* %%s, %%2** %%3, align 8"];
    [self printLine:@"store %%2* %%delimiter, %%2** %%4, align 8"];
    [self printLine:@"%%5 = load %%2** %%3, align 8"];
    [self printLine:@"%%6 = load %%2** %%4, align 8"];
    [self printLine:@"%%7 = load i8** @\"\\01L_OBJC_SELECTOR_REFERENCES_\", !invariant.load !4"];
    [self printLine:@"%%8 = bitcast %%2* %%5 to i8*"];
    [self printLine:@"%%9 = call %%0* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %%0* (i8*, i8*, %%2*)*)(i8* %%8, i8* %%7, %%2* %%6)"];
    [self printLine:@"ret %%0* %%9"];
    [self printLine:@"}"];
    [self printLine:@""];
    
    return methodListSymbol;

}

-(void)writeTrailer
{
    [self printLine:@" declare i8* @objc_msgSend(i8*, i8*, ...) nonlazybind"];

    [self printLine:@" !llvm.module.flags = !{!0, !1, !2, !3}"];
    [self printLine:@"!0 = metadata !{i32 1, metadata !\"Objective-C Version\", i32 2}"];
    [self printLine:@"!1 = metadata !{i32 1, metadata !\"Objective-C Image Info Version\", i32 0}"];
    [self printLine:@"!2 = metadata !{i32 1, metadata !\"Objective-C Image Info Section\", metadata !\"__DATA, __objc_imageinfo, regular, no_dead_strip\"}"];
    [self printLine:@"!3 = metadata !{i32 4, metadata !\"Objective-C Garbage Collection\", i32 0}"];
 
}



@end
