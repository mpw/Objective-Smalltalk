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
#import "SymtabEntry.h"

@interface MPWMachOWriter()

@property (nonatomic, assign) int numLoadCommands;
@property (nonatomic, assign) int cputype;
@property (nonatomic, assign) int filetype;
@property (nonatomic, assign) int loadCommandSize;
@property (nonatomic, strong) NSMutableDictionary *stringTableOffsets;
@property (nonatomic, strong) MPWByteStream *stringTableWriter;

@end


@implementation MPWMachOWriter

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.cputype = CPU_TYPE_ARM64;
    self.filetype = MH_OBJECT;
    self.stringTableWriter = [MPWByteStream stream];
    [self.stringTableWriter appendBytes:"" length:1];
    self.stringTableOffsets=[NSMutableDictionary dictionary];
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

-(int)symbolTableOffset
{
    return [self textSectionOffset] + [self textSectionSize];
}

-(int)numSymbols
{
    return (int)self.globalSymbols.count;
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
    segment.vmsize = 8;
    segment.initprot = VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE;
    segment.maxprot = VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE;

    strcpy( textSection.sectname, "__text");
    strcpy( textSection.segname, "__TEXT");
    textSection.offset = [self textSectionOffset];
    textSection.size = [self textSectionSize];
    textSection.flags = S_ATTR_PURE_INSTRUCTIONS | S_ATTR_SOME_INSTRUCTIONS;
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
    for (NSString* symbol in self.globalSymbols.allKeys) {
        [self stringTableOffsetOfString:symbol];
    }
}

-(void)writeSymbolTable
{
    NSAssert2(self.length == [self symbolTableOffset], @"Actual symbol table offset %ld does not match computed %d", (long)self.length,[self symbolTableOffset]);
    NSDictionary *symbols=self.globalSymbols;
    for (NSString* symbol in symbols.allKeys) {
        symtab_entry entry={};
        entry.type = 0x0f;
        entry.section = 1;      // TEXT section
        entry.string_offset=[self stringTableOffsetOfString:symbol];
        entry.address = [symbols[symbol] longValue];
        [self appendBytes:&entry length:sizeof entry];
    }
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
    [self writeSymbolTable];
    [self writeStringTable];
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
    writer.globalSymbols = @{ @"_add": @(10) };
    NSData *machineCode = [self frameworkResource:@"add" category:@"aarch64"];
    writer.textSection = machineCode;
    INTEXPECT(writer.textSection.length,8,@"bytes in text section");
    
    [writer writeFile];
    
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/generated.macho" atomically:YES];
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
    IDEXPECT( [reader textSection],machineCode, @"machine code from text section");
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
    writer.globalSymbols = @{ @"_add": @(0) };
    NSData *machineCode = [self frameworkResource:@"add" category:@"aarch64"];
    writer.textSection = machineCode;
    [writer writeFile];
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/add.o" atomically:YES];
    
}

+(NSArray*)testSelectors
{
   return @[
       @"testCanWriteHeader",
       @"testCanWriteStringsToStringTable",
       @"testCanWriteGlobalSymboltable",
       @"testWriteLinkableAddFunction",
		];
}

@end
