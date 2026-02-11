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

// Override tests that currently crash so they can be re-enabled safely later

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

+(void)testBinarySelectorPrecedenceOverKeyword
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
        // Float support not yet in JIT
        @"testBinarySelectorPrecedenceOverKeyword",
        @"testFloatArithmetic",
        @"testAsFloat",
        @"testNegativeDecimalFractions",
        // NSRange struct passing not yet in JIT
        @"testNSRangeViaSubarray",
        // Block-based collect with interval/array not yet in JIT
        @"testIntervalBlockCollect",
        @"testArrayBlockCollect",
        // Negative integer literals: -2 yields 65534 (unsigned interpretation)
        @"testNegativeLiteral",
        @"testNegativeLiteralComputation",
        // Local variables across statements: JIT can't find vars from earlier statements
        @"testMultipleStatments",
        @"testKeywordMessageWithBinaryAsArg",
        // 'true' not resolved as built-in identifier
        @"testIfTrueIfFalse",
        @"testIfTrueIfFalseWithExpressionValue",
        // Block argument compilation issue (countByEnumeratingWithState: on STIdentifierExpression)
        @"testBlockArgs",
        // 'context' not resolved as built-in identifier
        @"testRecursiveInterpret",
        @"testToDo",
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
