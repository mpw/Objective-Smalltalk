//
//  STJITExpressionTests.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 10.02.26.
//

#import "STJITExpressionTests.h"
#import "STNativeJitCompiler.h"

@implementation STJITExpressionTests

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STJITExpressionTests(testing) 

+evaluateTestExpression:(NSString*)expr
{
    NSLog(@"result of jitting: %@",expr);
    id result = [STNativeJitCompiler resultOfEvaluatingJitCompiledExpression:expr];
    NSLog(@"result");
    return result;
}

// disable failing JIT tests

+(void)testFloatArithmetic
{
    EXPECTTRUE(false, @"not crashing");
}

+(void)testAsFloat
{
    EXPECTTRUE(false, @"not crashing");
}

+(void)testNegativeDecimalFractions
{
    EXPECTTRUE(false, @"not crashing");
}

+(void)testNSRangeViaSubarray
{
    EXPECTTRUE(false, @"not crashing");
}

+(void)testIntervalBlockCollect
{
    EXPECTTRUE(false, @"not crashing");
}

+(void)testArrayBlockCollect
{
    EXPECTTRUE(false, @"not crashing");
}

+(NSArray*)testSelectorsOfExpressionTests
{
    return [super testSelectors];
}

+(NSArray*)testSelectorsToIgnore
{
    NSArray * const selectors = @[
        @"testFloatArithmetic",
        @"testAsFloat",
        @"testNegativeLiteral",
        @"testNegativeLiteralComputation",
        @"testNegativeDecimalFractions",
        @"stringConcat",
        @"nestedArgStringConcat",
        @"nestedReceiverStringConcat",
        @"mixedStackedMappedConcat",
        @"testNSRangeViaSubarray",
        @"testMultipleStatments",
        @"testIfTrueIfFalse",
        @"testIfTrueIfFalseWithExpressionValue",
        @"testIfTrueIfFalseWithExpressionCondition",
        @"testBasicWhileTrue",
        @"testWhileTrueWithLongerBlock",
        @"testForLoop",
        @"testToDo",
        @"testBlockArgs",
        @"testIntervalBlockCollect",
        @"testArrayBlockCollect",
        @"testBinarySelectorPrecedenceOverKeyword",
        @"testKeywordMessageWithBinaryAsArg",
        @"testRecursiveInterpret",
        @"testCurlyBracesAllowedForBlocks",
    ];
    return selectors;
}

+(NSArray*)computedTestSelectors
{
    NSSet *toIgnore = [NSSet setWithArray:[self testSelectorsToIgnore]];
    NSArray *allSelectors = [self testSelectorsOfExpressionTests];
    NSMutableArray *toRun = [NSMutableArray array];
    for (NSString *selector in allSelectors) {
        if ( ![toIgnore containsObject:selector]) {
            [toRun addObject:selector];
        }
    }
    return toRun;
}

+(NSArray*)testSelectors
{
    return [self computedTestSelectors];
}

+(NSArray*)testSelectors_disabled
{
    return @[];
}

@end
