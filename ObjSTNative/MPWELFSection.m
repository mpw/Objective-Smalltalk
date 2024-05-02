//
//  MPWELFSection.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 02.05.24.
//

#import "MPWELFSection.h"
#import "elf.h"

@implementation MPWELFSection
{
    const Elf64_Shdr *sectionHeader;
    NSData *sectionData;
}

-(instancetype)initWithSectionHeaderPointer:(const void*)sectionHeaderPtr
{
    if ( self=[super init]) {
        sectionHeader=sectionHeaderPtr;
    }
    return self;
}

-(int)sectionType
{
    return sectionHeader->sh_type;
}

-(long)sectionOffset
{
    return sectionHeader->sh_offset;
}

-(long)sectionSize
{
    return sectionHeader->sh_size;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWELFSection(testing) 

+(void)someTest
{
//	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end
