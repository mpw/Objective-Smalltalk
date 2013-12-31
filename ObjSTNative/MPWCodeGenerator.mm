//
//  MPWCodeGenerator.mm
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 2/26/13.
//
//

//#include "llvmincludes.h"

#import "MPWCodeGenerator.h"
#import "MPWLLVMAssemblyGenerator.h"
#import <dlfcn.h>
#import <objc/runtime.h>

@interface NSObject(dynamicallyGeneratedTestMessages)

-(NSArray*)components:(NSString*)aString splitInto:(NSString*)delimiter;
-(NSArray*)lines:(NSString*)aString;
-(NSArray*)words:(NSString*)aString;
-(NSArray*)splitThis:(NSString*)aString;

@end



@implementation MPWCodeGenerator



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
    NSString *o_to_dylib=[NSString stringWithFormat:@"ld  -macosx_version_min 10.8 -dylib -o %@ %@ -framework Foundation",dylib,ofile_name];
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


@end

#import <MPWFoundation/MPWFoundation.h>

@interface MPWCodeGeneratorTestClass : NSObject {}  @end

@implementation MPWCodeGeneratorTestClass




@end


@implementation MPWCodeGenerator(testing)



+(void)testStaticEmptyClassDefine
{
    MPWCodeGenerator *codegen=[[self new] autorelease];
    NSString *classname=@"EmptyCodeGenTestClass01";
    NSData *source=[[NSBundle bundleForClass:self] resourceWithName:@"empty-class" type:@"llvm-templateasm"];
    EXPECTNIL(NSClassFromString(classname), @"test class should not exist before load");
    EXPECTNOTNIL(source, @"should have source data");
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    
    Class loadedClass =NSClassFromString(classname);
    EXPECTNOTNIL(loadedClass, @"test class should  xist after load");
    id instance=[[loadedClass new] autorelease];
    EXPECTNOTNIL(instance, @"test class should be able to create instances");
}

+(void)testDefineEmptyClassDynamically
{
    // takes around 24 ms (real) total
    //    NSLog(@"start testDefineEmptyClassDynamically");
    MPWCodeGenerator *codegen=[[self new] autorelease];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
    
    NSString *classname=@"EmptyCodeGenTestClass03";
    [gen writeHeaderWithName:@"testModule"];
    [gen writeClassWithName:classname superclassName:@"NSObject" instanceMethodListRef:nil numInstanceMethods:0];
    [gen flushSelectorReferences];
    [gen writeTrailer];
    [gen flush];
    NSData *source=[gen target];
    [source writeToFile:@"/tmp/zeromethodclass.s" atomically:YES];
    EXPECTNIL(NSClassFromString(classname), @"test class should not exist before load");
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    Class loadedClass =NSClassFromString(classname);
    EXPECTNOTNIL(loadedClass, @"test class should  xist after load");
    id instance=[[loadedClass new] autorelease];
    EXPECTNOTNIL(instance, @"test class should be able to create instances");
    //    NSLog(@"end testDefineEmptyClassDynamically");
}

+(void)testDefineClassWithOneMethodDynamically
{
    // takes around 24 ms (real) total
    //    NSLog(@"start testDefineEmptyClassDynamically");
    MPWCodeGenerator *codegen=[[self new] autorelease];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
    
    NSString *classname=@"EmptyCodeGenTestClass04";
    [gen writeHeaderWithName:@"testModule"];
    NSString *methodName=@"components:splitInto:";
    NSString *methodType=@"@32@0:8@16@24";
    
//    NSString *methodListRef=[gen writeConstMethodAndMethodList:classname methodName:methodName typeString:methodType];
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
    EXPECTNOTNIL(loadedClass, @"test class should  xist after load");
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
    MPWCodeGenerator *codegen=[[self new] autorelease];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
    
    NSString *classname=@"EmptyCodeGenTestClass05";
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
    [source writeToFile:@"/tmp/threemethodclass.s" atomically:YES];
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
    MPWCodeGenerator *codegen=[[self new] autorelease];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
    
    NSString *classname=@"EmptyCodeGenTestClass06";
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


+testSelectors
{
    return @[
             @"testStaticEmptyClassDefine",
             @"testDefineEmptyClassDynamically",
             @"testDefineClassWithOneMethodDynamically",
             @"testDefineClassWithThreeMethodsDynamically",
             @"testStringsWithDifferentLengths",
              ];
}

@end