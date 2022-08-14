//
//  MPWLLVMAssemblyGenerator.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 12/26/13.
//
//

#import "MPWLLVMAssemblyGenerator.h"

@implementation MPWLLVMAssemblyGenerator

objectAccessor(NSMutableDictionary*, selectorReferences, setSelectorReferences)

objectAccessor(NSString*, nsnumberclassref, setNSnumberclassref)

-(id)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    [self setSelectorReferences:[NSMutableDictionary dictionary]];
    return self;
}

-(NSString*)selectorForName:(NSString*)selectorName
{
    NSString *ref=selectorReferences[selectorName];
    if ( !ref ) {
        ref=[NSString stringWithFormat:@"\\01L_OBJC_SELECTOR_REFERENCES_%d",(int)[selectorReferences count]];
        selectorReferences[selectorName]=ref;
    }
    return ref;
}

-(NSString*)classRefForClassName:(NSString*)className
{
    NSString* classSymbol=[self classSymbolForName:className isMeta:NO];
    [self writeExternalReferenceWithName:classSymbol type:@"%struct._class_t"];
    NSString *classRefSymbol=[NSString stringWithFormat:@"\\01L_OBJC_CLASSLIST_REFERENCES_%@",className];
    
    [self printLine:@"@\"%@\" = internal global %%struct._class_t* @\"%@\", section \"__DATA, __objc_classrefs, regular, no_dead_strip\", align 8",classRefSymbol,classSymbol];
    return classRefSymbol;
}

-(void)writeHeaderWithName:(NSString*)name
{
    [self printLine:@"%%object = type opaque"];
    [self printLine:@"%%id = type %%object*"];
    

    [self printLine:@"; ModuleID = '%@'",name];
    [self printLine:@"target datalayout = \"e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128\""];
    [self printLine:@"target triple = \"x86_64-apple-macosx10.9.0\""];
 
    [self printLine:@"%%struct.NSConstantString = type { i32*, i32, i8*, i64 }"];

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
    [self printLine:@"%%struct._category_t = type { i8*, %%struct._class_t*, %%struct.__method_list_t*, %%struct.__method_list_t*, %%struct._objc_protocol_list*, %%struct._prop_list_t* }"];
    
    [self printLine:@"%%struct.__block_literal_generic = type { i8*, i32, i32, i8*, %%struct.__block_descriptor* }"];
    [self printLine:@"%%struct.__block_descriptor = type { i64, i64 }"];

    
    [self printLine:@"@_objc_empty_cache = external global %%struct._objc_cache"];
    [self printLine:@"@_objc_empty_vtable = external global i8* (i8*, i8*)*"];
    [self printLine:@"@__CFConstantStringClassReference = external global [0 x i32]"];

    [self setNSnumberclassref:[self classRefForClassName:@"NSNumber"]];

    [self printLine:@"@_NSConcreteGlobalBlock = external global i8*"];
    [self printLine:@"@_NSConcreteStackBlock = external global i8*"];
    

    
}

-(void)writeExternalReferenceWithName:(NSString*)name type:(NSString*)type
{
    [self printLine:@"@\"%@\" = external global %@",name,type];
}


-(void)generateCString:(NSString*)cstring symbol:(NSString*)symbolName type:(NSString*)type
{
    NSString *sectionString=[NSString stringWithFormat:@"section \"__TEXT,%@,cstring_literals\", align 1",type];
    [self printLine:@"@\"%@\" = internal global [%ld x i8] c\"%@\\00\", %@",symbolName,[cstring length]+1,cstring,sectionString];
}

-(void)writeNSConstantString:(NSString*)value withSymbol:(NSString*)symbol
{
    // currently still ignores the value
    int stringLen=(int)[value length];
    int withNull=stringLen+1;
    numStrings++;
    
    [self printFormat:@"@.str_%d = private unnamed_addr constant [%d x i8] c\"",numStrings,withNull ];
    for (int i=0;i<[value length];i++) {
        unichar ch=[value characterAtIndex:i];
        if ( ch < 32 ) {
            [self printFormat:@"\\0%x",ch];
        } else {
            [self printFormat:@"%c",ch];
        }
    }
    [self printLine:@"\\00\", align 1"];
    
    [self printLine:@"%@ = private constant %%struct.NSConstantString { i32* getelementptr inbounds ([0 x i32],[0 x i32]* @__CFConstantStringClassReference, i32 0, i32 0), i32 1992, i8* getelementptr inbounds ([%d x i8],[%d x i8]* @.str_%d, i32 0, i32 0), i64 %d }, section \"__DATA,__cfstring\"",symbol,withNull,withNull,numStrings,stringLen];
}


-(NSString*)writeNSConstantString:(NSString*)value
{
    NSString *stringSymbol=[NSString stringWithFormat:@"@const_string_%d",numStrings++];
    [self writeNSConstantString:value withSymbol:stringSymbol];
    return stringSymbol;
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
                      numMethods:(int)numMethods
{
    NSString *methodListRef= methodListRefSymbol ? [NSString stringWithFormat:@"bitcast ({ i32, i32, [%d x %%struct._objc_method] }* @\"%@\" to %%struct.__method_list_t*)",numMethods,methodListRefSymbol] : @"null";
    [self printLine:@"@\"%@\" = internal global %%struct._class_ro_t { i32 %d, i32 %d, i32 %d, i8* null, i8* getelementptr inbounds ([%d x i8],[%d x i8]* @\"%@\", i32 0, i32 0), %%struct.__method_list_t* %@, %%struct._objc_protocol_list* null, %%struct._ivar_list_t* null, i8* null, %%struct._prop_list_t* null }, section \"__DATA, __objc_const\", align 8",structLabel,p1,p2,p2,nameLenNull,nameLenNull,classNameSymbol,methodListRef];
}

-(void)writeClassDefWithLabel:(NSString*)classSymbol
                  structLabel:(NSString*)classStructSymbol
              superClassSymbol:(NSString*)superClassSymbol
              metaClassSymbol:(NSString*)metaClassSymbol
{
    [self printLine:@"@%@ = global %%struct._class_t { %%struct._class_t* @\"%@\", %%struct._class_t* @\"%@\", %%struct._objc_cache* @_objc_empty_cache, i8* (i8*, i8*)** @_objc_empty_vtable, %%struct._class_ro_t* @\"%@\" }, section \"__DATA, __objc_data\", align 8",classSymbol,metaClassSymbol,superClassSymbol,classStructSymbol];
}

-(void)writeClassWithName:(NSString*)aName superclassName:(NSString*)superclassName instanceMethodListRef:(NSString*)instanceMethodListSymbol numInstanceMethods:(int)numInstanceMethods
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
    
    
    [self generateCString:aName symbol:classNameSymbol type:@"__objc_classname"];

    
    [self writeClassStructWithLabel:metaClassStructSymbol className:classNameSymbol nameLen:nameLenNull param1:1 param2:40 methodListRef:nil numMethods:0];
    [self writeClassDefWithLabel:metaClassSymbol structLabel:metaClassStructSymbol superClassSymbol:superMetaClassSymbol metaClassSymbol:superClassSymbol];
    
    
    [self writeClassStructWithLabel:classStructSymbol className:classNameSymbol nameLen:nameLenNull param1:0 param2:8 methodListRef:instanceMethodListSymbol numMethods:numInstanceMethods];
    [self writeClassDefWithLabel:classSymbol structLabel:classStructSymbol superClassSymbol:superClassSymbol metaClassSymbol:metaClassSymbol];
    
    [self printLine:@"@\"\%@\" = internal global [1 x i8*] [i8* bitcast (%%struct._class_t* @\"%@\" to i8*)], section \"__DATA, __objc_classlist, regular, no_dead_strip\", align 8",classLabelSymbol, classSymbol];
    [self printLine:@"@llvm.used = appending global [2 x i8*] [i8* getelementptr inbounds ([%d x i8],[%d x i8]* @\"%@\", i32 0, i32 0), i8* bitcast ([1 x i8*]* @\"%@\" to i8*)], section \"llvm.metadata\"",nameLenNull,nameLenNull,classNameSymbol,classLabelSymbol];
    
}

-(void)writeCategoryNamed:(NSString*)categoryName ofClass:(NSString*)aName instanceMethodListRef:(NSString*)methodListRefSymbol numInstanceMethods:(int)numMethods
{
    NSString *categorySymbol=[NSString stringWithFormat:@"\\01lOBJC_$_CATEGORY_%@_$_%@",aName,categoryName];
    NSString *categoryLabelSymbol=[NSString stringWithFormat:@"\\01lOBJC_LABEL_CATEGORY_%@_$_%@",aName,categoryName];
    NSString *classRefSymbol = [self classSymbolForName:aName isMeta:NO];
    [self writeExternalReferenceWithName:classRefSymbol type:@"%struct._class_t"];
    NSString *categoryNameStringSymbol=[NSString stringWithFormat:@"\\01L_OBJC_CATEGORY_NAME_%@",categoryName];
    
    [self generateCString:categoryName symbol:categoryNameStringSymbol type:@"__objc_classname"];
   
    NSString *methodListRef= methodListRefSymbol ? [NSString stringWithFormat:@"bitcast ({ i32, i32, [%d x %%struct._objc_method] }* @\"%@\" to %%struct.__method_list_t*)",numMethods,methodListRefSymbol] : @"null";

    [self printLine:@"@\"%@\" = internal global %%struct._category_t { i8* getelementptr inbounds ([%d x i8],[%d x i8]* @\"%@\", i32 0, i32 0), %%struct._class_t* @\"%@\", %%struct.__method_list_t* %@, %%struct.__method_list_t* null, %%struct._objc_protocol_list* null, %%struct._prop_list_t* null }, section \"__DATA, __objc_const\", align 8",categorySymbol,[categoryName length]+1,[categoryName length]+1, categoryNameStringSymbol,classRefSymbol, methodListRef];
    [self printLine:@"@\"%@\" = internal global [1 x i8*] [i8* bitcast (%%struct._category_t* @\"%@\" to i8*)], section \"__DATA, __objc_catlist, regular, no_dead_strip\", align 8",categoryLabelSymbol, categorySymbol];


}

static NSString *typeCharToLLVMType( char typeChar ) {
    switch (typeChar) {
        case '?':
        case '@':
            return @"%id";
        case 'v':
            return @"void";
        case ':':
            return @"i8*";
        case 'i':
            return @"i32";
        case 'Q':
            return @"i32";
        default:
            [NSException raise:@"invalidtype" format:@"unrecognized type char '%c' when converting to LLVM types",typeChar];
            return @"";
    }
}


-(NSString*)typeToLLVMType:(char)typeChar
{
    return typeCharToLLVMType(typeChar);
}

-(NSString*)typeStringToLLVMMethodType:(NSString*)typeString
{
    NSMutableString *llvmType=[NSMutableString string];
    char typeBytes[1000];
    NSUInteger len=0;
    [typeString getBytes:typeBytes maxLength:900 usedLength:&len encoding:NSASCIIStringEncoding options:0 range:NSMakeRange(0, [typeString length]) remainingRange:NULL];
    int from,to=0;
    for (from=0;from<len;from++) {
        char cur=typeBytes[from];
        if ( !isdigit(cur)) {
            typeBytes[to++]=cur;
        }
    }
    typeBytes[to]=0;
    from=0;
    [llvmType appendString:typeCharToLLVMType(typeBytes[from++])];
    [llvmType appendString:@" ( "];
    while ( from < to) {
        [llvmType appendString:typeCharToLLVMType(typeBytes[from++])];
        if ( from < to ) {
            [llvmType appendString:@", "];
        }
    }
    [llvmType appendString:@")"];

    return llvmType;
}

-(NSString*)methodListForClass:(NSString*)className methodNames:(NSArray*)methodNames methodSymbols:(NSArray*)methodSymbols methodTypes:(NSArray*)typeStrings
{
    NSString *methodListSymbol=[@"\\01l_OBJC_$_INSTANCE_METHODS_" stringByAppendingString:className];
    NSMutableArray *nameSymbols=[NSMutableArray array];
    NSMutableArray *typeSymbols=[NSMutableArray array];
    int methodCount=(int)[methodSymbols count];
    
    for (int i=0;i<[methodNames count];i++) {
        NSString *methodTypeString=typeStrings[i];
        NSString *methodName=methodNames[i];
        NSString *nameSymbol=[NSString stringWithFormat:@"\\01L_OBJC_METH_VAR_NAME_%d",i];
        NSString *typeSymbol=[NSString stringWithFormat:@"\\01L_OBJC_METH_VAR_TYPE_%d",i];
        [self generateCString:methodName symbol:nameSymbol type:@"__objc_methname"];
        [self generateCString:methodTypeString symbol:typeSymbol type:@"__objc_methtype"];
        [nameSymbols addObject:nameSymbol];
        [typeSymbols addObject:typeSymbol];
    }
    
    
    [self printFormat:@"@\"%@\" = internal global { i32, i32, [%d x %%struct._objc_method] } { i32 24, i32 %d, [%d x %%struct._objc_method] [ ",methodListSymbol,methodCount,methodCount,methodCount];
    for (int i=0;i<methodCount;i++) {
        NSString *methodSymbol=methodSymbols[i];
        NSString *methodTypeString=typeStrings[i];
        NSString *methodName=methodNames[i];
        if (i!=0) {
            [self printFormat:@", "];
        }
        [self printFormat:@"%%struct._objc_method { i8* getelementptr inbounds ([%d x i8],[%d x i8]* @\"%@\", i32 0, i32 0), i8* getelementptr inbounds ([%d x i8],[%d x i8]* @\"%@\", i32 0, i32 0), i8* bitcast ( %@ * @\"\\01%@\" to i8*) } ",[methodName length]+1,[methodName length]+1, nameSymbols[i],[methodTypeString length]+1,[methodTypeString length]+1, typeSymbols[i],[self typeStringToLLVMMethodType:typeStrings[i]],methodSymbol];

    }
    [self printLine:@" ] }, section \"__DATA, __objc_const\", align 8"];
    return methodListSymbol;
}


-(void)flushSelectorReferences
{
    __block int num=0;
    [selectorReferences enumerateKeysAndObjectsUsingBlock:^(id selector, id sel_reference, BOOL *stop) {
        NSString *symbol=[NSString stringWithFormat:@"\\01L_OBJC_METH_VAR_NAME_REF_%d",num++];
        [self generateCString:selector  symbol:symbol type:@"__objc_methname"];
        [self printLine:@"@\"%@\" = internal externally_initialized global i8* getelementptr inbounds ([%d x i8],[%d x i8]* @\"%@\", i32 0, i32 0), section \"__DATA, __objc_selrefs, literal_pointers, no_dead_strip\"",sel_reference,[selector length]+1,[selector length]+1,symbol];
    }];
    
    
}

-(NSString*)stackAllocLocal:(NSString*)type
{
    numLocals++;
    NSString *localName=[NSString stringWithFormat:@"%%%d",numLocals];
    [self printLine:@"%@ = alloca %@, align 8",localName,type];
    return localName;
}

-(void)writeMethodHeaderWithName:(NSString*)methodFunctionName returnType:(NSString*)returnType additionalParametrs:(NSArray*)additionalParams
{
    [self printFormat:@"define internal %@ @\"\\01%@\"(%%id %%self, i8* %%_cmd",returnType, methodFunctionName];
    for ( NSString *param in additionalParams) {
        [self printFormat:@", %@",param];
    }
    [self printLine:@" ) uwtable ssp {"];
    [self printLine:@"%%1 = alloca %%id, align 8"];
    [self printLine:@"%%2 = alloca i8*, align 8"];
    [self printLine:@"store %%id %%self, %%id* %%1, align 8"];
    [self printLine:@"store i8* %%_cmd, i8** %%2, align 8"];
    numLocals=2;
    
}


-(NSString*)emitMsg:(NSString*)msgName receiver:(NSString*)receiverName  returnType:(NSString*)retType args:(NSArray*)args argTypes:(NSArray*)argTypes
{
    NSString *selectorRef=[self selectorForName:msgName];
    int selectorIndex=++numLocals;
    int returnIndex=-1;
    NSString *returnCode=@"";
    if ( ![retType isEqualToString:@"void"] ) {
        NSLog(@"non-void return");
        returnIndex=++numLocals;
        NSLog(@"returnIndex=%d",returnIndex);
        returnCode=[NSString stringWithFormat:@"%%%d = ",returnIndex];
    } else {
        NSLog(@"void return");
    }
    
    [self printLine:@"%%%d = load i8*, i8** @\"%@\", !invariant.load !4",selectorIndex,selectorRef];
    [self printFormat:@"%@call %@ bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %@ (%%id, i8* ",returnCode,retType,retType];
    for ( NSString *argType in argTypes) {
        [self printFormat:@", %@",argType];
    }
    [self printFormat:@")*)( %%id %@, i8* %%%d " ,receiverName,selectorIndex];
    for ( int i=0;i<[args count];i++) {
        [self printFormat:@", %@ %@ ",argTypes[i],args[i]];
    }
    [self printLine:@" )"];
    NSLog(@"returnIndex: %d",returnIndex);
    return returnIndex >= 0 ? [NSString stringWithFormat:@"%%%d",returnIndex] : nil;
}


-(NSString*)writeNSNumberLiteralForInt:(NSString*)theIntSymbolOrLiteral
{
    NSLog(@"writeNSNumberLiteralForInt: %@",theIntSymbolOrLiteral);
    numLocals++;
    int loadedClass=numLocals;
    numLocals++;
    int bitcastClass=numLocals;
    [self printLine:@"%%%d = load %%struct._class_t*,%%struct._class_t** @\"%@\", align 8",loadedClass,[self nsnumberclassref ]];
    [self printLine:@"%%%d = bitcast %%struct._class_t* %%%d to %%id",bitcastClass,loadedClass];
    NSLog(@"will emit message for number literal");
    NSString *retval=[self emitMsg:@"numberWithInt:" receiver:[NSString stringWithFormat:@"%%%d",bitcastClass] returnType:@"%id" args:@[ theIntSymbolOrLiteral ] argTypes:@[ @"i32"]];
    NSLog(@"did emit message for number literal, retval: %@",retval);
    return retval;
}

-(NSString*)writeMethodNamed:(NSString*)methodName className:(NSString*)className methodType:(NSString*)methodType additionalParametrs:(NSArray*)params methodBody:(void (^)(MPWLLVMAssemblyGenerator*  ))block
{
    NSString *methodFunctionName=[NSString stringWithFormat:@"-[%@ %@]",className,methodName];
    
    
    [self printLine:@""];
    [self writeMethodHeaderWithName:methodFunctionName returnType:methodType additionalParametrs:params];
    block( self );
    [self printLine:@"}"];
    [self printLine:@""];
    
    return methodFunctionName;
}

-(void)emitReturnVal:(NSString*)val type:(NSString*)type
{
    [self printLine:@"ret %@ %@",type,val];
}


-(NSString*)stringRef:(NSString*)ref
{
    NSString *stringArg=[NSString stringWithFormat:@"bitcast (%%struct.NSConstantString* %@ to %%id)",ref];
    return stringArg;
}


-(NSString*)callBlock:(NSString*)blockName args:(NSArray*)blockArgs types:(NSArray*)blockTypes returnType:(NSString*)returnType
{
    int blockLiteralLocal=++numLocals;
    int blockFnPtrLocal=++numLocals;
    int blockFnLocal=++numLocals;
    int blockFunCastToRightType=++numLocals;
    int retValLocal=++numLocals;
    
    [self printLine:@"%%%d = bitcast %%id %@ to %%struct.__block_literal_generic*" ,blockLiteralLocal,blockName] ;
    [self printLine:@"%%%d = getelementptr inbounds %%struct.__block_literal_generic,%%struct.__block_literal_generic* %%3, i64 0, i32 3",blockFnPtrLocal];
    [self printLine:@"%%%d = load i8*, i8** %%%d, align 8",blockFnLocal,blockFnPtrLocal];
    [self printFormat:@"%%%d = bitcast i8* %%%d to %%id (%%id",blockFunCastToRightType,blockFnLocal];
    for ( NSString *argType in blockTypes) {
        [self printFormat:@", %@",argType];
    }
    [self printLine:@")*",blockFunCastToRightType,blockFnLocal];
    [self printFormat:@"%%%d = tail call %%id %%%d(%%id %@ ",retValLocal,blockFunCastToRightType,blockName];
    for ( int i=0;i<[blockTypes count];i++) {
        [self printFormat:@", %@ %@",blockTypes[i],blockArgs[i]];
    }
    [self printLine:@" ) optsize",retValLocal,blockFunCastToRightType,blockName];
    return [NSString stringWithFormat:@"%%%d",retValLocal];
}

-(NSString*)writeBlockDescriptorWithType:(NSString*)blockType isLocal:(BOOL)isLocal
{
    NSString *str_symbol=[NSString stringWithFormat:@"@.block.str_%d",numStrings++];
    NSString *block_symbol=[NSString stringWithFormat:@"@__block_descriptor_%d",numBlocks++];
    int blockTypeLenInclNull=(int)[blockType length]+1;
    [self printLine:@"%@ = private unnamed_addr constant [%d x i8] c\"%@\\00\", align 1",
     str_symbol,blockTypeLenInclNull,blockType];
    [self printLine:@"%@ = internal constant { i64, i64, %@ i8*, i64 } { i64 0, i64 %d, %@ i8* getelementptr inbounds ([%d x i8],[%d x i8]* %@, i32 0, i32 0), i64 %d }",
     block_symbol,
     isLocal ? @" i8*, i8*," : @"",
     isLocal ? 40 : 32,
     isLocal ? @" i8* bitcast (void (i8*, i8*)* @__copy_helper_block_ to i8*), i8* bitcast (void (i8*)* @__destroy_helper_block_ to i8*)," : @"",
     blockTypeLenInclNull,
     blockTypeLenInclNull,
     str_symbol,
     isLocal ? 0 : 256];
    return block_symbol;
}


-(void)writeBlockName:(NSString*)blockBodyName returnType:(NSString*)returnType args:(NSArray*)args argTypes:(NSArray*)argTypes typeString:blockType blockBody:(void (^)(MPWLLVMAssemblyGenerator*  ))bodyBlock
{
    
    [self printFormat:@"define internal %@ @\"%@\"(i8* nocapture %%.block_descriptor ",returnType,blockBodyName];
    for (int i=0;i<[argTypes count];i++) {
        [self printFormat:@", %@ %@ ",argTypes[i],args[i]];
    }
    [self printLine:@" ) optsize ssp uwtable {"];
    numLocals=0;
    bodyBlock( self);
    [self printLine:@"}"];
}



-(void)writeBlockCopyHelper
{
    [self printLine:@"define internal void @__copy_helper_block_(i8*, i8* nocapture) nounwind {"];
    [self printLine:@"%%3 = getelementptr inbounds i8,i8* %%1, i64 32"];
    [self printLine:@"%%4 = bitcast i8* %%3 to %%id*"];
    [self printLine:@"%%5 = getelementptr inbounds i8,i8* %%0, i64 32"];
    [self printLine:@"%%6 = load %%id,%%id* %%4, align 8"];
    [self printLine:@"%%7 = bitcast %%id %%6 to i8*"];
    [self printLine:@"tail call void @_Block_object_assign(i8* %%5, i8* %%7, i32 3) nounwind"];
    [self printLine:@"ret void"];
    [self printLine:@"}"];
}


-(void)writeBlockDestroyHelper
{
    [self printLine:@"define internal void @__destroy_helper_block_(i8* nocapture) nounwind {"];
    [self printLine:@"%%2 = getelementptr inbounds i8,i8* %%0, i64 32"];
    [self printLine:@"%%3 = bitcast i8* %%2 to %%id*"];
    [self printLine:@"%%4 = load %%id,%%id* %%3, align 8"];
    [self printLine:@"%%5 = bitcast %%id %%4 to i8*"];
    [self printLine:@"tail call void @_Block_object_dispose(i8* %%5, i32 3) nounwind"];
    [self printLine:@"ret void"];
    [self printLine:@"}"];
    [self printLine:@""];
}


-(void)writeBlockSupport
{
    [self writeBlockCopyHelper];
    [self printLine:@""];
    [self writeBlockDestroyHelper];
    [self printLine:@"declare void @_Block_object_assign(i8*, i8*, i32)"];
    [self printLine:@"declare void @_Block_object_dispose(i8*, i32)"];
}


-(void)writeTrailer
{
    [self printLine:@" declare i8* @objc_msgSend(i8*, i8*, ...) nonlazybind"];

    [self printLine:@" !llvm.module.flags = !{!0, !1, !2, !3}"];
    [self printLine:@"!0 = !{i32 1, !\"Objective-C Version\", i32 2}"];
    [self printLine:@"!1 = !{i32 1, !\"Objective-C Image Info Version\", i32 0}"];
    [self printLine:@"!2 = !{i32 1, !\"Objective-C Image Info Section\", !\"__DATA, __objc_imageinfo, regular, no_dead_strip\"}"];
    [self printLine:@"!3 = !{i32 4, !\"Objective-C Garbage Collection\", i32 0}"];
    [self printLine:@"!4 = !{i32 1, !\"Objective-C Class Properties\", i32 64}"];
    [self printLine:@"!5 = !{i32 1, !\"PIC Level\", i32 2}"];
    [self printLine:@"!6 = !{!\"Apple LLVM version 8.0.0 (clang-800.0.38)\"}"];
    [self printLine:@"!7 = !{}"];


}

@end

@implementation MPWLLVMAssemblyGenerator(testSupport)


-(void)writeGlobalBlockDescriptor:(NSString*)blockBodyName type:(NSString*)blockType
{
    NSString *descriptor=[self writeBlockDescriptorWithType:blockType isLocal:NO];
    
    [self printLine:@"@__block_literal_global = internal constant { i8**, i32, i32, i8*, %%struct.__block_descriptor* } { i8** @_NSConcreteGlobalBlock, i32 1342177280, i32 0, i8* bitcast (%%id (i8*, %%id)* @\"%@\" to i8*), %%struct.__block_descriptor* bitcast ({ i64, i64, i8*, i64 }* %@ to %%struct.__block_descriptor*) }, align 8",
     blockBodyName,descriptor];
    [self printLine:@""];
}


-(NSString*)writeDescriptorForLocalBlock
{
    NSString *descriptor=[self writeBlockDescriptorWithType:@"v24@?0@\22NSString\228^c16" isLocal:YES];
    return descriptor;
}



-(NSString*)writeStringSplitter:(NSString*)className methodName:(NSString*)methodName methodType:(NSString*)typeString splitString:(NSString*)splitString
{
    NSString *splitStringSymbol=[@"@splitString" stringByAppendingString:[methodName substringToIndex:[methodName length]-1]];
    
    [self writeNSConstantString:splitString withSymbol:splitStringSymbol];
    
    [self printLine:@""];
    
    return [self writeMethodNamed:methodName className:className methodType:@"%id" additionalParametrs:@[@"%id %s"] methodBody:^(MPWLLVMAssemblyGenerator *generator) {
        NSString *retval=[self emitMsg:@"componentsSeparatedByString:" receiver:@"%s" returnType:@"%id" args:@[ [self stringRef:splitStringSymbol] ] argTypes:@[ @"%id"]];
        [self emitReturnVal:retval type:@"%id"];
    }];
}

-(NSString*)writeConstMethod1:(NSString*)className methodName:(NSString*)methodName methodType:(NSString*)typeString
{
    return [self writeMethodNamed:methodName className:className methodType:@"%id" additionalParametrs:@[@"%id %s", @"%id %delimiter"] methodBody:^(MPWLLVMAssemblyGenerator *generator) {
        
        NSString *retval=[generator emitMsg:@"componentsSeparatedByString:" receiver:@"%s" returnType:@"%id" args:@[ @"%delimiter"] argTypes:@[ @"%id"]];
        
        [self emitReturnVal:retval type:@"%id"];
    }];
}

-(NSString*)writeMakeNumberFromArg:(NSString*)className methodName:(NSString*)methodName
{
    
    return [self writeMethodNamed:methodName className:className methodType:@"%id" additionalParametrs:@[@"i32 %num"] methodBody:^(MPWLLVMAssemblyGenerator *generator) {
        [generator emitReturnVal:[generator writeNSNumberLiteralForInt:@"%num"] type:@"%id"];
    }];
    
}



-(NSString*)writeMakeNumber:(int)aNumber className:(NSString*)className methodName:(NSString*)methodName
{
    
    return [self writeMethodNamed:methodName className:className methodType:@"%id" additionalParametrs:@[ ] methodBody:^(MPWLLVMAssemblyGenerator *generator) {
        [generator emitReturnVal:[generator writeNSNumberLiteralForInt:[NSString stringWithFormat:@"%d",aNumber]] type:@"%id"];
    }];
    
}


-(NSString*)writeUseBlockClassName:(NSString*)className methodName:(NSString*)methodName
{
    
    return [self writeMethodNamed:methodName className:className methodType:@"%id" additionalParametrs:@[@"%id %s", @"%id %block"] methodBody:^(MPWLLVMAssemblyGenerator *generator) {
        NSString *blockCall=[self callBlock:@"%block" args:@[@"%s"] types:@[@"%id"] returnType:@"%id"];
        [generator emitReturnVal:blockCall type:@"%id"];
    }];
    
}



-(NSString*)writeCreateBlockClassName:(NSString*)className methodName:(NSString*)methodName userMessageName:(NSString*)userMessageName
{
    NSString *retval= [self writeMethodNamed:methodName className:className methodType:@"%id" additionalParametrs:@[@"%id %s"] methodBody:^(MPWLLVMAssemblyGenerator *generator) {
        
        NSString *returnValue=[self emitMsg:userMessageName receiver:@"%self" returnType:@"%id" args:@[ @"%s", @" bitcast ({ i8**, i32, i32, i8*, %struct.__block_descriptor* }* @__block_literal_global to %id (%id)*)"] argTypes:@[ @"%id", @"%id (%id)*"]];
        
        [generator emitReturnVal:returnValue type:@"%id"];
    }];
    NSString *blockBodyName=@"__24-[Hi noCaptureBlockUse:]_block_invoke";
    NSString *blockType=@"@16@?0@8";
    [self writeBlockName:blockBodyName returnType:@"%id" args:@[@"%s"] argTypes:@[@"%id"] typeString:blockType   blockBody:^(MPWLLVMAssemblyGenerator *generator) {
        NSString *retval=[self emitMsg:@"uppercaseString" receiver:@"%s" returnType:@"%id" args:@[] argTypes:@[]];
        [self emitReturnVal:retval type:@"%id"];
    }];
    [self writeGlobalBlockDescriptor:blockBodyName type:blockType];
    [self writeBlockSupport];
    return retval;
}

-(NSString*)writeBlockWithVariableCapture:(NSString*)name
{
    
    [self writeBlockName:name returnType:@"void" args:@[ @"%line", @"%stop" ] argTypes:@[@"%id", @"i8* nocapture"] typeString:@""   blockBody:^(MPWLLVMAssemblyGenerator *generator) {
        
        [self printLine:@"%%1 = getelementptr inbounds i8,i8*  %%.block_descriptor, i64 32"];
        [self printLine:@"%%2 = bitcast i8* %%1 to %%id*"];
        [self printLine:@"%%3 = load %%id,%%id* %%2, align 8, !tbaa !5"];
        numLocals=3;
        [self emitMsg:@"addObject:" receiver:@"%3" returnType:@"void" args:@[ @"%line"] argTypes:@[@"%id"]];
        [self printLine:@"ret void"];
    }];
    
    [self printLine:@""];
    NSString *descriptor=[self writeDescriptorForLocalBlock];
    return descriptor;
}

-(void)fetchBlockDescriptorPartAtIndex:(int)anIndex into:(NSString *)varIdentifier
{
    [self printFormat:@"%@ = getelementptr inbounds <{ i8*, i32, i32, i8*, %%struct.__block_descriptor*, %%id }>,<{ i8*, i32, i32, i8*, %%struct.__block_descriptor*, %%id }>* %%3, i64 0, i32 %d\n",varIdentifier,anIndex];
}

-(void)storeValue:(NSString *)value type:(NSString *)type into:(NSString *)location alignment:(int)align
{
    [self printFormat:@"store %@, %@* %@",value,type,type,location];
    if (align>0) {
        [self printFormat:@", align %d",align];
    }
    [self printLine:@""];
}


-(NSString*)writeCreateStackBlockWithVariableCaptureClassName:(NSString*)className methodName:(NSString*)methodName
{

    NSString *blockName=[NSString stringWithFormat:@"-[%@ %@]_block1",className,methodName];
    NSString *descriptorSymbol=[self writeBlockWithVariableCapture:blockName];
    NSString *refForNSMutableArray=[self classRefForClassName:@"NSMutableArray"];
    NSString *methodId= [self writeMethodNamed:methodName className:className methodType:@"%id" additionalParametrs:@[@"%id %s"] methodBody:^(MPWLLVMAssemblyGenerator *generator) {
        [self printLine:@"%%3 = alloca <{ i8*, i32, i32, i8*, %%struct.__block_descriptor*, %%id }>, align 8"];
        [self printLine:@"%%4 = load %%struct._class_t*,%%struct._class_t** @\"%@\", align 8",refForNSMutableArray];
        [self printLine:@"%%5 = bitcast %%struct._class_t* %%4 to %%id"];
        numLocals=5;
        NSString *arrayRef=[self emitMsg:@"array" receiver:@"%5" returnType:@"%id" args:@[] argTypes:@[]];

        
        [self fetchBlockDescriptorPartAtIndex:0 into:@"%8"];
//        [self printLine:@"store i8* bitcast (i8** @_NSConcreteStackBlock to i8*), i8** %%8, align 8"];
        [self fetchBlockDescriptorPartAtIndex:1 into:@"%9"];
        
//        [self printLine:@"store i32 -1040187392, i32* %%9, align 8"];
        [self fetchBlockDescriptorPartAtIndex:2 into:@"%10"];
//        [self printLine:@"store i32 0, i32* %%10, align 4"];
        [self fetchBlockDescriptorPartAtIndex:3 into:@"%11"];
        [self printLine:@"store i8* bitcast (void (i8*, %%id, i8*)* @\"%@\" to i8*), i8** %%11, align 8",blockName];
        [self fetchBlockDescriptorPartAtIndex:4 into:@"%12"];
        [self printLine:@"store %%struct.__block_descriptor* bitcast ({ i64, i64, i8*, i8*, i8*, i64 }* %@ to %%struct.__block_descriptor*), %%struct.__block_descriptor** %%12, align 8",descriptorSymbol];
        [self fetchBlockDescriptorPartAtIndex:5 into:@"%13"];
        [self printLine:@"store %%id %@, %%id* %%13, align 8, !tbaa !5",arrayRef];
        

        
        [self printLine:@"%%14 = bitcast <{ i8*, i32, i32, i8*, %%struct.__block_descriptor*, %%id }>* %%3 to void (%%id, i8*)*"];
        numLocals=14;
        [self emitMsg:@"enumerateLinesUsingBlock:" receiver:@"%s" returnType:@"void" args:@[ @"%14"] argTypes:@[@"void (%id, i8*)*" ]];
        
        [self printLine:@"ret %%id %@",arrayRef];
    }];
    
    
    [self writeBlockSupport];
    return methodId;
}


@end
