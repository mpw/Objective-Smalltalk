//
//  STMachOCompiler.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 11.10.24.
//

#import "STMachOCompiler.h"

@implementation STMachOCompiler

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STMachOCompiler(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end
