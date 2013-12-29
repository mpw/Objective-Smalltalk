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
    [gen writeClassWithName:classname superclassName:@"NSObject" instanceMethodListRef:nil];
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

+(void)testDefineOneMethodClassDynamically
{
    // takes around 24 ms (real) total
    //    NSLog(@"start testDefineEmptyClassDynamically");
    MPWCodeGenerator *codegen=[[self new] autorelease];
    MPWLLVMAssemblyGenerator *gen=[MPWLLVMAssemblyGenerator stream];
    
    NSString *classname=@"EmptyCodeGenTestClass04";
    [gen writeHeaderWithName:@"testModule"];

    NSString *methodListRef=[gen writeConstMethodAndMethodList:classname methodName:@"components:splitInto:" typeString:@"@32@0:8@16@24"];
    [gen writeClassWithName:classname superclassName:@"NSObject" instanceMethodListRef:methodListRef];
    [gen writeTrailer];
    [gen flush];
    NSData *source=[gen target];
    [source writeToFile:@"/tmp/onemethodclass.s" atomically:YES];
    EXPECTNIL(NSClassFromString(classname), @"test class should not exist before load");
    EXPECTTRUE([codegen assembleAndLoad:source],@"codegen");
    Class loadedClass =objc_getClass("EmptyCodeGenTestClass04");
    EXPECTNOTNIL(loadedClass, @"test class should  xist after load");
    id instance=[[loadedClass new] autorelease];
    EXPECTTRUE([instance respondsToSelector:@selector(components:splitInto:)], @"responds to 'components:splitInto:");
    NSArray *splitResult=[instance components:@"Hi there" splitInto:@" "];
    IDEXPECT(splitResult, (@[@"Hi", @"there"]), @"loaded method");
    //    NSLog(@"end testDefineEmptyClassDynamically");
}


+testSelectors
{
    return @[
             @"testStaticEmptyClassDefine",
             @"testDefineEmptyClassDynamically",
             @"testDefineOneMethodClassDynamically",
              ];
}

@end