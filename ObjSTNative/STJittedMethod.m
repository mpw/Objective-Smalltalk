//
//  STJittedMethod.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 09.10.24.
//

#import "STJittedMethod.h"

@implementation STJittedMethod

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STJittedMethod(testing) 

+(void)someTest
{
//    	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end
