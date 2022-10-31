//
//  STNativeCompiler.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.10.22.
//

#import "STNativeCompiler.h"
#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>
#import "MPWMachOWriter.h"
#import "MPWARMObjectCodeGenerator.h"
#import "MPWMachOClassWriter.h"


@implementation STNativeCompiler

-(NSData*)compileClassToMachoO:(MPWClassDefinition*)aClass
{
    NSMutableData *macho=[NSMutableData data];
    MPWMachOWriter *writer = [MPWMachOWriter streamWithTarget:macho];
    MPWMachOClassWriter *classwriter = [MPWMachOClassWriter writerWithWriter:writer];
    classwriter.nameOfClass = aClass.name;
    classwriter.nameOfSuperClass = aClass.superclassName;
    [writer addTextSectionData:[@"    " asData]];       //  need to have something in the text section so section numbers work
    [classwriter writeClass];
    [writer writeFile];
    return macho;
}


@end


#import <MPWFoundation/DebugMacros.h>
#import "MPWMachOReader.h"
#import "MPWMachOClassReader.h"
#import "MPWMachORelocationPointer.h"

@implementation STNativeCompiler(testing) 

+(void)testCompileSimpleClassAndMethod
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition * compiledClass = [compiler compile:@" class TestClass : NSObject {  -<int>hashPlush200  { self hash + 200. }}"];
    IDEXPECT( compiledClass.name, @"TestClass", @"top level result");
    INTEXPECT( compiledClass.methods.count,1,@"method count");
    INTEXPECT( compiledClass.classMethods.count,0,@"class method count");
    NSData *macho=[compiler compileClassToMachoO:compiledClass];
    [macho writeToFile:@"/tmp/testclass-from-source.o" atomically:YES];
    MPWMachOReader *reader = [MPWMachOReader readerWithData:macho];
    EXPECTTRUE(reader.isHeaderValid, @"got a macho");
    INTEXPECT([reader classReaders].count,1,@"number of classes" );
    MPWMachOClassReader *classReader = [reader classReaders].firstObject;
    IDEXPECT(classReader.nameOfClass, @"TestClass", @"name of class");
    IDEXPECT(classReader.superclassPointer.targetName, @"_OBJC_CLASS_$_NSObject", @"symbol for superclass");
//    INTEXPECT(classReader.numberOfMethods, 1,@"number of methods");
}

+(NSArray*)testSelectors
{
   return @[
			@"testCompileSimpleClassAndMethod",
			];
}

@end
