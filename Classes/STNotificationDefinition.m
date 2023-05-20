//
//  STNotificationDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 20.05.23.
//

#import "STNotificationDefinition.h"

@implementation STNotificationDefinition

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STNotificationDefinition(testing) 

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
