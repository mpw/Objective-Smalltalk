//
//  STNativeMachOCompiler.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 12.10.24.
//

#import "STNativeMachOCompiler.h"

@implementation STNativeMachOCompiler

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STNativeMachOCompiler(testing) 

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
