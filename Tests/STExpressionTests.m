//
//  STExpressionTests.m
//  ObjectiveSmalltalk
//
//  Self-contained expression tests extracted from STTests.
//  Each test evaluates a single expression (or short sequence)
//  and checks the result, requiring no external setup.
//

#import "STExpressionTests.h"
#import <MPWFoundation/MPWFoundation.h>
#import "STExpression.h"
@implementation STExpressionTests

// --- Arithmetic ---

+(void)testThreePlusFour
{
    TESTEXPR(@"3+4",@"7");
}

+(void)testSevenMinus4
{
    TESTEXPR(@"7-4",@"3");
}

+(void)testFloatArithmetic
{
    TESTEXPR(@"(3.2+4.4*10) intValue",@"76");
}

+(void)testAsFloat
{
    [self testexpr:@"3 floatValue / 2" expected:@"1.5"];
}

+(void)testNegativeLiteral
{
    [self testexpr:@"-2" expected:[NSNumber numberWithInt:-2]];
}

+(void)testNegativeLiteralComputation
{
    [self testexpr:@"4 * -2" expected:[NSNumber numberWithInt:-8]];
}

+(void)testNegativeDecimalFractions
{
    [self testexpr:@"(-1.2  * 10) intValue stringValue" expected:@"-12"];
    [self testexpr:@"(1.2 negated * 10) intValue stringValue" expected:@"-12"];
}

// --- Strings ---

+(void)stringConcat
{
    TESTEXPR(@"'Hi ' stringByAppendingString:'there'." ,@"Hi there");
}

+(void)nestedArgStringConcat
{
    TESTEXPR(@"'Hi ' stringByAppendingString:'there' uppercaseString.",@"Hi THERE");
//    [self testexpr:@"'Hi ' stringByAppendingString:'there' uppercaseString." expected:@"Hi THERE"];
}

+(void)nestedReceiverStringConcat
{
    [self testexpr:@"'Hi 'uppercaseString stringByAppendingString:'there'." expected:@"HI there"];
}

+(void)stackedMappedConcat
{
    [self testexpr:@"'hi ' , 'there ' , 'to' uppercaseString" expected:@"hi there TO"];
}

+(void)mixedStackedMappedConcat
{
    [self testexpr:@"'hi ' uppercaseString , 'there ' , 'to' uppercaseString" expected:@"HI there TO"];
}

+(void)simpleLiteral
{
    [self testexpr:@"'Hi'" expected:@"Hi"];
}

+(void)testCommaSelector
{
    [self testexpr:@"'Hello ','World!'" expected:@"Hello World!"];
    [self testexpr:@" #() , 'a', '2'" expected:[NSArray arrayWithObjects:@"a",[NSNumber numberWithInt:2],nil]];
}

// --- Literals ---

+(void)arrayLiteral
{
    TESTEXPR(@" [ 1, 2, 3] " , (@[@(1),@(2),@(3)]));
}

+(void)testSimpleLiteralDict
{
    TESTEXPR(@"#{ #key: 'value' }" , (@{ @"key": @"value"}) );
}

+(void)testLiteralDictWithNumberKey
{
    TESTEXPR(@"#{ 1 : 'value' }" , (@{ @(1) : @"value"}) );
}

+(void)testTwoElementLiteralDict
{
    TESTEXPR(@"#{ #key: 'firstValue', #hello: 'world' }" , (@{ @"key": @"firstValue", @"hello": @"world"}));
}

+(void)testNestedLiteralArrays
{
    id result = [self evaluate: @"#( 1, 2, #( 2, 3 ) )"];
    INTEXPECT([result count], 3, @"top level elements");
}

// --- Collections ---

+(void)collectArrayLiteral
{
    TESTEXPR(@"[1, 2, 3] collect + 3" ,([NSMutableArray arrayWithObjects:@"4",@"5",@"6",nil]));
}

+(void)collectTwoArrayLiterals
{
    [self testexpr:@"[1, 2, 3] collect + [1, 2, 3] each" expected:[NSMutableArray arrayWithObjects:@"2",@"4",@"6",nil]];
}

+(void)testCollectHOM
{
    TESTEXPR(@"#( 'Help ', 'Hello ', 'Hi ') collect , 'World!' ", (@[@"Help World!",@"Hello World!",@"Hi World!"]) );
}

+(void)testSelectHOM
{
    [self testexpr:@" #( 'Help', 'Hello World', 'Hello Marcel') select hasPrefix:'Hello' " expected:[NSArray arrayWithObjects:@"Hello World",@"Hello Marcel",nil]];
}

+(void)testNSRangeViaSubarray
{
    TESTEXPR(@" #( 'Help' , 'Hello World', 'Hello Marcel') subarrayWithRange:( 1 to: 2) ", ( @[@"Hello World",@"Hello Marcel"] ) )
}

+(void)testReduceFactorial
{
    [self testexpr:@"(1 to: 5) reduce * 1" expected:@(120)];
}

// --- Nil ---

+(void)testNil
{
    id result=[self evaluate:@"nil"];
    EXPECTNIL( result, @"result of evaluating nil");
}

// --- Variables and assignment ---

+(void)testMultipleStatments
{
    [self testexpr:@"a:=3. b:=4. a+b" expected:[NSNumber numberWithInt:7]];
}

+(void)testLeftArrowWorksLikeAssignment
{
    id result=[self evaluate:@"a <- 3. b <- 4. a"];
    INTEXPECT([result intValue], 3, @"left arrow didn't do assignment");
}

+(void)testPipeForTemporaryVariablesAllowed
{
    id result=[self evaluate:@"| a b | a := 3+4. a"];
    INTEXPECT([result intValue], 7, @"3+4");
}

+(void)testSingleCharUnicodeIdentifiersAllowed
{
    unichar pichar=960;
    NSString *script=[NSString stringWithFormat:@"%C := 314 . %C * 2.",pichar,pichar];
    id result=[self evaluate:script];
    INTEXPECT([result intValue], 628, @"2 * pi * 100");
}

// --- Blocks ---

+(void)testBlockNoComputation
{
    TESTEXPR(@"{ 3. } value. ",@"3");
}

+(void)testNoArgBlockWithComputation
{
    TESTEXPR(@"{ 3+2. } value. ",@"5");
}

+(void)testBlockArgs
{
    TESTEXPR(@"{ :i | i*4 . } value: 2.",@"8");
}

+(void)testIntervalBlockCollect
{
    [self testexpr:@"((1 to:3) collect:{ :i | i+2. } ) lastObject" expected:@"5"];
}

+(void)testArrayBlockCollect
{
    TESTEXPR(@"( #( 1, 2, 7 ) collect:{ :i | i*2. } ) lastObject" ,@"14");
}



// --- Control flow ---

+(void)testIfTrueIfFalse
{
    TESTEXPR( @"true ifTrue: { 3. } ifFalse: { 4. }.", @(3) );
}

+(void)testIfTrueIfFalseWithIntegerCondition
{
    TESTEXPR( @"1 ifTrue: { 3. } ifFalse: { 4. }.", @(3) );
}

+(void)testIfTrueIfFalseWithExpressionValue
{
    TESTEXPR( @"true ifTrue: { 3+4. } ifFalse: { 4. }.", @(7) );
}

+(void)testIfTrueIfFalseWithExpressionCondition
{
    TESTEXPR(@"('hello world' hasPrefix:'hello') ifTrue: { 3+4.  } ifFalse: { 4. }." , @(7));
}

+(void)testBasicWhileTrue
{
    TESTEXPR(@"var a. a:=2.{ a<100. } whileTrue:{ a:=(2*a) }. a.", @(128));
}

+(void)testWhileTrueWithLongerBlock
{
    TESTEXPR(@"| a b | a:=2. b:=1. { a<100. } whileTrue:{ a:=(2*a). b:=(b+1). }. b." ,@(7));
}

+(void)testForLoop
{
    [self testexpr:@"| a |  a:=2. (1 to:10) do:{ :i | a:=(2*a). }. a." expected:[NSNumber numberWithInt:2048]];
}

+(void)testToDo
{
    TESTEXPR(@"var a.  a:=1. 1 to:10 do: { :i | a:=(a+1). }. a." ,@"11");
}

// --- Message precedence ---

+(void)testBinarySelectorPrecedenceOverKeyword
{
    [self testexpr:@"(1+3 to:3+8) to." expected:@"11"];
}

+(void)testKeywordMessageWithBinaryAsArg
{
    [self testexpr:@" a:= #( 1, 2, 3) mutableCopy. a replaceObjectAtIndex: 1+1 withObject:'there'. a at:2." expected:@"there"];
}

// --- Pipe syntax ---

+(void)testCompositionViaPipe
{
    NSString *result=[self evaluate:@"'a' stringByAppendingString:'b' | stringByAppendingString:'c'."];
    IDEXPECT(result, @"abc", @"concated");
}

+(void)testCompositionViaPipeDoesntBlockFurtherEval
{
    NSString *result=[self evaluate:@"'a' stringByAppendingString:'b' | stringByAppendingString:'c'. 'hello'"];
    IDEXPECT(result, @"hello", @"after");
}

// --- Points/Geometry ---

+(void)testNSPointViaString
{
    [self testexpr:@" '{1,2}' point " expected:[MPWPoint pointWithX:1 y:2]];
}

+(void)testNSSizeViaString
{
    [self testexpr:@" '{1,2}' asSize " expected:[MPWPoint pointWithX:1 y:2]];
}


// --- Query ---

+(void)testEvaluateQueryAsNextObject
{
    TESTEXPR( @"[ 'a', 'b'] each ? ",@"a");
}

+(NSArray*)testSelectors
{
    return @[
        // Arithmetic
        @"testThreePlusFour",
        @"testSevenMinus4",
        @"testFloatArithmetic",
        @"testAsFloat",
        @"testNegativeLiteral",
        @"testNegativeLiteralComputation",
        @"testNegativeDecimalFractions",
        // Strings
        @"stringConcat",
        @"nestedArgStringConcat",
        @"nestedReceiverStringConcat",
        @"stackedMappedConcat",
        @"mixedStackedMappedConcat",
        @"simpleLiteral",
        @"testCommaSelector",
        // Literals
        @"arrayLiteral",
        @"testSimpleLiteralDict",
        @"testLiteralDictWithNumberKey",
        @"testTwoElementLiteralDict",
        @"testNestedLiteralArrays",
        // Collections
        @"collectArrayLiteral",
        @"collectTwoArrayLiterals",
        @"testCollectHOM",
#if !GS_API_LATEST
        @"testSelectHOM",
#endif
        @"testNSRangeViaSubarray",
        @"testReduceFactorial",
        // Nil
        @"testNil",
        // Variables and assignment
        @"testMultipleStatments",
        @"testLeftArrowWorksLikeAssignment",
        @"testPipeForTemporaryVariablesAllowed",
        @"testSingleCharUnicodeIdentifiersAllowed",
        // Blocks
        @"testBlockNoComputation",
        @"testNoArgBlockWithComputation",
        @"testBlockArgs",
        @"testIntervalBlockCollect",
        @"testArrayBlockCollect",
        // Control flow
        @"testIfTrueIfFalse",
        @"testIfTrueIfFalseWithExpressionValue",
        @"testIfTrueIfFalseWithExpressionCondition",
        @"testBasicWhileTrue",
        @"testWhileTrueWithLongerBlock",
        @"testForLoop",
        @"testToDo",
        // Message precedence
        @"testBinarySelectorPrecedenceOverKeyword",
        @"testKeywordMessageWithBinaryAsArg",
        // Pipe syntax
        @"testCompositionViaPipe",
        @"testCompositionViaPipeDoesntBlockFurtherEval",
        // Points/Geometry
        @"testNSPointViaString",
        @"testNSSizeViaString",
        // Query
        @"testEvaluateQueryAsNextObject",
        @"testIfTrueIfFalseWithIntegerCondition",
    ];
}

@end
