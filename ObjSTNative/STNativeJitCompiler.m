//
//  STNativeJitCompiler.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 12.10.24.
//

#import "STNativeJitCompiler.h"

@implementation STNativeJitCompiler

-(bool)jit
{
    return true;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STNativeJitCompiler(testing) 

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
