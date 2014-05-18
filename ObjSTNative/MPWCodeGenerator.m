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
#import "MPWStCompiler.h"
#import "MPWMethodHeader.h"
#import "MPWExpression.h"
#import "MPWMessageExpression.h"
#import "MPWStatementList.h"

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

@end



@implementation MPWCodeGenerator

objectAccessor(MPWLLVMAssemblyGenerator, assemblyGenerator, setAssemblyGenerator )

+(instancetype)codegen
{
    return [[[self alloc] init] autorelease];
}

-(instancetype)initWithAssemblyGenerator:(MPWLLVMAssemblyGenerator*)newGenerator
{
    self=[super init];
    [self setAssemblyGenerator:newGenerator];
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
    if (    mktemp( theTemplate) ) {
        name=[NSString stringWithUTF8String:theTemplate];
    }
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
    NSString *o_to_dylib=[NSString stringWithFormat:@"ld  -macosx_version_min 10.8 -dylib -o %@ %@ -framework Foundation -lSystem",dylib,ofile_name];
    system([o_to_dylib fileSystemRepresentation]);
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

-(NSString*)generateMessageSend:(MPWMessageExpression*)messageSend
{
    NSMutableArray *messageArgumentNames = [NSMutableArray array];
    NSMutableArray *messageArgumentTypes = [NSMutableArray array];
    for ( int i=0;i<[[messageSend args] count];i++) {
        [messageArgumentNames addObject:[@"%" stringByAppendingString:[[[messageSend args] objectAtIndex:i] name]]];
        [messageArgumentTypes addObject:@"%id"];
    }
    
    NSString *retval =[assemblyGenerator emitMsg:[messageSend messageName]
                      receiver:[@"%" stringByAppendingString:[[messageSend receiver] name]]
                    returnType:@"%id"
                          args:messageArgumentNames
                      argTypes:messageArgumentTypes
    ];
    return retval;
}

-(NSString*)generateMethodWithHeader:(MPWMethodHeader*)header body:(MPWStatementList*)method forClass:(NSString*)classname
{
    MPWMessageExpression *methodBody=[[method statements] lastObject];
    NSString *objcReturnType = [[header typeString] substringToIndex:1];
    
    NSString *llvmReturnType = [assemblyGenerator typeToLLVMType:[objcReturnType characterAtIndex:0]];
    
    
    
    
    NSMutableArray *allMethodArguments=[NSMutableArray array];
    for ( int i=0;i<[header numArguments];i++) {
        char typeChar =[[header typeStringForTypeName:[header argumentNameAtIndex:i]] characterAtIndex:0];
        
        [allMethodArguments addObject:[NSString stringWithFormat:@"%@ %@",[assemblyGenerator typeToLLVMType:typeChar],[@"%" stringByAppendingString:[header argumentNameAtIndex:i]]]];
    }

    
    
    NSString *methodSymbol1 = [assemblyGenerator writeMethodNamed:[header methodName]
                                          className:classname
                                         methodType:llvmReturnType
                                additionalParametrs:allMethodArguments
                                         methodBody:^(MPWLLVMAssemblyGenerator *generator) {
                                             NSString *retval=[self generateMessageSend:methodBody];
                                             
                                             [assemblyGenerator emitReturnVal:retval type:@"%id"];
                                         }];
    return methodSymbol1;
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

+(void)testDefineEmptyClassDynamically
{
    // takes around 24 ms (real) total
    //    NSLog(@"start testDefineEmptyClassDynamically");
    MPWCodeGenerator *codegen=[self codegen];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
    
    NSString *classname=[self anotherTestClassName];
    [gen writeHeaderWithName:@"testModule"];
    [gen writeClassWithName:classname superclassName:@"NSObject" instanceMethodListRef:nil numInstanceMethods:0];
    [gen flushSelectorReferences];
    [gen writeTrailer];
    [gen flush];
    NSData *source=[gen target];
 //   [source writeToFile:@"/tmp/zeromethodclass.s" atomically:YES];
    EXPECTNIL(NSClassFromString(classname), @"test class should not exist before load");
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
    [gen flushSelectorReferences];
    [gen writeTrailer];
    [gen flush];
    NSData *source=[gen target];
    [source writeToFile:@"/tmp/onemethodclass.s" atomically:YES];
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
    
    [gen flushSelectorReferences];
    [gen writeTrailer];
    [gen flush];
    NSData *source=[gen target];
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
    
    [gen flushSelectorReferences];
    [gen writeTrailer];
    [gen flush];
    NSData *source=[gen target];
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
    
    [gen flushSelectorReferences];
    [gen writeTrailer];
    [gen flush];
    NSData *source=[gen target];
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
    
    [gen flushSelectorReferences];
    [gen writeTrailer];
    [gen flush];
    NSData *source=[gen target];
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
    
    [gen flushSelectorReferences];
    [gen writeTrailer];
    NSData *source=[gen target];
    [source writeToFile:@"/tmp/onemethodcategory.s" atomically:YES];

    id instance=[[NSClassFromString(classname) new] autorelease];
    
    EXPECTFALSE([instance respondsToSelector:@selector(three)], @"responds tp selector three before loading class");
    
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    
    
    EXPECTTRUE([instance respondsToSelector:@selector(three)], @"responds tp selector three before loading class");
    
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
    
    [gen flushSelectorReferences];
    [gen writeTrailer];
    [gen flush];
    NSData *source=[gen target];
    [source writeToFile:@"/tmp/blockuse.s" atomically:YES];
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
    
    [gen flushSelectorReferences];
    [gen writeTrailer];
    [gen flush];
    NSData *source=[gen target];
    [source writeToFile:@"/tmp/blockcreate.s" atomically:YES];
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
    
    [gen flushSelectorReferences];
    [gen writeTrailer];
    [gen flush];
    NSData *source=[gen target];
    [source writeToFile:@"/tmp/blockcreatecapture.s" atomically:YES];
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
    MPWLLVMAssemblyGenerator *gen=[codegen assemblyGenerator];
    [gen writeHeaderWithName:@"testModule"];

    MPWStCompiler *compiler=[MPWStCompiler compiler];
    MPWMethodHeader *header=[MPWMethodHeader methodHeaderWithString:@"components:source splitInto:separator"];
    NSString *methodSymbol1 = [codegen generateMethodWithHeader:header body:[compiler compile:@"source componentsSeparatedByString:separator."] forClass:classname];
    
    NSString *methodListRef= [gen methodListForClass:classname methodNames:@[ [header methodName]]  methodSymbols:@[ methodSymbol1 ] methodTypes:@[ [header typeString]]];
    [gen writeClassWithName:classname superclassName:@"NSObject" instanceMethodListRef:methodListRef  numInstanceMethods:1];
    
    [gen flushSelectorReferences];
    [gen writeTrailer];
    [gen flush];
    NSData *source=[gen target];
    [source writeToFile:@"/tmp/fromsmalltalk.s" atomically:YES];
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    
    
    id instance=[[NSClassFromString(classname) new] autorelease];
    
     EXPECTTRUE([instance respondsToSelector:@selector(components:splitInto:)], @"responds to 'components:splitInto:");
    NSArray *splitResult=[instance components:@"Hi there" splitInto:@" "];
    IDEXPECT(splitResult, (@[@"Hi", @"there"]), @"loaded method");
    
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
             @"testGenerateStackBlockWithVariableCapture",
             @"testDefineClassWithOneSimpleSmalltalkMethod",
              ];
}

@end