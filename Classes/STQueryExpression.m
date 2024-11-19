//
//  STQueryExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 19.11.24.
//

#import "STQueryExpression.h"

@implementation STQueryExpression

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STQueryExpression(testing) 

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
