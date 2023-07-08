//
//  MPWMachOInSectionPointer.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 09.10.22.
//

#import "MPWMachOInSectionPointer.h"
#import "MPWMachOSection.h"
#import "MPWMachORelocationPointer.h"
#import <MPWFoundation/DebugMacros.h>
#import "Mach_O_Structs.h"

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

-(NSString*)cfStringValue
{
//    EXPECTNOTNIL(self, @"stringPointer");
//    IDEXPECT([[self section] sectionName],@"__cfstring",@"section");
    Mach_O_NSString *s=(Mach_O_NSString*)[self bytes];
//    INTEXPECT(s->length,2,@"length");
    INTEXPECT(s->flags,1992,@"flags");

    MPWMachORelocationPointer *stringClassPtr=[self relocationPointer];
    EXPECTNOTNIL(stringClassPtr, @"stringClassPtr");
    IDEXPECT(stringClassPtr.targetName,@"___CFConstantStringClassReference",@"string class name");
    long cStringPtrOffset = ((void*)&(s->cstring) - (void*)s);
    INTEXPECT( cStringPtrOffset,16,@"");
    MPWMachORelocationPointer *stringContentsPointer=[self relocationPointerAtOffset:cStringPtrOffset];
    EXPECTNOTNIL(stringContentsPointer, @"stringContentsPointer");
//    IDEXPECT(,@"hi",@"actual string value");
    return [[stringContentsPointer targetPointer] stringValue];
}

-(void)dealloc
{
    [_section release];
    [super dealloc];
}

@end



@implementation MPWMachOInSectionPointer(testing)

+(void)testReadNSString
{
    MPWMachOReader *reader=[MPWMachOReader readerForTestFile:@"function-passing-nsstring"];
    int cfstringSymbolIndex = [reader indexOfSymbolNamed:@"l__unnamed_cfstring_"];
    INTEXPECT( cfstringSymbolIndex,1,@"index of the cfstring");
    MPWMachOInSectionPointer *stringPointer=[reader pointerForSymbolAt:cfstringSymbolIndex];
    IDEXPECT([stringPointer cfStringValue],@"hi",@"actual string value");
}

+(NSArray*)testSelectors
{
   return @[
       @"testReadNSString",
			];
}

@end
