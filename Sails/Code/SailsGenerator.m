//
//  SailsGenerator.m
//  Sails
//
//  Created by Marcel Weiher on 01.01.24.
//

#import "SailsGenerator.h"
#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>


@implementation SailsGenerator

@end


#import <MPWFoundation/DebugMacros.h>

@implementation SailsGenerator(testing) 

+(void)someTest
{
    STBundle *bundle=[STBundle new];
//	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end
