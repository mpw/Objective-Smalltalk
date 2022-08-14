//
//  MPWCodeGenerator.mm
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 2/26/13.
//
//


#import "MPWCodeGenerator.h"
#import "MPWLLVMAssemblyGenerator.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import "STCompiler.h"
#import "MPWMethodHeader.h"
#import "MPWExpression.h"
#import "MPWMessageExpression.h"
#import "MPWStatementList.h"
#import "MPWIdentifierExpression.h"
#import "MPWLiteralExpression.h"
#import "MPWMethodDescriptor.h"
#import "MPWClassDefinition.h"
#import "MPWScriptedMethod.h"
#import "MPWClassMirror.h"
#import "MPWMethodMirror.h"

@interface NSObject(dynamicallyGeneratedTestMessages)

-(NSArray*)components:(NSString*)aString splitInto:(NSString*)delimiter;
-(NSArray*)lines:(NSString*)aString;
-(NSArray*)words:(NSString*)aString;
-(NSArray*)splitThis:(NSString*)aString;
-(NSNumber*)makeNumber:(int)aNumber;
-(NSNumber*)three;
-(NSNumber*)four;
-(NSString*)onString:(NSString*)s execBlock:(NSString* (^)(NSString *line))block;
-(NSArray*)linesViaBlock:(NSString*)s;
-(NSNumber*)answer;
-(NSString*)answerString;
-(NSNumber*)fifteen;
-(NSNumber*)add5:arg;
-(NSString*)withoutFirst:(NSString*)arg;
-(NSNumber*)startsWithHello:(NSString*)arg;

@end

@interface MPWExpression(generation)
-(NSString*)generateOn:(MPWCodeGenerator*)generator;

@end


@implementation MPWCodeGenerator

objectAccessor(MPWLLVMAssemblyGenerator*, assemblyGenerator, setAssemblyGenerator )
objectAccessor(NSMutableDictionary*, stringMap, setStringMap )

+(instancetype)codegen
{
    return [[[self alloc] init] autorelease];
}

-(instancetype)initWithAssemblyGenerator:(MPWLLVMAssemblyGenerator*)newGenerator
{
    self=[super init];
    [self setAssemblyGenerator:newGenerator];
    [self setStringMap:[NSMutableDictionary dictionary]];
    return self;
}

-(instancetype)init
{
    return [self initWithAssemblyGenerator:[MPWLLVMAssemblyGenerator stream]];
}

+(NSString*)createTempDylibName
{
    const char *templatename="/tmp/testdylibXXXXXXXX";
    char *theTemplate = strdup(templatename);
    NSString *name=nil;
#ifndef __clang_analyzer__                  // the race is OK for unit tests
    if (    mktemp( theTemplate) ) {
        name=[NSString stringWithUTF8String:theTemplate];
    }
#endif
    free( theTemplate);
    return name;
}

-(NSString*)pathToLLC
{
    return @"/usr/local/bin/llc";
}

-(BOOL)assembleLLVM:(NSData*)llvmAssemblySource toFile:(NSString*)ofile_name
{
    NSString *asm_to_o=[NSString stringWithFormat:@"%@ -filetype=obj -o %@",[self pathToLLC],ofile_name];
    FILE *f=popen([asm_to_o fileSystemRepresentation], "w");
    fwrite([llvmAssemblySource bytes], 1, [llvmAssemblySource length], f);
    pclose(f);
    return YES;
}

-(void)linkOFileName:(NSString*)ofile_name toDylibName:(NSString*)dylib
{
    NSString *o_to_dylib=[NSString stringWithFormat:@"cc -dynamiclib  -F/Library/Frameworks/ -F/System/Library/Frameworks -o %@ %@ -framework MPWFoundation -framework Foundation -lSystem  2>/tmp/link-errors",dylib,ofile_name];
    int ok = system([o_to_dylib fileSystemRepresentation]);
    NSLog(@"did link '%@' -> %d",o_to_dylib,ok);
}

-(BOOL)assembleAndLoad:(NSData*)llvmAssemblySource
{
    NSString *name=[[self  class] createTempDylibName];
    NSString *ofile_name=[name stringByAppendingPathExtension:@"o"];
    NSString *dylib=[name stringByAppendingPathExtension:@"dylib"];

    [self assembleLLVM:llvmAssemblySource toFile:ofile_name];
    [self linkOFileName:ofile_name toDylibName:dylib];

    void *handle = dlopen( [dylib fileSystemRepresentation], RTLD_NOW);

    unlink([ofile_name fileSystemRepresentation]);
    unlink([dylib fileSystemRepresentation]);
    return handle!=NULL;

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
        case 'c':
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

-(NSString*)generateIntegerUnboxing:(NSString*)varToUnbox
{
    NSLog(@"generateIntegerUnboxing");
    NSString *retval =[assemblyGenerator emitMsg:@"integerValue"
                                        receiver:varToUnbox
                                      returnType:@"i32"
                                            args:@[]
                                        argTypes:@[]
                       ];
    return retval;
}

-(MPWMessageExpression*)resolveTypesInMessageSend:(MPWMessageExpression*)messageSend
{
    NSArray *classes=[MPWClassMirror allUsefulClasses];
    for ( MPWClassMirror *theClass in classes) {
        NSArray *methods=[theClass methodMirrors];
        for ( MPWMethodMirror *method in methods) {
            if ( [method selector] == [messageSend selector] ) {
                NSLog(@"found method %@ in class %@",method,theClass);
                const char *origTypestring=(const char*)[method typestring];
                long len=strlen(origTypestring);
                int dest=0;
                char *typestring=calloc( len+1,1);
                for (int i=0;i<len;i++) {
                    char ch=origTypestring[i];
                    if ( !isdigit(ch)) {
                        if ( ch=='Q') {
                            ch='i';
                        }
                        typestring[dest++]=ch;
                    }
                }
                typestring[dest]=0;
                [messageSend setArgtypes:typestring+3];
                [messageSend setReturnType:typestring[0]];
                return  messageSend;
            }
        }
    }
//
//    if ( [messageSend selector] == @selector(substringFromIndex:)) {
//        [messageSend setArgtypes:"i"];
//    }
    return  messageSend;
}


-(NSString*)generateMessageSend:(MPWMessageExpression*)messageSend
{
    NSMutableArray *messageArgumentNames = [NSMutableArray array];
    NSMutableArray *messageArgumentTypes = [NSMutableArray array];
    [self resolveTypesInMessageSend:messageSend];
    const char *typeString=[messageSend argtypes];
    long numArgs=[[messageSend args] count];
    NSAssert(numArgs < sizeof typeString - 2, @"too many arguments");
    for ( int i=0;i<numArgs;i++) {
        char argtype=typeString[i];
        NSLog(@"will add argument[%d]: %@",i,[[messageSend args] objectAtIndex:i]);
        id arg=[[messageSend args] objectAtIndex:i];
        id generatedTag=[arg generateOn:self];
        if ( argtype=='i'|| argtype=='I') {
            generatedTag=[self generateIntegerUnboxing:generatedTag];
        }
        NSLog(@"will add argument[%d]: %@ generated: %@",i,arg,generatedTag);
        [messageArgumentNames addObject:generatedTag ?: @"dummy"];
        NSString *llvmArgType=[self typeToLLVMType:argtype];
        [messageArgumentTypes addObject:llvmArgType];
    }
    char returnType=[messageSend returnType];
    NSString *llvmReturnType=[self typeToLLVMType:returnType];
    NSLog(@"Did generate args, will generate the message send");
    NSString *retval =[assemblyGenerator emitMsg:[messageSend messageName]
                      receiver:[[messageSend receiver] generateOn:self]
                    returnType:llvmReturnType
                          args:messageArgumentNames
                      argTypes:messageArgumentTypes
    ];
    NSLog(@"returnTyp: '%c'",returnType);
    if ( returnType == 'B' || returnType == 'i' || returnType == 'c' || returnType == 'Q' ) {
        retval = [assemblyGenerator writeNSNumberLiteralForInt:retval];
    }
    return retval;
}

-(NSString*)generateIdentifierRead:(MPWIdentifierExpression*)expression
{
    return [@"%" stringByAppendingString:[expression name]];
}

-(NSString*)generateLiteral:(MPWLiteralExpression*)literal
{
    id value=[literal theLiteral];
    NSLog(@"generate literal: %@: %@ of class %@",literal,value,[value class]);
    if ( [value isKindOfClass:[NSString class]] ) {
        NSLog(@"string literal");
        NSString *symbol= [stringGenerator writeNSConstantString:value];
        if ( symbol ) {
            [stringMap setObject:symbol forKey:value];
        }
        return [assemblyGenerator stringRef:[stringMap objectForKey:value]];
        
    } else if ( [value isKindOfClass:[NSNumber class]]) {
        NSLog(@"number literal, generate on assemblyGenerator: %@",[self assemblyGenerator]);
        
        return [[self assemblyGenerator] writeNSNumberLiteralForInt:[NSString stringWithFormat:@"%d",[value intValue]]];
    } else {
        @throw [NSException exceptionWithName:@"unsuppertedLiteral" reason:[NSString stringWithFormat:@"Unsupported Literal of class: %@",[value class]] userInfo:nil];
        return nil;
    }
}

-(NSString*)generateMethodWithHeader:(MPWMethodHeader*)header body:(MPWStatementList*)method forClass:(NSString*)classname
{
    NSString *objcReturnType = [[header typeString] substringToIndex:1];
    BOOL isVoidReturn=[objcReturnType isEqualToString:@"v"];
    NSString *llvmReturnType = [assemblyGenerator typeToLLVMType:[objcReturnType characterAtIndex:0]];
    
    
    
    
    NSMutableArray *allMethodArguments=[NSMutableArray array];
    for ( int i=0;i<[header numArguments];i++) {
        NSLog(@"will get typchar for arg[%d]",i);
        char typeChar =[[header argumentTypeAtIndex:i] objcTypeCode];
        NSLog(@"typeChar for arg[%d] = %c",i,typeChar);
        [allMethodArguments addObject:[NSString stringWithFormat:@"%@ %@",[assemblyGenerator typeToLLVMType:typeChar],[@"%" stringByAppendingString:[header argumentNameAtIndex:i]]]];
        NSLog(@"all args now: %@",allMethodArguments);
    }

    stringGenerator=assemblyGenerator;
    assemblyGenerator=nil;
    NSLog(@"will generatOn:");
    [method generateOn:self];
    NSLog(@"did generatOn:");
    assemblyGenerator=stringGenerator;
    stringGenerator=nil;
    NSLog(@"will write assembly");
    NSString *methodSymbol1 = [assemblyGenerator writeMethodNamed:[header methodName]
                                          className:classname
                                         methodType:llvmReturnType
                                additionalParametrs:allMethodArguments
                                         methodBody:^(MPWLLVMAssemblyGenerator *generator) {
                                             NSString *retval=[method generateOn:self];
        if ( isVoidReturn) {
            [assemblyGenerator emitReturnVal:@"" type:@"void"];
        } else {
                                                [assemblyGenerator emitReturnVal:retval type:@"%id"];
        }
                                         }];
    NSLog(@"did write assembly");
    return methodSymbol1;
}

-(MPWMethodDescriptor*)compileMethodForClass:(NSString*)className withHeader:(MPWMethodHeader*)header body:methodBody
{
    NSLog(@"will generate");
    NSString *methodSymbol1 = [self generateMethodWithHeader:header body:methodBody forClass:className];
    NSLog(@"did generate, fill out descriptor");
    MPWMethodDescriptor *descriptor=[[MPWMethodDescriptor new] autorelease];
    [descriptor setName:[header methodName]];
    [descriptor setObjcType:[header typeString]];
    [descriptor setSymbol:methodSymbol1];
    return descriptor;
    
}

-(MPWMethodDescriptor*)compileMethodForClass:(NSString*)className withHeaderString:(NSString*)methodHeaderString bodyText:(NSString*)methodBodyString
{
    STCompiler *compiler=[STCompiler compiler];
    MPWMethodHeader *header=[MPWMethodHeader methodHeaderWithString:methodHeaderString];
    id body=[compiler compile:methodBodyString];
    return [self compileMethodForClass:className withHeader:header body:body];
    
}

-(NSString*)generateMethodList:(NSArray*)methodDescriptors forClassName:(NSString*)classname
{
    NSArray *names=(NSArray*)[[methodDescriptors collect] name];
    NSArray *symbols=(NSArray*)[[methodDescriptors collect] symbol];
    NSArray *types=(NSArray*)[[methodDescriptors collect] objcType];
    
    return [assemblyGenerator methodListForClass:classname methodNames:names  methodSymbols:symbols methodTypes:types];
}

-(void)writeClassWithName:(NSString*)classname superclassName:(NSString*)superclassname instanceMethodDescriptors:(NSArray*)descriptors
{
    NSString *methodListRef=[self generateMethodList:descriptors forClassName:classname];
    [assemblyGenerator writeClassWithName:classname superclassName:superclassname instanceMethodListRef:methodListRef  numInstanceMethods:(int)[descriptors count]];
}

-(void)generateClass:(MPWClassDefinition*)classDef
{
    NSString *classname=[classDef name];
    NSString *methodListRef=nil;
    NSMutableArray *methodRefs=[NSMutableArray array];
    NSLog(@"generate class: %@ superclass: %@ with %d method",classDef.className,classDef.superclassNameToUse,(int)[[classDef methods] count]);
    for ( MPWScriptedMethod *method in [classDef methods] ) {
        NSLog(@"will generate: %@ body: %p/%@",[[method header] methodName],[method methodBody],[method methodBody]);
        MPWMethodDescriptor *ref=[self compileMethodForClass:classname withHeader:[method header] body:[method methodBody]];
        NSLog(@"did generate: %@",[[method header] methodName]);
        if (ref) {
            [methodRefs addObject:ref];
        } else {
            [NSException raise:@"compilefailure" format:@"method ref nil"];
        }
    }
    
    if ( [methodRefs count]>0) {
        methodListRef=[self generateMethodList:methodRefs forClassName:classname];
    }
    [assemblyGenerator writeClassWithName:classname superclassName:[classDef superclassNameToUse] instanceMethodListRef:methodListRef  numInstanceMethods:(int)[methodRefs count]];
}


-(void)flush
{
    [assemblyGenerator flushSelectorReferences];
    [assemblyGenerator writeTrailer];
    [assemblyGenerator flush];
}

@end

@implementation MPWMessageExpression(generation)

-(NSString*)generateOn:(MPWCodeGenerator*)generator
{
    NSLog(@"will generate message expression: %@",self);
    id retval = [generator generateMessageSend:self];
    NSLog(@"did generate message expression: %@",self);

    return retval;
}

@end

@implementation MPWStatementList(generation)

-(NSString*)generateOn:(MPWCodeGenerator*)generator
{
    NSString *result=nil;
    NSLog(@"write statement list with %ld entries",(long)[[self statements] count]);
    for ( MPWExpression *expression in [self statements]) {
        NSLog(@"will generate: %@",expression);
        result = [expression generateOn:generator];
        NSLog(@"did generate: %@",expression);
    }
    return result;
}

@end


@implementation MPWIdentifierExpression(generation)

-(NSString*)generateOn:(MPWCodeGenerator*)generator
{
    return [generator generateIdentifierRead:self];
}

@end


@implementation MPWLiteralExpression(generation)

-(NSString*)generateOn:(MPWCodeGenerator*)generator
{
    return [generator generateLiteral:self];
}

@end

@implementation MPWClassDefinition(generation)

-(NSString*)generateOn:(MPWCodeGenerator*)generator
{
    [generator generateClass:self];
    return nil;
}

@end



#import <MPWFoundation/MPWFoundation.h>

@interface MPWCodeGeneratorTestClass : NSObject {}  @end

@implementation MPWCodeGeneratorTestClass




@end


@implementation MPWCodeGenerator(testing)

+(NSString*)anotherTestClassName
{
    static int classNo=0;
    return [NSString stringWithFormat:@"__MPWCodeGenerator_CodeGenTestClass_%d",++classNo];
}

+(void)testStaticEmptyClassDefine
{
    static BOOL wasRunOnce=NO;          // bit of a hack, but I want these tests to be automagically mirrored by subclass
    if ( !wasRunOnce) {
        MPWCodeGenerator *codegen=[self codegen];
        NSString *classname=@"EmptyCodeGenTestClass01";
        NSData *source=[[NSBundle bundleForClass:self] resourceWithName:@"empty-class" type:@"llvm-templateasm"];
        EXPECTNIL(NSClassFromString(classname), @"test class should not exist before load");
        EXPECTNOTNIL(source, @"should have source data");
        EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
        
        Class loadedClass =NSClassFromString(classname);
        EXPECTNOTNIL(loadedClass, @"test class should  exist after load");
        id instance=[[loadedClass new] autorelease];
        EXPECTNOTNIL(instance, @"test class should be able to create instances");
        wasRunOnce=YES;
    }
}

+(NSData*)resultOfFlushing:(MPWLLVMAssemblyGenerator *)gen
{
    [gen flushSelectorReferences];
    [gen writeTrailer];
    [gen flush];
    return (NSData*)[gen target];
}

+(void)testDefineEmptyClassDynamically
{
    // takes around 24 ms (real) total
    //    NSLog(@"start testDefineEmptyClassDynamically");
    MPWCodeGenerator *codegen=[self codegen];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
   
    NSString *classname=[self anotherTestClassName];
    EXPECTNIL(NSClassFromString(classname), @"test class should not exist before load");

    [gen writeHeaderWithName:@"testModule"];
    [gen writeClassWithName:classname superclassName:@"NSObject" instanceMethodListRef:nil numInstanceMethods:0];
    NSData *source=[self resultOfFlushing:gen];
    [source writeToFile:@"/tmp/smalltalkmanualemptyclass.s" atomically:YES];

    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    Class loadedClass =NSClassFromString(classname);
    EXPECTNOTNIL(loadedClass, @"test class should exist after load");
    id instance=[[loadedClass new] autorelease];
    EXPECTNOTNIL(instance, @"test class should be able to create instances");
    //    NSLog(@"end testDefineEmptyClassDynamically");
}

+(void)testDefineClassWithOneMethodDynamically
{
    // takes around 24 ms (real) total
    //    NSLog(@"start testDefineEmptyClassDynamically");
    MPWCodeGenerator *codegen=[self codegen];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
    
    NSString *classname=[self anotherTestClassName];
    [gen writeHeaderWithName:@"testModule"];
    NSString *methodName=@"components:splitInto:";
    NSString *methodType=@"@32@0:8@16@24";
    
    NSString *methodSymbol=[gen writeConstMethod1:classname methodName:methodName methodType:methodType];
    
    NSString *methodListRef= [gen methodListForClass:classname methodNames:@[ methodName]  methodSymbols:@[ methodSymbol ] methodTypes:@[ methodType]];

    
    [gen writeClassWithName:classname superclassName:@"NSObject" instanceMethodListRef:methodListRef  numInstanceMethods:1
];
    NSData *source=[self resultOfFlushing:gen];

//    [source writeToFile:@"/tmp/onemethodclass.s" atomically:YES];
    EXPECTNIL(NSClassFromString(classname), @"test class should not exist before load");
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    Class loadedClass =NSClassFromString(classname);
    EXPECTNOTNIL(loadedClass, @"test class should exist after load");
    id instance=[[loadedClass new] autorelease];
    EXPECTTRUE([instance respondsToSelector:@selector(components:splitInto:)], @"responds to 'components:splitInto:");
    NSArray *splitResult=[instance components:@"Hi there" splitInto:@" "];
    IDEXPECT(splitResult, (@[@"Hi", @"there"]), @"loaded method");
    //    NSLog(@"end testDefineEmptyClassDynamically");
}

+(void)testDefineClassWithThreeMethodsDynamically
{
    // takes around 24 ms (real) total
    //    NSLog(@"start testDefineEmptyClassDynamically");
    MPWCodeGenerator *codegen=[self codegen];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
    
    NSString *classname=[self anotherTestClassName];
    [gen writeHeaderWithName:@"testModule"];
    NSString *methodName1=@"components:splitInto:";
    NSString *methodType1=@"@32@0:8@16@24";
    NSString *methodName2=@"lines:";
    NSString *methodType2=@"@32@0:8@16";
    NSString *methodName3=@"words:";
    NSString *methodType3=@"@32@0:8@16";
    
    //    NSString *methodListRef=[gen writeConstMethodAndMethodList:classname methodName:methodName typeString:methodType];
    NSString *methodSymbol1=[gen writeConstMethod1:classname methodName:methodName1 methodType:methodType1];
    NSString *methodSymbol2=[gen writeStringSplitter:classname methodName:methodName2 methodType:methodType2 splitString:@"\n"];
    NSString *methodSymbol3=[gen writeStringSplitter:classname methodName:methodName3 methodType:methodType3 splitString:@" "];
    
    NSString *methodListRef= [gen methodListForClass:classname methodNames:@[ methodName1, methodName2, methodName3]  methodSymbols:@[ methodSymbol1, methodSymbol2, methodSymbol3 ] methodTypes:@[ methodType1, methodType2, methodType3]];
    
    
    [gen writeClassWithName:classname superclassName:@"NSObject" instanceMethodListRef:methodListRef numInstanceMethods:3];
    
    NSData *source=[self resultOfFlushing:gen];
//    [source writeToFile:@"/tmp/threemethodclass.s" atomically:YES];
    EXPECTNIL(NSClassFromString(classname), @"test class should not exist before load");
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    EXPECTNOTNIL(NSClassFromString(classname), @"test class should exist after load");
    id instance=[[NSClassFromString(classname) new] autorelease];
    EXPECTTRUE([instance respondsToSelector:@selector(components:splitInto:)], @"responds to 'components:splitInto:");
    EXPECTTRUE([instance respondsToSelector:@selector(lines:)], @"responds to 'lines:'");
    NSArray *splitResult=[instance components:@"Hi there" splitInto:@" "];
    IDEXPECT(splitResult, (@[@"Hi", @"there"]), @"1st loaded method");
    NSArray *splitResult1=[instance lines:@"Hi\nthere"];
    IDEXPECT(splitResult1, (@[@"Hi", @"there"]), @"2nd loaded method");
    NSArray *splitResult2=[instance words:@"Hello world!"];
    IDEXPECT(splitResult2, (@[@"Hello", @"world!"]), @"3rd loaded method");
    //    NSLog(@"end testDefineEmptyClassDynamically");
}



+(void)testStringsWithDifferentLengths
{
    // takes around 24 ms (real) total
    //    NSLog(@"start testDefineEmptyClassDynamically");
    MPWCodeGenerator *codegen=[self codegen];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
    
    NSString *classname=[self anotherTestClassName];
    [gen writeHeaderWithName:@"testModule"];
    NSString *methodName=@"splitThis:";
    NSString *methodType=@"@32@0:8@16";
    
    //    NSString *methodListRef=[gen writeConstMethodAndMethodList:classname methodName:methodName typeString:methodType];
    NSString *methodSymbol=[gen writeStringSplitter:classname methodName:methodName methodType:methodType splitString:@"this"];
    
    NSString *methodListRef= [gen methodListForClass:classname methodNames:@[ methodName]  methodSymbols:@[ methodSymbol ] methodTypes:@[ methodType ]];
    
    
    [gen writeClassWithName:classname superclassName:@"NSObject" instanceMethodListRef:methodListRef numInstanceMethods:1];
    
    NSData *source=[self resultOfFlushing:gen];
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");


    id instance=[[NSClassFromString(classname) new] autorelease];
 
    NSArray *splitResult2=[instance splitThis:@"Hello this is cool!"];
    IDEXPECT(splitResult2, (@[@"Hello ", @" is cool!"]), @"string split by 'this'");
    //    NSLog(@"end testDefineEmptyClassDynamically");
}

+(void)testCreateNSNumber
{
    // takes around 24 ms (real) total
    //    NSLog(@"start testDefineEmptyClassDynamically");
    MPWCodeGenerator *codegen=[self codegen];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
    
    NSString *classname=[self anotherTestClassName];
    [gen writeHeaderWithName:@"testModule"];
    NSString *methodName=@"makeNumber:";
    NSString *methodType=@"@32@0:8i16";
    
    //    NSString *methodListRef=[gen writeConstMethodAndMethodList:classname methodName:methodName typeString:methodType];
    NSString *methodSymbol=[gen writeMakeNumberFromArg:classname methodName:methodName];
    
    NSString *methodListRef= [gen methodListForClass:classname methodNames:@[ methodName]  methodSymbols:@[ methodSymbol ] methodTypes:@[ methodType ]];
    
    
    [gen writeClassWithName:classname superclassName:@"NSObject" instanceMethodListRef:methodListRef numInstanceMethods:1];
    
    NSData *source=[self resultOfFlushing:gen];
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    
    
    id instance=[[NSClassFromString(classname) new] autorelease];
    
    NSNumber *num1=[instance makeNumber:42];
    IDEXPECT(num1, @(42), @"number from int");
    //    NSLog(@"end testDefineEmptyClassDynamically");
}


+(void)testCreateConstantNSNumber
{
    // takes around 24 ms (real) total
    //    NSLog(@"start testDefineEmptyClassDynamically");
    MPWCodeGenerator *codegen=[self codegen];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
    
    NSString *classname=[self anotherTestClassName];
    [gen writeHeaderWithName:@"testModule"];
    NSString *methodName1=@"three";
    NSString *methodName2=@"four";
    NSString *methodType=@"@32@0:";
    
    //    NSString *methodListRef=[gen writeConstMethodAndMethodList:classname methodName:methodName typeString:methodType];
    NSString *methodSymbol1=[gen writeMakeNumber:3 className:classname methodName:methodName1];
    NSString *methodSymbol2=[gen writeMakeNumber:4 className:classname methodName:methodName2];
    
    NSString *methodListRef= [gen methodListForClass:classname methodNames:@[ methodName1,methodName2]  methodSymbols:@[ methodSymbol1, methodSymbol2 ] methodTypes:@[ methodType, methodType ]];
    
    
    [gen writeClassWithName:classname superclassName:@"NSObject" instanceMethodListRef:methodListRef numInstanceMethods:2];
    
    NSData *source=[self resultOfFlushing:gen];
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    
    
    id instance=[[NSClassFromString(classname) new] autorelease];
    
    NSNumber *three=[instance three];
    IDEXPECT(three, @(3), @"number from int");
    NSNumber *four=[instance four];
    IDEXPECT(four, @(4), @"number from int");
    //    NSLog(@"end testDefineEmptyClassDynamically");
}


+(void)testCreateCategory
{
    // takes around 24 ms (real) total
    //    NSLog(@"start testDefineEmptyClassDynamically");
    MPWCodeGenerator *codegen=[self codegen];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
    
    NSString *classname=@"NSObject";
    [gen writeHeaderWithName:@"testModule"];
    NSString *methodName1=@"three";
    NSString *methodType=@"@32@0:";
    
    NSString *methodSymbol1=[gen writeMakeNumber:3 className:classname methodName:methodName1];
    
    NSString *methodListRef= [gen methodListForClass:classname methodNames:@[ methodName1]  methodSymbols:@[ methodSymbol1 ] methodTypes:@[ methodType ]];
    
    
    [gen writeCategoryNamed:@"randomTestCategory" ofClass:@"NSObject" instanceMethodListRef:methodListRef numInstanceMethods:1];
    
    NSData *source=[self resultOfFlushing:gen];
//    [source writeToFile:@"/tmp/onemethodcategory.s" atomically:YES];

    id instance=[[NSClassFromString(classname) new] autorelease];
    
    EXPECTFALSE([instance respondsToSelector:@selector(three)], @"responds tp selector three before loading class");
    
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    
    
    EXPECTTRUE([instance respondsToSelector:@selector(three)], @"responds tp selector three after loading class");
    
    NSNumber *three=[instance three];
    IDEXPECT(three, @(3), @"number from int");
    //    NSLog(@"end testDefineEmptyClassDynamically");
}

+(void)testGenerateBlockUse
{
    // takes around 24 ms (real) total
    //    NSLog(@"start testDefineEmptyClassDynamically");
    MPWCodeGenerator *codegen=[self codegen];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
    
    NSString *classname=[self anotherTestClassName];
    [gen writeHeaderWithName:@"testModule"];
    NSString *methodName=@"onString:execBlock:";
    NSString *methodType=@"@32@0:8@16@24";  //  @"@32@0:8@16@?24"
    
    NSString *methodSymbol=[gen writeUseBlockClassName:classname methodName:methodName];
    
    NSString *methodListRef= [gen methodListForClass:classname methodNames:@[ methodName]  methodSymbols:@[ methodSymbol ] methodTypes:@[ methodType ]];

    
    [gen writeClassWithName:classname superclassName:@"NSObject" instanceMethodListRef:methodListRef numInstanceMethods:1];
    
    NSData *source=[self resultOfFlushing:gen];
//    [source writeToFile:@"/tmp/blockuse.s" atomically:YES];
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    
    
    id instance=[[NSClassFromString(classname) new] autorelease];
    
    NSString *res1=[instance onString:@"Hello" execBlock:^NSString *(NSString *line) {
        return [line stringByAppendingString:@" World!"];
    }];
    IDEXPECT(res1, @"Hello World!", @"block execution 1");
    NSString *res2=[instance onString:@"Hello" execBlock:^NSString *(NSString *line) {
        return [line uppercaseString];
    }];
    IDEXPECT(res2, @"HELLO", @"block execution2 ");
}

+(void)testGenerateGlobalBlockCreate
{
    // takes around 24 ms (real) total
    //    NSLog(@"start testDefineEmptyClassDynamically");
    MPWCodeGenerator *codegen=[self codegen];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
    
    NSString *classname=[self anotherTestClassName];
    [gen writeHeaderWithName:@"testModule"];
    NSString *methodName1=@"linesViaBlock:";
    NSString *methodType1=@"@32@0:8@16";
    NSString *methodName2=@"onString:execBlock:";
    NSString *methodType2=@"@32@0:8@16@24";  //  @"@32@0:8@16@?24"
    
    NSString *methodSymbol1=[gen writeCreateBlockClassName:classname methodName:methodName1 userMessageName:methodName2];
    NSString *methodSymbol2=[gen writeUseBlockClassName:classname methodName:methodName2];

    NSString *methodListRef= [gen methodListForClass:classname methodNames:@[ methodName1, methodName2]  methodSymbols:@[ methodSymbol1, methodSymbol2 ] methodTypes:@[ methodType1, methodType2 ]];
    
    
    [gen writeClassWithName:classname superclassName:@"NSObject" instanceMethodListRef:methodListRef numInstanceMethods:2];
    
    NSData *source=[self resultOfFlushing:gen];
//    [source writeToFile:@"/tmp/blockcreate.s" atomically:YES];
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    
    
    id instance=[[NSClassFromString(classname) new] autorelease];
    
    NSArray *res1=[instance linesViaBlock:@"Hello"];
    IDEXPECT(res1, @"HELLO", @"block execution 1");
}

+(void)testGenerateStackBlockWithVariableCapture
{
    // takes around 24 ms (real) total
    //    NSLog(@"start testDefineEmptyClassDynamically");
    MPWCodeGenerator *codegen=[self codegen];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
    
    NSString *classname=[self anotherTestClassName];
    [gen writeHeaderWithName:@"testModule"];
    NSString *methodName1=@"onString:execBlock:";
    NSString *methodType1=@"@32@0:8@16@24";  //  @"@32@0:8@16@?24"
    NSString *methodName2=@"linesViaBlock:";
    NSString *methodType2=@"@32@0:8@16";
    
    NSString *methodSymbol1=[gen writeUseBlockClassName:classname methodName:methodName1];
    NSString *methodSymbol2=[gen writeCreateStackBlockWithVariableCaptureClassName:classname methodName:methodName2];
    
    NSString *methodListRef= [gen methodListForClass:classname methodNames:@[ methodName1, methodName2]  methodSymbols:@[ methodSymbol1, methodSymbol2 ] methodTypes:@[ methodType1, methodType2 ]];
    
    
    [gen writeClassWithName:classname superclassName:@"NSObject" instanceMethodListRef:methodListRef numInstanceMethods:2];
    
    NSData *source=[self resultOfFlushing:gen];
//    [source writeToFile:@"/tmp/blockcreatecapture.s" atomically:YES];
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    NSLog(@"after codegen and load");
    
    id instance=[[NSClassFromString(classname) new] autorelease];
    
    NSArray *res1=[instance linesViaBlock:@"Hello\nthese\nare\nsome\nlines"];
    IDEXPECT(res1, (@[ @"Hello", @"these", @"are", @"some", @"lines"]), @"block execution 1");
}

+(void)testDefineClassWithOneSimpleSmalltalkMethod
{
    NSString *classname=[self anotherTestClassName];
    MPWCodeGenerator *codegen=[self codegen];
    [[codegen assemblyGenerator] writeHeaderWithName:@"testModule"];
    
    MPWMethodDescriptor *methodDescriptor1 = [codegen compileMethodForClass:classname
                                                                 withHeaderString:@"components:source splitInto:separator"
                                                                       bodyText:@"source componentsSeparatedByString:separator."];
    
    [codegen writeClassWithName:classname
                 superclassName:@"NSObject"
      instanceMethodDescriptors:@[ methodDescriptor1 ]];
    
    [codegen flush];
    NSData *source=(NSData*)[[codegen assemblyGenerator] target];  // FIXME
//    [source writeToFile:@"/tmp/fromsmalltalk.s" atomically:YES];
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    
    
    id instance=[[NSClassFromString(classname) new] autorelease];
    
    EXPECTTRUE([instance respondsToSelector:@selector(components:splitInto:)], @"responds to 'components:splitInto:");
    NSArray *splitResult=[instance components:@"Hi there" splitInto:@" "];
    IDEXPECT(splitResult, (@[@"Hi", @"there"]), @"loaded method");
    
}

+(void)testSmalltalkLiterals
{
    NSString *classname=[self anotherTestClassName];
    MPWCodeGenerator *codegen=[self codegen];
    [[codegen assemblyGenerator] writeHeaderWithName:@"testModule"];
    
    MPWMethodDescriptor *methodDescriptor1 = [codegen compileMethodForClass:classname
                                                                 withHeaderString:@"answer"
                                                                       bodyText:@"42."];
    MPWMethodDescriptor *methodDescriptor2 = [codegen compileMethodForClass:classname
                                                                 withHeaderString:@"answerString"
                                                                       bodyText:@"'The answer'."];
    
    [codegen writeClassWithName:classname
                 superclassName:@"NSObject"
      instanceMethodDescriptors:@[ methodDescriptor1 , methodDescriptor2 ]];
    
    [codegen flush];
    NSData *source=(NSData*)[[codegen assemblyGenerator] target];  // FIXME
//    [source writeToFile:@"/tmp/smalltalkliterals.s" atomically:YES];
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    
    
    id instance=[[NSClassFromString(classname) new] autorelease];
    
    IDEXPECT([instance answer], @(42), @"nsnumber literal");
    IDEXPECT([instance answerString], @"The answer", @"string literal");
    
}

+instanceOfGeneratedClassDefinedByParametrizedSourceString:(NSString*)sourceCodeTemplates
{
    MPWCodeGenerator *codegen=[self codegen];
    STCompiler *compiler=[STCompiler compiler];
    NSString *classname=[self anotherTestClassName];
    NSString *classDefString=[NSString stringWithFormat:sourceCodeTemplates, classname];
    MPWClassDefinition *classDef=[compiler parseClassDefinitionFromString:classDefString];
    EXPECTNIL(NSClassFromString(classname), @"shouldn't exist");
    [[codegen assemblyGenerator] writeHeaderWithName:@"testModule"];
    [classDef generateOn:codegen];
    [codegen flush];
    NSData *source=(NSData*)[[codegen assemblyGenerator] target];  // FIXME, cast
    NSString *filename=[NSString stringWithFormat:@"/tmp/%@.s",classname];
    NSLog(@"classDefString: %@",classDefString);
    [source writeToFile:filename atomically:YES];
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    id a=[[NSClassFromString(classname) new] autorelease];
    EXPECTNOTNIL(a, @"should be able to instantiate new class");
    IDEXPECT([a className],classname,@"should be instance of class I created");
    return a;
}


+(void)testCreateEmptyClassUsingClassSyntax
{
    [self instanceOfGeneratedClassDefinedByParametrizedSourceString:@"class %@  { } "];
}

+(void)testCreateClassWithMethodReturningConstantUsingClassSyntax
{
    id a=[self instanceOfGeneratedClassDefinedByParametrizedSourceString:@"class %@  { -fifteen { 15. } } "];
    id result=[a fifteen];
    IDEXPECT(result,@(15),@"constant 15");
}

+(void)testCreateClassWithMethodWithAMessageSendUsingClassSyntax
{
    id a=[self instanceOfGeneratedClassDefinedByParametrizedSourceString:@"class %@  { -add5:arg { arg+5. } } "];
    id result=[a add5:@(7)];
    IDEXPECT(result,@(12),@"computed 12");
}

+(void)testUseOfIntegerParameterInMessageSend
{
    id a=[self instanceOfGeneratedClassDefinedByParametrizedSourceString:@"class %@  { -withoutFirst:arg { arg substringFromIndex:1. } } "];
    id result=[a withoutFirst:@"Hello"];
    IDEXPECT(result,@"ello",@"Hello without first character");
}

+(void)testUseOfAnotherIntegerParameterInMessageSend
{
    id a=[self instanceOfGeneratedClassDefinedByParametrizedSourceString:@"class %@  { -withoutFirst:arg { arg substringToIndex:2. } } "];
    id result=[a withoutFirst:@"Hello"];
    IDEXPECT(result,@"He",@"Hello up to 2nd char");
}

+(void)testBooleanReturnFromMessage
{
    id a=[self instanceOfGeneratedClassDefinedByParametrizedSourceString:@"class %@  { -startsWithHello:arg {  arg hasPrefix:'Hello'. } }"];
    id result1=[a startsWithHello:@"Hello World"];
    IDEXPECT(result1,@(1),@"did contain hello");
    id result2=[a startsWithHello:@"Bye World"];
    IDEXPECT(result2,@(0),@"did not start with  hello");
}



+(void)testCreateFilterClass
{
    MPWFilter* a=[self instanceOfGeneratedClassDefinedByParametrizedSourceString:@"class %@ : MPWFilter { -<void>writeObject:arg { self forward:arg uppercaseString. } } "];
    [a writeObject:@"hello world"];
    IDEXPECT([a firstObject],@"HELLO WORLD",@"stream processing result");
}

+(void)testCreateFilterClassWithFilterSyntax
{
    MPWFilter* a=[self instanceOfGeneratedClassDefinedByParametrizedSourceString:@"filter %@  |{  self forward:object uppercaseString. } "];
    [a writeObject:@"hello cruel world"];
    IDEXPECT([a firstObject],@"HELLO CRUEL WORLD",@"stream processing result");
}

+testSelectors
{
    return @[
             @"testStaticEmptyClassDefine",
             @"testDefineEmptyClassDynamically",
             @"testDefineClassWithOneMethodDynamically",
             @"testDefineClassWithThreeMethodsDynamically",
             @"testStringsWithDifferentLengths",
             @"testCreateNSNumber",
             @"testCreateConstantNSNumber",
             @"testCreateCategory",
             @"testGenerateBlockUse",
             @"testGenerateGlobalBlockCreate",
//             @"testGenerateStackBlockWithVariableCapture",  currently fails
             @"testDefineClassWithOneSimpleSmalltalkMethod",
             @"testSmalltalkLiterals",
             @"testCreateEmptyClassUsingClassSyntax",
             @"testCreateClassWithMethodReturningConstantUsingClassSyntax",
             @"testCreateClassWithMethodWithAMessageSendUsingClassSyntax",
             @"testUseOfIntegerParameterInMessageSend",
             @"testUseOfAnotherIntegerParameterInMessageSend",
             @"testBooleanReturnFromMessage",
             @"testCreateFilterClass",
             @"testCreateFilterClassWithFilterSyntax",
              ];
}

@end
