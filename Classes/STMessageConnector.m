//
//  STMessageConnector.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 20.02.21.
//

#import "STMessageConnector.h"

@implementation STMessageConnector

-(instancetype)initWithSelector:(SEL)newSelector
{
    self=[super init];
    self.selector=newSelector;
    return self;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STMessageConnector(testing) 

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
