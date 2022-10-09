//
//  MPWMachOPointer.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 08.10.22.
//

#import "MPWMachORelocationPointer.h"
#import "MPWMachOSection.h"
#import "MPWMachOInSectionPointer.h"

@interface MPWMachORelocationPointer()

@property (nonatomic, strong) MPWMachOSection *section;
@property (nonatomic, assign) int relocEntryIndex;

@end

@implementation MPWMachORelocationPointer

-(instancetype)initWithSection:(MPWMachOSection*)section relocEntryIndex:(int)theIndex
{
    self = [super init];
    self.section = section;
    self.relocEntryIndex = theIndex;
    return self;
}


-(long)targetOffset
{
    return [self.section offsetInTargetSectionForRelocEntryAt:self.relocEntryIndex];
}

-(int)indexOfSymtabEntry
{
    return [self.targetSection indexOfSymboltableEntryAtOffset:[self targetOffset]];
}

-(NSString*)targetName
{
    return [self.section nameOfRelocEntryAt:self.relocEntryIndex];
}

-(MPWMachOSection*)targetSection
{
    return [self.section sectionForRelocEntryAt:self.relocEntryIndex];
}


-(MPWMachOInSectionPointer*)targetPointer
{
    return [[MPWMachOInSectionPointer alloc] initWithSection:self.targetSection offset:self.targetOffset];
}

-(instancetype)relativePointer:(long)offset
{
    return [[[self class] alloc] initWithSection:self.section offset:self.offset + offset];
}





-(void)dealloc
{
    [_section release];
    return [super dealloc];
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachORelocationPointer(testing) 

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
