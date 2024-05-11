//
//  STNativeCompilerTestsMachO.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 11.05.24.
//

#import "STNativeCompilerTestsMachO.h"
#import "MPWMachOWriter.h"
#import "MPWMachOClassWriter.h"

@implementation STNativeCompiler(MachO)

-createObjectFileWriter
{
    return [MPWMachOWriter stream];
}

-createClassWriter
{
    return [MPWMachOClassWriter writerWithWriter:[self writer]];
}


@end

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

+(void)testMachOCompileBlock
{
    STNativeCompiler *compiler = [self compiler];
    MPWBlockExpression * compiledBlock = [compiler compile:@"{ 3 }"];
    [[compiler compileBlockToMachoO:compiledBlock] writeToFile:@"/tmp/blockFromST.o" atomically:YES];
}

+(void)testMachOCompileBlockWithArg
{
    STNativeCompiler *compiler = [self compiler];
    MPWBlockExpression * compiledBlock = [compiler compile:@"{ :a | a + 3. }"];
    [[compiler compileBlockToMachoO:compiledBlock] writeToFile:@"/tmp/blockWithArg.o" atomically:YES];
}

+(void)testMachOCompileAndRunBlockWithArg
{
    STNativeCompiler *compiler = [self compiler];
    MPWBlockExpression * compiledBlock = [compiler compile:@"{ :a | a + 3. }"];
    [[compiler compileBlockToMachoO:compiledBlock] writeToFile:@"/tmp/blockWithArgToLink.o" atomically:YES];
    [[self frameworkResource:@"use_st_block" category:@"mfile"] writeToFile:@"/tmp/use_st_block.m" atomically:YES];
    int compileSucess = system("cd /tmp; cc -rpath /Library/Frameworks -O  -Wall -o use_st_block use_st_block.m blockWithArgToLink.o -F/Library/Frameworks -framework ObjectiveSmalltalk   -framework MPWFoundation -framework Foundation");
    INTEXPECT(compileSucess,0,@"compile worked");
    int runSucess = system("cd /tmp; ./use_st_block");
    INTEXPECT(runSucess,0,@"run worked");
    
}

+(void)testGenerateCodeForBlocksInMethod
{
    STNativeCompiler *compiler = [self compiler];
    STClassDefinition *theClass = [compiler compile:@"class TestClassIfTrueIfFalse { -tester:cond { cond ifTrue: { 3. } ifFalse:{ 2. }. } }"];
    [[compiler compileClassToMachoO:theClass] writeToFile:@"/tmp/classWithIfTrueIfFalse.o" atomically:YES];
    
    
    [[self frameworkResource:@"use_class_with_if" category:@"mfile"] writeToFile:@"/tmp/use_class_with_if.m" atomically:YES];
    int compileSucess = system("cd /tmp; cc -rpath /Library/Frameworks -O  -Wall -o use_class_with_if use_class_with_if.m classWithIfTrueIfFalse.o -F/Library/Frameworks -framework ObjectiveSmalltalk   -framework MPWFoundation -framework Foundation");
    INTEXPECT(compileSucess,0,@"compile worked");
    int runSucess = system("cd /tmp; ./use_class_with_if");
    INTEXPECT(runSucess,0,@"run worked");
}

+(void)testGenerateCodeForClassReference
{
    STNativeCompiler *compiler = [self compiler];
    STClassDefinition *theClass = [compiler compile:@"class TestClassWithClassRef { -tester { class:NSObject new. } }"];
    [[compiler compileClassToMachoO:theClass] writeToFile:@"/tmp/classThatCreatesNSObjects.o" atomically:YES];
    
    
    [[self frameworkResource:@"use_class_that_creates_nsobject" category:@"mfile"] writeToFile:@"/tmp/use_class_that_creates_nsobject.m" atomically:YES];
    int compileSucess = system("cd /tmp; cc -rpath /Library/Frameworks -O  -Wall -o use_class_that_creates_nsobject use_class_that_creates_nsobject.m classThatCreatesNSObjects.o -F/Library/Frameworks -framework ObjectiveSmalltalk   -framework MPWFoundation -framework Foundation");
    INTEXPECT(compileSucess,0,@"compile worked");
    int runSucess = system("cd /tmp; ./use_class_that_creates_nsobject");
    INTEXPECT(runSucess,0,@"run worked");
}


+(NSString*)errorCompilingAndRunning:(NSString*)objs filename:(NSString*)filename compiler:(STNativeCompiler *)compiler
{
    STClassDefinition *theClass = [compiler compile:objs];
    
    [[compiler compileProcessToMachoO:theClass] writeToFile:[NSString stringWithFormat:@"/tmp/%@.o",filename] atomically:YES];
    int compileSuccess = [compiler linkObjects:@[ filename ] toExecutable:filename inDir:@"/tmp"];
    if (compileSuccess!=0) {
        return [NSString stringWithFormat:@"link of %@ failed with %d",filename,compileSuccess];
    }
    NSString *runCommmand=[NSString stringWithFormat:@"cd /tmp; ./%@",filename];
    int runSucess = system([runCommmand UTF8String]);
    if (runSucess!=0) {
        return [NSString stringWithFormat:@"run of %@ failed with %d",filename,runSucess];
    }
    return @"No error";
    //    INTEXPECT(runSucess,0,@"run worked");
}

+(NSString*)errorCompilingAndRunning:(NSString*)objs filename:(NSString*)filename
{
    return [self errorCompilingAndRunning:(NSString*)objs filename:(NSString*)filename compiler:[self compiler]];
}



#define COMPILEANDRUN( str, theFilename )\
NSString *msg=[self errorCompilingAndRunning:str filename:theFilename];\
IDEXPECT(msg,@"No error",@"compile and run");\


+(void)testGenerateMainThatCallsClassMethod
{
    COMPILEANDRUN( @"class TestHelloWorld : STProgram { -main:args { class:MPWByteStream Stdout println:'Hello World from auto-generated main'. 0. } }", @"selfContainedHelloWorld");
}


+(void)testTwoStringsInMachO
{
    COMPILEANDRUN( @"class TestClassTwoStrings : STProgram {  -method2 { self Stdout println:'2nd string'.  } -main:args { self Stdout println:'1st string'. self method2. 0. } }", @"classWithTwoStrings");
}

+(void)testLocalVariablesNotOverwrittenByNestedExpressionsRegression
{
    COMPILEANDRUN( @"class TestDoNotOverwriteLocalVar : STProgram {  -main:args {  var a. a := 10. var b. b := 20. (3+4) * a - 70.  a * 2 - 20.} }", @"TestDoNotOverwriteLocalVar");
}

#define COMPILEANDRUNSTACKBLOCKS( str, theFilename )\
NSString *msg=[self errorCompilingAndRunning:str filename:theFilename compiler:[self stackBlockCompiler]];\
IDEXPECT(msg,@"No error",@"compile and run");\


+(void)testNormalBlocksAreNotOnStack
{
    COMPILEANDRUN( @"class TestStaticBlocksNotOnStack : STProgram {  -main:args {  class:NSObject isPointerOnStackAboveMeForST:{ 2. }. } }", @"TestStaticBlocksNotOnStack");
}

+(void)testForcedStackBlocksAreActuallyOnStack
{
    COMPILEANDRUNSTACKBLOCKS(@"class TestStaticBlocksNotOnStack : STProgram {  -main:args {  1 - (class:NSObject isPointerOnStackAboveMeForST:{ 2. }). } }",  @"TestStackBlocksAreOnStack")
}

+(void)testStackBlocksAreActuallyOnStack
{
    COMPILEANDRUN(@"class TestCapturedVarBlocksOnStack : STProgram {  -main:args { var a. a:=1.  1 - (class:NSObject isPointerOnStackAboveMeForST:{ a. }). } }",  @"TestCapturedVarBlocksOnStack")
}

+(void)testStackBlocksCanBeUsed
{
    COMPILEANDRUNSTACKBLOCKS(@"class TestStackBlocksCanBeUsed : STProgram {  -main:args {  { :stream | stream println:'Stack Block executing!'. 0. } value: self Stdout. } }",  @"TestStackBlocksCanBeUsed")
}

+(void)testBlockCanAccessOutsideScopeVariables
{
    COMPILEANDRUN( @"class TestAccessOutsideScopeVarsFromBlock : STNonNilTestProgram {  -main:args { var a. a := 10. { a - 10. } value.} }", @"TestAccessOutsideScopeVarsFromBlock");
}

+(void)testClassMethodsWork
{
    COMPILEANDRUN( @"class TestClassWithClassMethods : STNonNilTestProgram { +main:args { 0. } }", @"testClassMethodsWork");
}

+(void)testMixingClassAndInstanceMethodsWorks
{
    COMPILEANDRUN( @"class TestClassWithClassMethods : STNonNilTestProgram { +thirtytwo { 32. } -main:args { self class thirtytwo - 32. } }", @"testClassMethodsWork");
}

+(void)testDeclarAndReturnNativeIntVariables
{
    // This currently "works" if I return "a intValue" instead of "a"
    COMPILEANDRUN( @"class Hello  { +<int>main:args { var <int> a. a:= 0. a. }  } }", @"testDeclaredIntCanBeReturned");
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
       @"testMachOCompileBlock",
       @"testMachOCompileBlockWithArg",
       @"testMachOCompileAndRunBlockWithArg",
       @"testGenerateCodeForBlocksInMethod",
       @"testGenerateCodeForClassReference",
       @"testGenerateMainThatCallsClassMethod",
       @"testTwoStringsInMachO",
       @"testLocalVariablesNotOverwrittenByNestedExpressionsRegression",
       @"testNormalBlocksAreNotOnStack",
       @"testForcedStackBlocksAreActuallyOnStack",
       @"testStackBlocksAreActuallyOnStack",
       @"testStackBlocksCanBeUsed",
       @"testBlockCanAccessOutsideScopeVariables",
       @"testClassMethodsWork",
       @"testMixingClassAndInstanceMethodsWorks",
       //       @"testDeclarAndReturnNativeIntVariables",
			];
}

@end
