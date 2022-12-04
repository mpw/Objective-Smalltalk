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
        self.relocationLength = 3;
        self.alignment=3;
        self.relocationPCRel=0;
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
    struct section_64 section={};
    strncpy( section.segname, [self.segname UTF8String] ,16); // "__text"
    strncpy( section.sectname, [self.sectname UTF8String] ,16 ); // "__TEXT"
    section.addr = self.address;
    section.offset = (int)self.offset;
    section.size = self.length;
    section.flags = self.flags; //;
    section.nreloc = [self numRelocationEntries];
    section.reloff = [self numRelocationEntries] >0 ? self.relocationEntryOffset : 0;
    section.align = self.alignment;
    [writer appendBytes:&section length:sizeof section];
}

-(void)declareGlobalSymbol:(NSString*)symbol
{
    [self.symbolWriter declareGlobalSymbol:symbol atOffset:(int)[self length] type:0xf section:self.sectionNumber];
}

-(void)declareLocalSymbol:(NSString*)symbol
{
    [self.symbolWriter declareGlobalSymbol:symbol atOffset:(int)[self length] type:0xe section:self.sectionNumber];
}

-(void)declareGlobalTextSymbol:(NSString*)symbol
{
    [self.symbolWriter declareGlobalSymbol:symbol atOffset:(int)[self length] type:0xe section:1];
}



-(void)addRelocationEntryForSymbol:(NSString*)symbol atOffset:(int)offset type:(int)type relative:(BOOL)relative
{
    struct relocation_info r={};
    // FIXME:  this should not declare, it should retrieve + verify that the symbol already exists
    r.r_symbolnum = [self.symbolWriter declareGlobalSymbol:symbol atOffset:offset type:0xf section:self.sectionNumber];
    //    NSLog(@"offset of reloc entry[%d]=%d, symbol name: %@",relocCount,offset,symbol);
    r.r_address = offset;
    r.r_extern = 1;
    r.r_length=self.relocationLength;
    r.r_pcrel=relative;
    r.r_type=type;
    if ( relocCount >= relocCapacity ) {
        [self growRelocations];
    }
    relocations[relocCount++]=r;
}


-(void)addRelocationEntryForSymbol:(NSString*)symbol atOffset:(int)offset
{
    [self addRelocationEntryForSymbol:symbol atOffset:offset type:self.relocationType relative:self.relocationPCRel];
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
    long len = [self data].length;
    int remainder = (int)(len & 7);
    return remainder == 0 ? 0 : (8-remainder);
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
    INTEXPECT( [writer padding],0,@"padding after 0 bytes");
    [writer appendBytes:"" length:1];
    INTEXPECT( [writer padding],7,@"padding after 1 byte");
    [writer appendBytes:"" length:1];
    INTEXPECT( [writer padding],6,@"padding after 2 bytes");
    [writer appendBytes:"" length:1];
    INTEXPECT( [writer padding],5,@"padding after 3 bytes");
    [writer appendBytes:"" length:1];
    INTEXPECT( [writer padding],4,@"padding after 4 bytes");
    [writer appendBytes:"" length:1];
    INTEXPECT( [writer padding],3,@"padding after 5 bytes");
    [writer appendBytes:"" length:1];
    INTEXPECT( [writer padding],2,@"padding after 6 bytes");
    [writer appendBytes:"" length:1];
    INTEXPECT( [writer padding],1,@"padding after 7 bytes");
    [writer appendBytes:"" length:1];
    INTEXPECT( [writer padding],0,@"padding after 8 bytes");
}

+(NSArray*)testSelectors
{
   return @[
       @"testComputePadding",
			];
}

@end
