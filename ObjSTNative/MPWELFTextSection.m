//
//  MPWELFTextSection.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.06.24.
//

#import "MPWELFTextSection.h"
#import "MPWELFReader.h"

@implementation MPWELFTextSection

-(long)numRelocEntries
{
    return [[[self reader] textRelocationTable] numEntries];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWELFTextSection(testing) 

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
