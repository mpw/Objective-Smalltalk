//
//  MPWMachOWriter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.09.22.
//
// http://www.cilinder.be/docs/next/NeXTStep/3.3/nd/DevTools/14_MachO/MachO.htmld/index.html
//

#import "MPWMachOWriter.h"
#import <mach-o/loader.h>
#import <nlist.h>
#import <mach-o/reloc.h>
#import <mach-o/arm64/reloc.h>
#import "SymtabEntry.h"
#import "MPWMachOSection.h"

@interface MPWMachOWriter()

@property (nonatomic, assign) int numLoadCommands;
@property (nonatomic, assign) int cputype;
@property (nonatomic, assign) int filetype;
@property (nonatomic, assign) int loadCommandSize;
@property (nonatomic, strong) NSMutableDictionary *stringTableOffsets;
@property (nonatomic, strong) MPWByteStream *stringTableWriter;

@property (nonatomic, strong) NSMutableDictionary *globalSymbolOffsets;
@property (nonatomic, strong) NSDictionary *externalSymbols;
//@property (nonatomic, strong) NSMutableDictionary *relocationEntries;



@end


@implementation MPWMachOWriter
{
    symtab_entry *symtab;
    int symtabCount;
    int symtabCapacity;
    struct relocation_info *relocations;
    int relocCount;
    int relocCapacity;
}

-(void)growSymtab
{
    symtabCapacity *= 2;
    symtab_entry *newSymtab = calloc( symtabCapacity , sizeof(symtab_entry));
    if ( symtab ) {
        memcpy( newSymtab, symtab, symtabCount * sizeof(symtab_entry));
        free(symtab);
    }
    symtab = newSymtab;
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

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    if ( self ) {
        self.cputype = CPU_TYPE_ARM64;
        self.filetype = MH_OBJECT;
        self.stringTableWriter = [MPWByteStream stream];
        [self.stringTableWriter appendBytes:"" length:1];
        self.stringTableOffsets=[NSMutableDictionary dictionary];
        self.globalSymbolOffsets=[NSMutableDictionary dictionary];

        symtabCapacity = 10;
        [self growSymtab];
        relocCapacity = 10;
        [self growRelocations];
    }
    return self;
}


-(void)writeHeader
{
    struct mach_header_64 header={};
    header.magic = MH_MAGIC_64;
    header.cputype = self.cputype;
    header.filetype = self.filetype;
    header.ncmds = self.numLoadCommands;
    header.sizeofcmds = self.loadCommandSize;
    [self appendBytes:&header length:sizeof header];

}

-(int)textSectionOffset
{
    return self.loadCommandSize + sizeof(struct mach_header_64);
}

-(int)relocationEntriessOffset
{
    return [self textSectionOffset] + [self textSectionSize];
}

-(int)numRelocationEntries
{
    return relocCount;
}

-(int)relocationEntriesSize
{
    return [self numRelocationEntries] * sizeof(struct relocation_info);
}


-(int)symbolTableOffset
{
    return [self relocationEntriessOffset] + [self relocationEntriesSize];
}

-(int)numSymbols
{
    return symtabCount;
}

-(int)symbolTableSize
{
    return [self numSymbols] * sizeof(symtab_entry);
}

-(int)textSectionSize
{
    return (int)self.textSection.length;
}

-(int)stringTableOffset
{
    return [self symbolTableOffset] + [self symbolTableSize];
}

-(int)segmentCommandSize
{
    return sizeof(struct segment_command_64) + sizeof(struct section_64);
}


-(void)writeSegmentLoadCommand
{
    struct segment_command_64 segment={};
    struct section_64 textSection={};
    segment.cmd = LC_SEGMENT_64;
    segment.cmdsize = [self segmentCommandSize];
    segment.nsects = 1;
    segment.fileoff=[self textSectionOffset];
    segment.filesize=[self textSectionSize];
    segment.vmsize = [self textSectionSize];
    segment.initprot = VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE;
    segment.maxprot = VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE;

    strcpy( textSection.sectname, "__text");
    strcpy( textSection.segname, "__TEXT");
    textSection.offset = [self textSectionOffset];
    textSection.size = [self textSectionSize];
    textSection.flags = S_ATTR_PURE_INSTRUCTIONS | S_ATTR_SOME_INSTRUCTIONS;
    textSection.nreloc = [self numRelocationEntries];
    textSection.reloff = [self relocationEntriessOffset];
    [self appendBytes:&segment length:sizeof segment];
    [self appendBytes:&textSection length:sizeof textSection];
}


-(void)writeSymbolTableLoadCommand
{
    struct symtab_command symtab={};
    symtab.cmd = LC_SYMTAB;
    symtab.cmdsize = sizeof symtab;
    symtab.nsyms = [self numSymbols];
    symtab.symoff = [self symbolTableOffset];
    symtab.stroff = [self stringTableOffset];
    symtab.strsize = (int)[self.stringTableWriter length];
    [self appendBytes:&symtab length:sizeof symtab];
}

-(void)writeTextSection
{
    NSAssert2(self.length == [self textSectionOffset], @"Actual symbol table offset %ld does not match computed %d", (long)self.length,[self symbolTableOffset]);
     [self writeData:self.textSection];
}

-(void)writeStringTable
{
    [self writeData:(NSData*)[self.stringTableWriter target]];
}

-(int)stringTableOffsetOfString:(NSString*)theString
{
    int offset = [self.stringTableOffsets[theString] intValue];
    if ( !offset ) {
        offset=(int)[self.stringTableWriter length];
        [self.stringTableWriter writeObject:theString];
        [self.stringTableWriter appendBytes:"" length:1];
        self.stringTableOffsets[theString]=@(offset);
    }
    return offset;
}

-(void)generateStringTable
{
    for (NSString* symbol in self.globalSymbolOffsets.allKeys) {
        [self stringTableOffsetOfString:symbol];
    }
}


-(void)writeRelocationEntries
{
    [self appendBytes:relocations length:relocCount * sizeof(struct relocation_info)];
}

-(void)addGlobalSymbol:(NSString*)symbol atOffset:(int)offset type:(int)theType section:(int)theSection
{
    if ( self.globalSymbolOffsets[symbol] == nil ) {
        self.globalSymbolOffsets[symbol]=@(symtabCount);
        symtab_entry entry={};
        entry.type = theType;
        entry.section = theSection;      // TEXT section
        entry.string_offset=[self stringTableOffsetOfString:symbol];
        entry.address = offset;
        if ( symtabCount >= symtabCapacity ) {
            [self growSymtab];
        }
        symtab[symtabCount++]=entry;
    }
}

-(void)addGlobalSymbol:(NSString*)symbol atOffset:(int)offset
{
    [self addGlobalSymbol:symbol atOffset:offset type:0xf section:1];
}

-(void)addRelocationEntryForSymbol:(NSString*)symbol atOffset:(int)offset
{
    struct relocation_info r={};
    [self addGlobalSymbol:symbol atOffset:0 type:0 section:0];
    r.r_symbolnum = [self.globalSymbolOffsets[symbol] intValue];
    r.r_address = offset;
    r.r_extern = 1;
    r.r_length=2;
    r.r_pcrel=1;
    r.r_type=ARM64_RELOC_BRANCH26;
    if ( relocCount >= relocCapacity ) {
        [self growRelocations];
    }
    relocations[relocCount++]=r;
}

-(void)writeSymbolTable
{
    NSAssert2(self.length == [self symbolTableOffset], @"Actual symbol table offset %ld does not match computed %d", (long)self.length,[self symbolTableOffset]);
    [self appendBytes:symtab length:symtabCount * sizeof(symtab_entry)];
}


-(NSData*)data
{
    return (NSData*)self.target;
}

-(void)writeFile
{
    self.numLoadCommands = 2;
    self.loadCommandSize = sizeof(struct symtab_command) + [self segmentCommandSize];
//    self.loadCommandSize += sizeof(struct section_64);
    [self writeHeader];
    [self generateStringTable];
    [self writeSegmentLoadCommand];
    [self writeSymbolTableLoadCommand];
    [self writeTextSection];
    [self writeRelocationEntries];
    [self writeSymbolTable];
    [self writeStringTable];
}

-(void)dealloc
{
    free( symtab );
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>
#import "MPWMachOReader.h"

@implementation MPWMachOWriter(testing) 

+(void)testCanWriteHeader
{
    MPWMachOWriter *writer = [self stream];
    [writer writeHeader];
    
    NSData *macho=[writer data];
    MPWMachOReader *reader = [[[MPWMachOReader alloc] initWithData:macho] autorelease];
    EXPECTTRUE([reader isHeaderValid], @"header valid");
    INTEXPECT([reader cputype],CPU_TYPE_ARM64,@"cputype");
    INTEXPECT([reader filetype],MH_OBJECT,@"filetype");
    INTEXPECT([reader numLoadCommands],0,@"number load commands");
}

+(void)testCanWriteGlobalSymboltable
{
    MPWMachOWriter *writer = [self stream];
    [writer addGlobalSymbol:@"_add" atOffset:10];
    NSData *machineCode = [self frameworkResource:@"add" category:@"aarch64"];
    writer.textSection = machineCode;
    INTEXPECT(writer.textSection.length,8,@"bytes in text section");
    
    [writer writeFile];
    
    NSData *macho=[writer data];
//    [macho writeToFile:@"/tmp/generated.macho" atomically:YES];
    MPWMachOReader *reader = [[[MPWMachOReader alloc] initWithData:macho] autorelease];
    
    EXPECTTRUE([reader isHeaderValid],@"valid header");
    INTEXPECT([reader numLoadCommands],2,@"number of load commands");
    INTEXPECT([reader numSymbols],1,@"number of symbols");
    NSArray *strings = [reader stringTable];
    EXPECTTRUE([reader isSymbolGlobalAt:0],@"first symbol _add is global");
    IDEXPECT([reader symbolNameAt:0],@"_add",@"first symbol _add is global");
    INTEXPECT([reader symbolOffsetAt:0],10,@"offset of _add");
    IDEXPECT( strings.lastObject, @"_add", @"last string in string table");
    INTEXPECT( strings.count, 1, @"number of strings");
    IDEXPECT( strings, (@[@"_add"]), @"string table");
    IDEXPECT( [[reader textSection] sectionData],machineCode, @"machine code from text section");
}

+(void)testCanWriteStringsToStringTable
{
    MPWMachOWriter *writer = [self stream];
    INTEXPECT( [writer stringTableOffsetOfString:@"_add"],1,@"offset");
    INTEXPECT( [writer stringTableOffsetOfString:@"_sub"],6,@"offset");
    INTEXPECT( [writer stringTableOffsetOfString:@"_add"],1,@"repeat");
}

+(void)testWriteLinkableAddFunction
{
    MPWMachOWriter *writer = [self stream];
    [writer addGlobalSymbol:@"_add" atOffset:10];
    NSData *machineCode = [self frameworkResource:@"add" category:@"aarch64"];
    writer.textSection = machineCode;
    [writer writeFile];
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/add.o" atomically:YES];
    
}

+(void)testWriteFunctionWithRelocationEntries
{
    MPWMachOWriter *writer = [self stream];
    [writer addRelocationEntryForSymbol:@"_other" atOffset:12];
    NSData *machineCode = [self frameworkResource:@"add" category:@"aarch64"];
    writer.textSection = machineCode;
    [writer writeFile];
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/reloc.o" atomically:YES];

    MPWMachOReader *reader = [[[MPWMachOReader alloc] initWithData:macho] autorelease];
    INTEXPECT([[reader textSection] numRelocEntries],1,@"number of undefined symbol reloc entries");
    INTEXPECT([[reader textSection] relocEntryOffset],216,@"offset of undefined symbol reloc entries");
    IDEXPECT( [[reader textSection] nameOfRelocEntryAt:0],@"_other",@"name");
    INTEXPECT( [[reader textSection] offsetOfRelocEntryAt:0],12,@"address");
    INTEXPECT([[reader textSection] typeOfRelocEntryAt:0],ARM64_RELOC_BRANCH26,@"reloc entry type");

}

+(NSArray*)testSelectors
{
   return @[
       @"testCanWriteHeader",
       @"testCanWriteStringsToStringTable",
       @"testCanWriteGlobalSymboltable",
//       @"testWriteLinkableAddFunction",
       @"testWriteFunctionWithRelocationEntries",
		];
}

@end
