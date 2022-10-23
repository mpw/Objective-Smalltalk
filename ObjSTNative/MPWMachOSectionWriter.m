//
//  MPWMachOSectionWriter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.10.22.
//

#import "MPWMachOSectionWriter.h"
#import "MPWMachOWriter.h"
#import <mach-o/loader.h>
#import <mach-o/reloc.h>
#import <mach-o/arm64/reloc.h>


@implementation MPWMachOSectionWriter
{
    struct relocation_info *relocations;
    int relocCount;
    int relocCapacity;
}

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    if ( self ) {
        relocCapacity = 10;
        [self growRelocations];
        self.segname=@"__TEXT";
        self.sectname=@"__text";
        self.relocationType = GENERIC_RELOC_VANILLA;
    }
    return self;
}



-(void)growRelocations
{
    relocCapacity *= 2;
    struct relocation_info *newReloc = calloc( relocCapacity , sizeof(struct relocation_info));
    if ( relocations ) {
        memcpy( newReloc, relocations, relocCount * sizeof(struct relocation_info));
        free(relocations);
    }
    relocations = newReloc;
}


-(void)writeSectionLoadCommandOnWriter:(MPWByteStream*)writer
{
    struct section_64 textSection={};
    strncpy( textSection.segname, [self.segname UTF8String] ,16); // "__text"
    strncpy( textSection.sectname, [self.sectname UTF8String] ,16 ); // "__TEXT"
    textSection.addr = self.address;
    textSection.offset = (int)self.offset;
    textSection.size = self.length;
    textSection.flags = self.flags; //;
    textSection.nreloc = [self numRelocationEntries];
    textSection.reloff = [self numRelocationEntries] >0 ? self.relocationEntryOffset : 0;
    [writer appendBytes:&textSection length:sizeof textSection];
}

-(void)declareGlobalSymbol:(NSString*)symbol
{
    [self.symbolWriter declareGlobalSymbol:symbol atOffset:(int)[self length] type:0xf section:self.sectionNumber];
}



-(void)addRelocationEntryForSymbol:(NSString*)symbol atOffset:(int)offset
{
    struct relocation_info r={};
    // FIXME:  this should not declare, it should retrieve + verify that the symbol already exists
    r.r_symbolnum = [self.symbolWriter declareGlobalSymbol:symbol atOffset:0 type:0xf section:self.sectionNumber];
//    NSLog(@"offset of reloc entry[%d]=%d, symbol name: %@",relocCount,offset,symbol);
    r.r_address = offset;
    r.r_extern = 1;
    r.r_length=2;
    r.r_pcrel=0;
    r.r_type=self.relocationType;
    if ( relocCount >= relocCapacity ) {
        [self growRelocations];
    }
    relocations[relocCount++]=r;
}


-(int)numRelocationEntries
{
    return relocCount;
}

-(int)relocationEntriesSize
{
    return [self numRelocationEntries] * sizeof(struct relocation_info);
}

-(int)padding
{
    return 8-([self data].length & 7);
}

-(long)sectionDataSize
{
    return [self data].length + [self padding];
}

-(BOOL)isActive
{
    return [self data].length > 0;
}


-(long)totalSize
{
    return [self sectionDataSize] + [self relocationEntriesSize];
}

-(long)relocEntrySize
{
    return relocCount * sizeof(struct relocation_info);
}

-(void)writeRelocationEntriesOn:(MPWByteStream*)writer
{
    [writer appendBytes:relocations length:self.relocEntrySize];
}

-(NSData*)data
{
    return (NSData*)[self target];
}


-(void)writeSectionDataOn:(MPWByteStream*)writer
{
    const char padding[8]={ 0,0,0,0,0,0,0,0};
    [writer writeData:[self data]];
    [writer appendBytes:padding length:[self padding]];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachOSectionWriter(testing) 

+(void)testComputePadding
{
    MPWMachOSectionWriter *writer=[self stream];
    [writer appendBytes:"" length:1];
    INTEXPECT( [writer padding],7,@"padding after 1 byte");
    [writer appendBytes:"" length:1];
    INTEXPECT( [writer padding],6,@"padding after 2 bytes");
}

+(NSArray*)testSelectors
{
   return @[
       @"testComputePadding",
			];
}

@end
