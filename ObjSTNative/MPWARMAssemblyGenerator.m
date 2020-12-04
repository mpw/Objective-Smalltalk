//
//  MPWARMAssemblyGenerator.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.12.20.
//

#import "MPWARMAssemblyGenerator.h"

@implementation MPWARMAssemblyGenerator

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWARMAssemblyGenerator(testing) 

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
