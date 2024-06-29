//
//  MPWELFTextSection.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.06.24.
//

#import "MPWELFTextSection.h"
#import "MPWELFReader.h"
#import "MPWELFRelocationTable.h"


@implementation MPWELFTextSection

-(MPWELFRelocationTable*)relocationTable
{
    return [[self reader] textRelocationTable];
}


-(long)numRelocEntries
{
    return [[self relocationTable] numEntries];
}


-(int)typeOfRelocEntryAt:(int)offset
{
    return [[self relocationTable] typeOfRelocEntryAt:offset];
}

-(int)offsetOfRelocEntryAt:(int)offset
{
    return [[self relocationTable] offsetOfRelocEntryAt:offset];
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
