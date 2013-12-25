//
//  MPWCodeGenerator.mm
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 2/26/13.
//
//

//#include "llvmincludes.h"

#import "MPWCodeGenerator.h"
#import <dlfcn.h>

@implementation MPWCodeGenerator



+(NSString*)createTempDylibName
{
    char *templatename="/tmp/testdylibXXXXXXXX";
    char *theTemplate = strdup(templatename);
    NSString *name=nil;
    if (    mktemp( theTemplate) ) {
        name=[NSString stringWithUTF8String:theTemplate];
    }
    free( theTemplate);
    return name;
}

-(BOOL)assembleAndLoad:(NSData*)llvmAssemblySource
{
    NSString *name=[[self  class] createTempDylibName];
    NSString *ofile_name=[name stringByAppendingPathExtension:@"o"];
    NSString *dylib=[name stringByAppendingPathExtension:@"dylib"];
    NSString *source_name=[name stringByAppendingPathExtension:@"s"];
    [llvmAssemblySource writeToFile:source_name atomically:YES];
    NSString *asm_to_o=[NSString stringWithFormat:@"/usr/local/bin/llc -filetype=obj  %@  -o %@",source_name,ofile_name];
    NSString *o_to_dylib=[NSString stringWithFormat:@"ld  -macosx_version_min 10.8 -dylib -o %@ %@ -framework Foundation",dylib,ofile_name];
    system([asm_to_o fileSystemRepresentation] );
    system([o_to_dylib fileSystemRepresentation]);
    unlink([source_name fileSystemRepresentation]);
    unlink([ofile_name fileSystemRepresentation]);
    void *handle = dlopen( [dylib fileSystemRepresentation], RTLD_NOW);
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
    
    EXPECTNOTNIL(NSClassFromString(classname), @"test class should  xist after load");
}


+testSelectors
{
    return @[
             @"testStaticEmptyClassDefine"
              ];
}

@end