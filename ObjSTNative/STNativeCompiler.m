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

-(void)writeMethodBody:(MPWScriptedMethod*)method on:(MPWARMObjectCodeGenerator*)codegen
{
}

-(NSData*)compileClassToMachoO:(MPWClassDefinition*)aClass
{
    NSMutableData *macho=[NSMutableData data];
    MPWMachOWriter *writer = [MPWMachOWriter streamWithTarget:macho];
    MPWMachOClassWriter *classwriter = [MPWMachOClassWriter writerWithWriter:writer];
    MPWARMObjectCodeGenerator *codegen = [MPWARMObjectCodeGenerator stream];

    codegen.symbolWriter = writer;
    codegen.relocationWriter = writer.textSectionWriter;

    classwriter.nameOfClass = aClass.name;
    classwriter.nameOfSuperClass = aClass.superclassName;
    NSMutableArray *symbolNames=[NSMutableArray array];
    NSMutableArray *methodNames=[NSMutableArray array];
    NSMutableArray *methodTypes=[NSMutableArray array];
    for ( MPWScriptedMethod* method in aClass.methods) {
        [methodNames addObject:method.methodName];
        [methodTypes addObject:[[method header] typeString]];
        
        NSString *symbol=[NSString stringWithFormat:@"-[%@ %@]",aClass.name,method.methodName];
        [codegen generateFunctionNamed:symbol body:^(MPWARMObjectCodeGenerator * _Nonnull gen) {
            [self writeMethodBody:method on:codegen];
        }];
        [symbolNames addObject:symbol];
    }
    [writer addTextSectionData:[codegen target]];
    [classwriter writeInstanceMethodListForMethodNames:methodNames types:methodTypes functions:symbolNames ];
    [classwriter writeClass];
    [writer writeFile];
    return macho;
}


@end


#import <MPWFoundation/DebugMacros.h>
#import "MPWMachOReader.h"
#import "MPWMachOClassReader.h"
#import "MPWMachORelocationPointer.h"
#import "MPWMachOInSectionPointer.h"

@implementation STNativeCompiler(testing) 

+(void)testCompileSimpleClassAndMethod
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition * compiledClass = [compiler compile:@" class TestClass : NSObject {  -<int>hashPlus200  { self hash + 200. }}"];
    IDEXPECT( compiledClass.name, @"TestClass", @"top level result");
    INTEXPECT( compiledClass.methods.count,1,@"method count");
    INTEXPECT( compiledClass.classMethods.count,0,@"class method count");
    NSData *macho=[compiler compileClassToMachoO:compiledClass];
//    [macho writeToFile:@"/tmp/testclass-from-source.o" atomically:YES];
    MPWMachOReader *reader = [MPWMachOReader readerWithData:macho];
    EXPECTTRUE(reader.isHeaderValid, @"got a macho");
    INTEXPECT([reader classReaders].count,1,@"number of classes" );
    MPWMachOClassReader *classReader = [reader classReaders].firstObject;
    IDEXPECT(classReader.nameOfClass, @"TestClass", @"name of class");
    IDEXPECT(classReader.superclassPointer.targetName, @"_OBJC_CLASS_$_NSObject", @"symbol for superclass");
    INTEXPECT(classReader.numberOfMethods, 1,@"number of methods");
    IDEXPECT([classReader methodNameAt:0].targetPointer.stringValue,@"hashPlus200",@"name of method");
    IDEXPECT([classReader methodTypesAt:0].targetPointer.stringValue,@"l@:",@"type of method");
    IDEXPECT([classReader methodCodeAt:0].targetName,@"-[TestClass hashPlus200]",@"symbol for method code");
}

+(NSArray*)testSelectors
{
   return @[
			@"testCompileSimpleClassAndMethod",
			];
}

@end
