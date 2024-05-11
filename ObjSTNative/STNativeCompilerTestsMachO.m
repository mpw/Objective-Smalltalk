//
//  STNativeCompilerTestsMachO.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 11.05.24.
//

#import "STNativeCompilerTestsMachO.h"

@implementation STNativeCompilerTestsMachO

@end


#import <MPWFoundation/DebugMacros.h>
#import "MPWMachOReader.h"
#import "MPWMachOClassReader.h"
#import "MPWMachORelocationPointer.h"
#import "MPWMachOInSectionPointer.h"
#import "Mach_O_Structs.h"

@implementation STNativeCompilerTestsMachO(testing) 

+(void)testCompileSimpleClassAndMethod
{
    STNativeCompiler *compiler = [self compiler];
    STClassDefinition * compiledClass = [compiler compile:@" class TestClass : NSObject {  -<int>hashPlus200  { self hash + 200. }}"];
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
    INTEXPECT(classReader.numberOfMethods, 1,@"number of methods");
    IDEXPECT([classReader methodNameAt:0].targetPointer.stringValue,@"hashPlus200",@"name of method");
    IDEXPECT([classReader methodTypesAt:0].targetPointer.stringValue,@"l@:",@"type of method");
    IDEXPECT([classReader methodCodeAt:0].targetName,@"-[TestClass hashPlus200]",@"symbol for method code");
}

+(void)testCompileSimpleClassWithTwoMethods
{
    STNativeCompiler *compiler = [self compiler];
    STClassDefinition * compiledClass = [compiler compile:@" class TestClass2Methods : NSObject {  -<int>hashPlus100 { self hash + 100. } -<int>hashPlus200  { self hash + 200. }}"];
    IDEXPECT( compiledClass.name, @"TestClass2Methods", @"top level result");
    INTEXPECT( compiledClass.methods.count,2,@"method count");
    INTEXPECT( compiledClass.classMethods.count,0,@"class method count");
    NSData *macho=[compiler compileClassToMachoO:compiledClass];
    [macho writeToFile:@"/tmp/testclass2methods-from-source.o" atomically:YES];
    MPWMachOReader *reader = [MPWMachOReader readerWithData:macho];
    EXPECTTRUE(reader.isHeaderValid, @"got a macho");
    INTEXPECT([reader classReaders].count,1,@"number of classes" );
    MPWMachOClassReader *classReader = [reader classReaders].firstObject;
    IDEXPECT(classReader.nameOfClass, @"TestClass2Methods", @"name of class");
    IDEXPECT(classReader.superclassPointer.targetName, @"_OBJC_CLASS_$_NSObject", @"symbol for superclass");
    INTEXPECT(classReader.numberOfMethods, 2,@"number of methods");
    IDEXPECT([classReader methodNameAt:0].targetPointer.stringValue,@"hashPlus100",@"name of method");
    IDEXPECT([classReader methodNameAt:1].targetPointer.stringValue,@"hashPlus200",@"name of method");
    IDEXPECT([classReader methodTypesAt:0].targetPointer.stringValue,@"l@:",@"type of method");
    IDEXPECT([classReader methodCodeAt:0].targetName,@"-[TestClass2Methods hashPlus100]",@"symbol for method code");
    IDEXPECT([classReader methodCodeAt:1].targetName,@"-[TestClass2Methods hashPlus200]",@"symbol for method code");
}

+(void)testCompileMethodWithMultipleArgs
{
    STNativeCompiler *compiler = [self compiler];
    STClassDefinition * compiledClass = [compiler compile:@"class Concatter { -concat:a and:b { a, b. }}"];
    IDEXPECT( compiledClass.name, @"Concatter", @"top level result");
    INTEXPECT( compiledClass.methods.count,1,@"method count");
    [[compiler compileClassToMachoO:compiledClass] writeToFile:@"/tmp/concatter.o" atomically:YES];
}

+(void)testMachOCompileStringObjectLiteral
{
    STNativeCompiler *compiler = [self compiler];
    STClassDefinition * compiledClass = [compiler compile:@"class StringTest { -stringAnswer { 'answer: 42'. }}"];
    NSData *d=[compiler compileClassToMachoO:compiledClass];
    [d writeToFile:@"/tmp/stringLiteral.o" atomically:YES];
    
    MPWMachOReader *reader=[MPWMachOReader readerWithData:d];
    MPWMachOInSectionPointer *s=[reader pointerForSymbolAt:[reader indexOfSymbolNamed:@"_CFSTR_L1"]];
    EXPECTNOTNIL(s, @" pointer");
    Mach_O_NSString *str_read=(Mach_O_NSString*)[s bytes];
    IDEXPECT([[s relocationPointer] targetName],@"___CFConstantStringClassReference",@"class");
    INTEXPECT( str_read->length,10,@"length");
    INTEXPECT( str_read->flags, 1992, @"flags");
    
    long offset=((void*)&str_read->cstring) - (void*)str_read;
    MPWMachOInSectionPointer *contentPtr = [[s relocationPointerAtOffset:offset] targetPointer];
    IDEXPECT( contentPtr.stringValue,@"answer: 42",@"contents");
}

+(void)testMachOCompileSimpleFilter
{
    STNativeCompiler *compiler = [self compiler];
    STClassDefinition * compiledClass = [compiler compile:@"filter Upcaser |{ ^object stringValue uppercaseString. }"];
    [[compiler compileClassToMachoO:compiledClass] writeToFile:@"/tmp/upcasefilter.o" atomically:YES];
}

+(void)testCompileConstantNumberArithmeticToMachO
{
    STNativeCompiler *compiler = [self compiler];
    STClassDefinition * compiledClass = [compiler compile:@"class ArithmeticTester { -someConstantNumbersAdded { 100+30+7. }}"];
    [[compiler compileClassToMachoO:compiledClass] writeToFile:@"/tmp/constantArithmetic.o" atomically:YES];
}

+(void)testCompileNumberArithmeticToMachO
{
    STNativeCompiler *compiler = [self compiler];
    STClassDefinition * compiledClass = [compiler compile:@"class ArithmeticTester { -add:a to:b to:c { a+b+c. }}"];
    [[compiler compileClassToMachoO:compiledClass] writeToFile:@"/tmp/arithmetic.o" atomically:YES];
}


+(NSArray*)testSelectors
{
   return @[
       @"testCompileSimpleClassAndMethod",
       @"testCompileSimpleClassWithTwoMethods",
       @"testCompileMethodWithMultipleArgs",
       @"testMachOCompileStringObjectLiteral",
       @"testMachOCompileSimpleFilter",
       @"testCompileConstantNumberArithmeticToMachO",
       @"testCompileNumberArithmeticToMachO",
			];
}

@end
