//
//  MPWELFSection.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 02.05.24.
//

#import "MPWELFSection.h"
#import "elf.h"
#import "MPWELFReader.h"

@interface MPWELFSection()

@property (nonatomic,strong ) MPWELFReader *reader;

@end

@implementation MPWELFSection
{
    const Elf64_Shdr *sectionHeader;
    NSData *sectionData;
}

-(NSString*)sectionName
{
    return [self.reader sectionNameAtOffset:[self sectionNameOffset]];
}

-(instancetype)initWithSectionNumber:(int)secNo reader:(MPWELFReader*)newReader
{
    if ( self=[super init]) {
        self.reader = newReader;
        self.sectionNumber = secNo;
        sectionHeader=[self.reader sectionHeaderPointerAtIndex:secNo];
    }
    return self;
}

-(long)dataOffsetForOffset:(long)offset
{
    return sectionHeader->sh_offset + offset;
}


-(int)sectionNameOffset
{
    return sectionHeader->sh_name;
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

-(long)entrySize
{
    return sectionHeader->sh_entsize;
}

-(long)numEntries
{
    return sectionHeader->sh_entsize ?  sectionHeader->sh_size / sectionHeader->sh_entsize : 0;
}

-(NSData*)data
{
    return [self.reader.elfData subdataWithRange:NSMakeRange(self.sectionOffset,self.sectionSize)];
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
