//
//  STNativeJitCompiler.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 12.10.24.
//

#import "STNativeJitCompiler.h"

@implementation STNativeJitCompiler

-(bool)jit
{
    return true;
}

@end


#import <MPWFoundation/DebugMacros.h>

@interface ConcatterTest1: NSObject
@end
@interface ConcatterTest1(dynamic)
-concat:a and:b;
-concat:a also:b;
-(NSNumber*)someConstantNumbersAdded;
-(NSString*)stringAnswer;
-add:a to:b to:c;
-theAnswer;
@end
@implementation ConcatterTest1
@end

@implementation STNativeJitCompiler(testing)


+(void)testJitCompileAMethod
{
    STNativeCompiler *compiler = [self jitCompiler];
    STClassDefinition * compiledClass = [compiler compile:@"extension ConcatterTest1 { -concat:a and:b { a, b. }}"];
    [compiler compileMethod:compiledClass.methods.firstObject inClassNamed:compiledClass.name isClassMethod:NO];
    STJittableData *methodData = [compiler generatedCode];
    ConcatterTest1* concatter=[[ConcatterTest1 new] autorelease];
    NSString* result=nil;
    NSException *didRaise=nil;
    @try {
        result=[concatter concat:@"This is " and:@"working"];
        EXPECTFALSE(true,@"should not get here");
    } @catch ( NSException *e ) {
        didRaise=e;
    }
    EXPECTNOTNIL(didRaise, @"should have raised");
    IDEXPECT(didRaise.name,  NSInvalidArgumentException,@"type of exception");
    [concatter.class addMethod:methodData.bytes forSelector:@selector(concat:and:) types:"@@:@@"];
    result=[concatter concat:@"This is " and:@"working"];
    IDEXPECT(result,@"This is working",@"concatted");
}

+(ConcatterTest1*)compileAndAddSingleMethodExtensionToConcatter:(NSString*)code
{
    STNativeCompiler *compiler = [self jitCompiler];
    STClassDefinition *compiledClass = [compiler compile:code];
    [compiler compileAndAddMethodsForClassDefinition:compiledClass];
    return [[ConcatterTest1 new] autorelease];
}

+(void)testJitCompileAMethodMoreCompactly
{
    ConcatterTest1 *concatter=[self compileAndAddSingleMethodExtensionToConcatter:@"extension ConcatterTest1 { -concat:a also:b { a, b. }}"];
    IDEXPECT([concatter concat:@"This abbreviated version " also:@"also works"],@"This abbreviated version also works",@"concatted");
}

+(void)testJitCompileNumberObjectLiteral
{
    ConcatterTest1 *concatter=[self compileAndAddSingleMethodExtensionToConcatter:@"extension ConcatterTest1 { -theAnswer { 42. }}"];
    IDEXPECT([concatter theAnswer],@(42),@"the answer");
}

+(void)testJitCompileStringObjectLiteral
{
    ConcatterTest1 *concatter=[self compileAndAddSingleMethodExtensionToConcatter:@"extension ConcatterTest1 { -stringAnswer { 'abcd'.  'answer: 42'. }}"];
    IDEXPECT([concatter stringAnswer],@"answer: 42",@"the answer");
}

+(void)testJitCompileNumberArithmetic
{
    ConcatterTest1 *concatter=[self compileAndAddSingleMethodExtensionToConcatter:@"extension ConcatterTest1 { -add:a to:b to:c { a+b+c. }}"];
    IDEXPECT([concatter add:@(100) to:@(10) to:@(3)],@(113),@"the answer");
}

+(void)testJitCompileConstantNumberArithmeticSequence
{
    ConcatterTest1 *concatter=[self compileAndAddSingleMethodExtensionToConcatter:@"extension ConcatterTest1 { -someConstantNumbersAdded { 100+30 + 5  * 2 * 2. }}"];
    id expectedAnswer = @(540);
    id computedAnswer = [concatter someConstantNumbersAdded];
    IDEXPECT(computedAnswer,expectedAnswer,@"the answer");
}



+(void)testJitCompileFilter
{
    STNativeCompiler *compiler = [self jitCompiler];
    Class testClass1 = [compiler evaluateScriptString:@"filter TestDowncaser |{ ^object lowercaseString. }"];
    MPWFilter *filter = [testClass1 stream];
    [filter writeObject:@"Some Upper CASE string Data"];
    IDEXPECT([(NSArray*)[filter target] firstObject],@"some upper case string data",@"Filter result (should be lowercase)");
    
}

+(void)testJitCompileMethodWithLocalVariables
{
    STNativeCompiler *compiler = [self jitCompiler];
    Class testClass1 = [compiler evaluateScriptString:@"filter TestLocalVarFilter |{ var a. a := object uppercaseString. ^a. ^object. }"];
    MPWFilter *filter = [testClass1 stream];
    NSString *testData = @"Some Upper CASE string Data";
    [filter writeObject:testData];
    IDEXPECT([(NSArray*)[filter target] firstObject],@"SOME UPPER CASE STRING DATA",@"Filter result (should be uppercase)");
    IDEXPECT([(NSArray*)[filter target] lastObject],testData,@"second filter result");
}

+(void)testJitCompileClassReference
{
    STNativeCompiler *compiler = [self jitCompiler];
    STClassDefinition *theClass = [compiler compile:@"class JitCompilerTestClassWithClassRef { -returnNSObjectInstance { class:NSObject new. } }"];
    
    Class testClass = NSClassFromString(@"JitCompilerTestClassWithClassRef");
    [theClass defineJustTheClass];
    EXPECTNIL(testClass, @"should not be defined before I defined it");
    NSLog(@"Before jit compiling code with class reference");
    [compiler compileAndAddMethodsForClassDefinition:theClass];
    NSLog(@"After jit compiling code with class reference");
    testClass = NSClassFromString(@"JitCompilerTestClassWithClassRef");
    EXPECTNOTNIL(testClass, @"should be defined after I define it");
    id myObject = [testClass new];
    IDEXPECT( [myObject className], @"JitCompilerTestClassWithClassRef", @"class");
    //    EXPECTTRUE(false, @"the genereated code does not work, stop before I get a SEGFAULT");
    NSObject *n=[myObject returnNSObjectInstance];
    NSLog(@"after");
    IDEXPECT( [n className],@"NSObject",@"the created method generated an NSObject");
    
}


+(NSArray*)testSelectors
{
   return @[
       @"testJitCompileAMethod",
       @"testJitCompileNumberObjectLiteral",
       @"testJitCompileAMethodMoreCompactly",
       @"testJitCompileNumberArithmetic",
       @"testJitCompileConstantNumberArithmeticSequence",
       @"testJitCompileStringObjectLiteral",
       @"testJitCompileFilter",
       @"testJitCompileMethodWithLocalVariables",
       @"testJitCompileClassReference",
			];
}

@end
