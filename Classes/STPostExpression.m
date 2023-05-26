//
//  STPostExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 26.05.23.
//

#import "STPostExpression.h"

@implementation STPostExpression

-(NSObject<MPWEvaluable>*)evaluateIn:aContext
{
    id value = [aContext evaluate:[self rhs]];

    //    NSLog(@"rhs: %@ value: %@, lhs: %@",[self rhs],value,lhs);
    return [lhs evaluatePostOf:value in:aContext];
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation STPostExpression(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
