//
//  STPort.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 23.08.23.
//

#import "STPort.h"

@implementation STPort

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STPort(testing) 

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
