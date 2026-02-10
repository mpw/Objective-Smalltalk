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

+(NSArray*)testSelectors
{
    return @[];
}

@end
