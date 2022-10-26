//
//  MPWMachOInSectionPointer.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 09.10.22.
//

#import "MPWMachOInSectionPointer.h"
#import "MPWMachOSection.h"
#import "MPWMachORelocationPointer.h"

@interface MPWMachOInSectionPointer()

@property (nonatomic, strong) MPWMachOSection *section;
@property (nonatomic, assign) long offset;

@end

@implementation MPWMachOInSectionPointer

-(instancetype)initWithSection:(MPWMachOSection*)section offset:(long)offset
{
    self = [super init];
    self.section = section;
    self.offset = offset;
    return self;
}

-(const void*)bytes
{
    return [self.section bytes] + self.offset;
}

-(BOOL)hasRelocEntry
{
    return [self.section indexOfRelocationEntryAtOffset:self.offset] >= 0;
}

-(instancetype)pointerAtOffset:(long)relativeOffset
{
    return [[[[self class] alloc] initWithSection:self.section offset:self.offset + relativeOffset] autorelease];
}

-(MPWMachORelocationPointer*)relocationPointer
{
    if ([self hasRelocEntry]) {
        return [[[MPWMachORelocationPointer alloc] initWithSection:self.section relocEntryIndex:[self.section indexOfRelocationEntryAtOffset:self.offset]] autorelease];
    }
    return nil;
}

-(MPWMachORelocationPointer*)relocationPointerAtOffset:(long)offset
{
    return [[self pointerAtOffset:offset] relocationPointer];
}

-(instancetype)targetPointerAtOffset:(long)relativeOffset
{
    return [[self relocationPointerAtOffset:relativeOffset] targetPointer];
}

-(NSString*)stringValue
{
    return [NSString stringWithUTF8String:self.bytes];
}

-(void)dealloc
{
    [_section release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachOInSectionPointer(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
			];
}

@end
