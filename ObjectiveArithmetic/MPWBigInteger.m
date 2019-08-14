//
//  MPWBigInteger.m
//  ObjectiveArithmetic
//
//  Created by Marcel Weiher on 14.08.19.
//

#import "MPWBigInteger.h"

@implementation MPWBigInteger

@end


@import MPWFoundation;

@implementation MPWBigInteger(tests)

+(void)testsAreBeingRun
{
    EXPECTTRUE( true, @"implemented something");
}

+testSelectors
{
    return @[
             @"testsAreBeingRun",
             ];
}

@end

