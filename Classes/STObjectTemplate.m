//
//  STObjectTemplate.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 13.02.21.
//

#import "STObjectTemplate.h"

@implementation STObjectTemplate

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STObjectTemplate(testing) 

+(void)someTest
{
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end
