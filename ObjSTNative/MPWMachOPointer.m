//
//  MPWMachOPointer.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 08.10.22.
//

#import "MPWMachOPointer.h"
#import "MPWMachOSection.h"

@interface MPWMachOPointer()

@property (nonatomic, strong) MPWMachOSection *section;
@property (nonatomic, assign) int relocEntryIndex;

@end

@implementation MPWMachOPointer

-(instancetype)initWithSection:(MPWMachOSection*)section relocEntryIndex:(int)theIndex
{
    self = [super init];
    self.section = section;
    self.relocEntryIndex = theIndex;
    return self;
}

-(long)offset
{
    return [self.section offsetOfRelocEntryAt:self.relocEntryIndex];
}

-(long)targetOffset:(long)relativeOffset
{
    return [self.section offsetInTargetSectionForRelocEntryAt:self.relocEntryIndex] + relativeOffset;
}

-(long)targetOffset
{
    return [self targetOffset:0];
}

-(int)indexOfSymtabEntryAtRelativeOffset:(long)relativeOffset
{
    return [self.targetSection indexOfSymboltableEntryAtOffset:[self targetOffset:relativeOffset]];
}

-(void)dealloc
{
    [_section release];
    return [super dealloc];
}

-(NSString*)name
{
    return [self.section nameOfRelocEntryAt:self.relocEntryIndex];
}

-(MPWMachOSection*)targetSection
{
    return [self.section sectionForRelocEntryAt:self.relocEntryIndex];
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachOPointer(testing) 

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
