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

-(int)symbolTableOffset
{
    return self.loadCommandSize + sizeof(struct mach_header_64);
}

-(void)writeSymbolTableLoadCommand
{
    struct symtab_command symtab={};
    symtab.cmd = LC_SYMTAB;
    symtab.cmdsize = sizeof symtab;
    symtab.nsyms = (int)self.globalSymbols.count;
    symtab.symoff = [self symbolTableOffset];
    [self appendBytes:&symtab length:sizeof symtab];
}

-(int)stringTableOffsetOfString:(NSString*)theString
{
    int offset = [self.stringTableOffsets[theString] intValue];
    if ( !offset ) {
        offset=(int)[self.stringTableWriter length];
        [self.stringTableWriter writeObject:theString];
        self.stringTableOffsets[theString]=@(offset);
    }
    return offset;
}

-(void)writeSymbolTable
{
    NSAssert2(self.length == [self symbolTableOffset], @"Actual symbol table offset %d does not match computed %d", self.length,[self symbolTableOffset]);
    NSLog(@"offset before writing symbol table:%ld",self.length);
    NSDictionary *symbols=self.globalSymbols;
    for (NSString* symbol in symbols.allKeys) {
        symtab_entry entry={};
        entry.type = 0x0f;
        entry.string_offset=[self stringTableOffsetOfString:symbol];
        entry.address = [symbols[symbol] longValue];
        NSLog(@"offset[%@]=%ld",symbol,entry.address);
        [self appendBytes:&entry length:sizeof entry];
    }
}


-(NSData*)data
{
    return (NSData*)self.target;
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
    writer.numLoadCommands = 1;
    writer.loadCommandSize = sizeof(struct symtab_command);
    [writer writeHeader];
    [writer writeSymbolTableLoadCommand];
    [writer writeSymbolTable];

    
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/generated.macho" atomically:YES];
    MPWMachOReader *reader = [[[MPWMachOReader alloc] initWithData:macho] autorelease];

    EXPECTTRUE([reader isHeaderValid],@"valid header");
    INTEXPECT([reader numLoadCommands],1,@"number of load commands");
    INTEXPECT([reader numSymbols],1,@"number of symbols");
    NSArray *strings = [reader stringTable];
    EXPECTTRUE([reader isSymbolGlobalAt:0],@"first symbol _add is global");
//    INTEXPECT([reader symbolOffsetAt:0],10,@"offset of _add");
//    IDEXPECT( strings, (@[@"_add"]), @"string table");
}

+(void)testCanWriteStringsToStringTable
{
    MPWMachOWriter *writer = [self stream];
    INTEXPECT( [writer stringTableOffsetOfString:@"_add"],1,@"offset");
    INTEXPECT( [writer stringTableOffsetOfString:@"_sub"],5,@"offset");
    INTEXPECT( [writer stringTableOffsetOfString:@"_add"],1,@"repeat");
}

+(NSArray*)testSelectors
{
   return @[
       @"testCanWriteHeader",
       @"testCanWriteStringsToStringTable",
       @"testCanWriteGlobalSymboltable",
		];
}

@end
