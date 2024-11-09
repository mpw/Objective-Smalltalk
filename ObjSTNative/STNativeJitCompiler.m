//
//  STNativeJitCompiler.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 12.10.24.
//

#import "STNativeJitCompiler.h"
#import "STObjectCodeGeneratorARM.h"
#import "MPWLiteralArrayExpression.h"
#import "MPWLiteralDictionaryExpression.h"

@implementation STNativeJitCompiler

-(void)generateMessageSendToSelector:(NSString*)selector
{
    [self.codegen generateJittedMessageSendToSelector:selector];
}

-(int)loadObjectPointer:someObject intoRegister:(int)regno
{
    [someObject retain];
    [[self codegen] loadRegister:regno withConstantAdress:someObject];
    return regno;
}




-(int)generateStringLiteral:(NSString*)theString intoRegister:(int)regno
{
    return [self loadObjectPointer:theString intoRegister:regno];
}

-(int)generateLiteralArrayExpression:(MPWLiteralArrayExpression*)theArray
{
    // FIXME:  does not currently support dynamically generated values
    //         or custom classes
    //         for dynamic literal expressions, must create a new array
    //         on the heap every time, generate code for filling it
    //         probably:  call a method that interacts well with compiled
    //         code (so do the array creation + looping + checking if dynamic
    //         code is needed as a method that just gets called)
    NSMutableArray *evaluated = [NSMutableArray arrayWithCapacity:theArray.objects.count];
    for ( id expr in theArray.objects ) {
        [evaluated addObject:[expr evaluateIn:self]];
    }
    // FIXME:  I don't know if just loading into register 0 is OK here
    return [self loadObjectPointer:evaluated intoRegister:0];
}

-(int)generateLiteralDictionaryExpression:(MPWLiteralDictionaryExpression*)theDict
{
    NSArray *keys=[theDict keys],*values=[theDict values];
    NSMutableDictionary *evaluated = [NSMutableDictionary dictionaryWithCapacity:keys.count];
    for (long i=0,max=keys.count;i<max;i++ ) {
        evaluated[[keys[i] evaluateIn:self]]=[values[i] evaluateIn:self];
    }
    return [self loadObjectPointer:evaluated intoRegister:0];
}

-(void)generateCallToCreateObjectFromInteger
{
    [self.codegen loadRegister:9 withConstantAdress:MPWCreateInteger];
    [self.codegen generateBranchAndLinkWithRegister:9];
}



-(int)generateLoadClassReference:(NSString*)className intoRegister:(int)regno
{
    Class theClass = NSClassFromString(className);
    NSAssert1( theClass != nil, @"class %@ not found",className);
    [[self codegen] loadRegister:regno withConstantAdress:theClass];
    return regno;
}


-(void)compileAndAddMethod:(STScriptedMethod*)method forClassNamed:(NSString*)className
{
    NSAssert1(method!=nil , @"no method to jit for class: %@", className);
    STJittableData *methodData=[self compiledCodeForMethod:method inClassNamed:className];
    method.classOfMethod=NSClassFromString(className);
    method.nativeCode = methodData;
    [method installNativeCode];
}

-(void)compileAndAddMethod:(STScriptedMethod*)method forClassDefinition:(STClassDefinition*)compiledClass
{
    [self compileAndAddMethod:method forClassNamed:compiledClass.name];
}

-(void)compileAndAddMethodsForClassDefinition:(STClassDefinition*)aClass
{
    for ( STScriptedMethod* method in aClass.methods) {
        [self compileAndAddMethod:method forClassDefinition:aClass];
    }
}


-(void)defineMethodsForClassDefinition:(STClassDefinition*)classDefinition
{
    self.classes[classDefinition.name]=classDefinition;
    [self compileAndAddMethodsForClassDefinition:classDefinition];
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

+resultOfEvaluatingJitCompiledExpression:(NSString*)expr
{
    static int numExpressions=0;
    NSString *className=[NSString stringWithFormat:@"STJitCompilerExpressionTester_%d",numExpressions++];
    NSString *wrapper=[NSString stringWithFormat:@"class %@ { -expression { %@. }}",className,expr];
    STNativeJitCompiler *compiler = [self compiler];
    STClassDefinition* classDef=[compiler compile:wrapper];
    [classDef defineJustTheClass];
    [compiler compileAndAddMethodsForClassDefinition:classDef];
    INTEXPECT( classDef.methods.count,1,@"one method defined");
    EXPECTNIL( [classDef.methods.firstObject callback],@"should not have a callback");
    EXPECTTRUE([classDef.methods.firstObject isNativeCodeActive],@"native code is active/installed in the method");

    return [[NSClassFromString(className) new] expression];
}

#define JITEXPECT( expr, expected , msg) IDEXPECT( [self resultOfEvaluatingJitCompiledExpression:expr], expected, msg)



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
    JITEXPECT(@"42",@(42),@"numeric constant" );
}

+(void)testJitCompileStringObjectLiteral
{
    JITEXPECT(@"'answer: 42'",@"answer: 42",@"string constant" );
}

+(void)testJitCompileNumberArithmetic
{
    ConcatterTest1 *concatter=[self compileAndAddSingleMethodExtensionToConcatter:@"extension ConcatterTest1 { -add:a to:b to:c { a+b+c. }}"];
    IDEXPECT([concatter add:@(100) to:@(10) to:@(3)],@(113),@"the answer");
}

+(void)testJitCompileConstantNumberArithmeticSequence
{
    JITEXPECT(@"100+30 + 5  * 2 * 2",@(540),@"number arithmetic on constants" );
}



+(void)testJitCompileFilter
{
    STNativeCompiler *compiler = [self jitCompiler];
    Class testClass1 = [compiler evaluateScriptString:@"filter TestDowncaser |{ ^object lowercaseString. }"];
    STClassDefinition *def=[compiler classForName:@"TestDowncaser"];
    INTEXPECT( def.methods.count,1,@"one method defined");
    EXPECTNIL( [def.methods.firstObject callback],@"should not have a callback");
    EXPECTTRUE([def.methods.firstObject isNativeCodeActive],@"native code is active/installed in the method");
    MPWFilter *filter = [testClass1 stream];
    [filter writeObject:@"Some Upper CASE string Data"];
    IDEXPECT([(NSArray*)[filter target] firstObject],@"some upper case string data",@"Filter result (should be lowercase)");
    
}

+(void)testNonJitFilterHasCallback
{
    STNativeCompiler *compiler = [STCompiler compiler];
    [compiler evaluateScriptString:@"filter TestDowncaserInterpreted |{ ^object lowercaseString. }"];
    STClassDefinition *def=[compiler classForName:@"TestDowncaserInterpreted"];
    INTEXPECT( def.methods.count,1,@"one method defined");
    EXPECTNOTNIL( [def.methods.firstObject callback],@"interpreted should have a callback");
    EXPECTFALSE( [def.methods.firstObject isNativeCodeActive],@"native code not active");
    
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

+(void)testJitCompileClassWithClassReference
{
    STNativeJitCompiler *compiler = [self jitCompiler];
    STClassDefinition *theClass = [compiler compile:@"class JitCompilerTestClassWithClassRef { -returnNSObjectInstance { class:NSObject new. } }"];
    
    Class testClass = NSClassFromString(@"JitCompilerTestClassWithClassRef");
    [theClass defineJustTheClass];
    EXPECTNIL(testClass, @"should not be defined before I defined it");
    [compiler compileAndAddMethodsForClassDefinition:theClass];
    testClass = NSClassFromString(@"JitCompilerTestClassWithClassRef");
    EXPECTNOTNIL(testClass, @"should be defined after I define it");
    id myObject = [testClass new];
    IDEXPECT( [myObject className], @"JitCompilerTestClassWithClassRef", @"class");
    //    EXPECTTRUE(false, @"the genereated code does not work, stop before I get a SEGFAULT");
    NSObject *n=[myObject returnNSObjectInstance];
    IDEXPECT( [n className],@"NSObject",@"the created method generated an NSObject");
}



+(void)testJitExpressionEvaluation
{
    JITEXPECT(@"3+5",@(8),@"jit compiled expr" );
}

+(void)testJitPlainLiteralArrays
{
    JITEXPECT(@"[3,5]", (@[@(3),@(5)]),@"jit compiled literal array" );
}

+(void)testJitPlainLiteralDicts
{
    JITEXPECT(@"#{ a: 3, b:5}", (@{@"a": @(3), @"b": @(5)}),@"jit compiled literal dict" );
}

+(void)testJitAccessEnv
{
    // FIXME:  this hangs (presumably in evaluation)
    JITEXPECT(@"env:HOME", @"/Ussrs/marcel/",@"jit compiled access to env scheme" );
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
       @"testNonJitFilterHasCallback",
       @"testJitCompileMethodWithLocalVariables",
       @"testJitCompileClassWithClassReference",
       @"testJitExpressionEvaluation",
       @"testJitPlainLiteralArrays",
       @"testJitPlainLiteralDicts",
//       @"testJitAccessEnv",				hangs so disabled
    ];
}

@end
