//
//  STQueryPredicate.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 23.09.25.
//

#import "STQueryPredicate.h"

@implementation STQueryPredicate

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STQueryPredicate(testing) 

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
