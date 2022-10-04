//
//  MPWMachOReader.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 09.09.22.
//

#import "MPWMachOReader.h"
#import <mach-o/loader.h>
#import <nlist.h>
#import <mach-o/reloc.h>
#import <mach-o/arm64/reloc.h>
#import "SymtabEntry.h"
#import "MPWMachOSection.h"

@interface MPWMachOReader()

@property (nonatomic, strong) NSData *data;

@end

@implementation MPWMachOReader

-(instancetype)initWithData:(NSData*)machodata
{
    if ( machodata ) {
        self=[super init];
        self.data = machodata;
        return self;
    } else {
        return nil;
    }
}

-(const void*)bytes
{
    return [[self data] bytes];
}

-(struct mach_header_64*)header
{
    return (struct mach_header_64*)[self bytes];
}

-(BOOL)isHeaderValid
{
    
    struct mach_header_64 *header=[self header];
    return (self.data.length >= sizeof *header) &&
            (header->magic == MH_MAGIC_64);
}


-(int)cputype
{
    return [self header]->cputype;
}

-(int)cpusubtype
{
    return [self header]->cpusubtype;
}

-(int)filetype
{
    return [self header]->filetype;
}

-(int)numLoadCommands
{
    return [self header]->ncmds;
}

-(int)sizeOfLoadCommands
{
    return [self header]->sizeofcmds;
}

-(struct load_command)loadCommandAtIndex:(int)lindex
{
    const struct load_command *cur=[self.data bytes] + sizeof(struct mach_header_64);
    for (int i=0, max=MIN(lindex,[self numLoadCommands]); i<max; i++) {
        cur = ((void*)cur)+cur->cmdsize;
    }
    return *cur;
}

-(const struct load_command*)loadCommandOfType:(int)commandType
{
    const struct load_command *cur=[self.data bytes] + sizeof(struct mach_header_64);
    for (int i=0, max=[self numLoadCommands]; i<max; i++) {
        if ( cur->cmd == commandType) {
            return cur;
        }
        cur = ((void*)cur)+cur->cmdsize;
    }
    @throw [NSException exceptionWithName:@"noloadcommand" reason:@"Load Command not found" userInfo:nil];
    return nil;
}

-(struct segment_command_64*)segment
{
    return (struct segment_command_64*)[self loadCommandOfType:LC_SEGMENT_64];
}

-(int)numSections
{
    return [self segment]->nsects;
}

-(struct section_64*)sectionHeaderWithName:(const char*)name
{
    struct segment_command_64 *segment=[self segment];
    long len=strlen(name);
    len=MIN(len,16);
    struct section_64 *sections=(struct section_64*)(segment + 1);
    for (int i=0; i < segment->nsects;i++) {
        if ( !strncmp(sections[i].sectname, name, len ) ) {
            return sections+i;
        }
    }
    return nil;
}

-(struct section_64*)textSectionHeader
{
    return [self sectionHeaderWithName:"__text"];
}

-(MPWMachOSection*)textSection
{
    
}

-(struct section_64*)objcClassNameSectionHeader
{
    return [self sectionHeaderWithName:"__objc_classname"];
}

-(NSString*)objcClassName
{
    struct section_64 *classSect=[self objcClassNameSectionHeader];
    NSString *name=nil;
    if ( classSect ) {
        name=[NSString stringWithUTF8String:[self bytes] + classSect->offset];
    }
    return name;
}

-(NSData*)textSectionData
{
    struct section_64 *textSection=[self textSectionHeader];
    if (textSection) {
        return [self.data subdataWithRange:NSMakeRange(textSection->offset,textSection->size)];
    }
    return nil;
}

-(struct symtab_command*)symtab
{
    return (struct symtab_command*)[self loadCommandOfType:LC_SYMTAB];
}

-(struct dysymtab_command*)dsymtab
{
    return (struct dysymtab_command*)[self loadCommandOfType:LC_DYSYMTAB];
}

-(NSArray<NSString*>*)stringTable
{
    NSMutableArray *strings = [NSMutableArray array];
    struct symtab_command *symtab=[self symtab];
    const char *str = [self.data bytes] + symtab->stroff +1;
    const char *end = str + symtab->strsize;
    while ( str < end - 1 ) {
        NSString *entry = @(str);
        if (entry.length) {
            [strings addObject:@(str)];
        }
        str += strlen(str)+1;
    }
    return strings;
}

-(int)numSymbols
{
    return [self symtab]->nsyms;
}


-(symtab_entry*)entryAt:(int)which
{
    struct symtab_command *symtab=[self symtab];
    const char *firstbyte = [self.data bytes] + symtab->symoff;
    symtab_entry *entries = (symtab_entry*)firstbyte;
    return entries + which;
}

-(NSString*)symbolNameAt:(int)which
{
    struct symtab_command *symtab=[self symtab];
    symtab_entry *entry=[self entryAt:which];
    const char *firststr = [self.data bytes] + symtab->stroff;
    return @(firststr + entry->string_offset);
}

-(long)symbolOffsetAt:(int)which
{
    return [self entryAt:which]->address;
}

-(bool)isSymbolGlobalAt:(int)which
{
    return ([self entryAt:which]->type & N_EXT) != 0;
}

-(bool)isSymbolUndefined:(int)which
{
    symtab_entry *entry = [self entryAt:which];
    
    return (entry->section) == 0 && (entry->type & N_EXT);
}

-(int)numRelocEntries
{
    return [self textSectionHeader]->nreloc;
}

-(int)relocEntryOffset
{
    return [self textSectionHeader]->reloff;
}

-(struct relocation_info)relocEntryAt:(int)i
{
    const struct relocation_info *reloc=[self.data bytes] + [self relocEntryOffset];
    return reloc[i];
}

-(NSString*)nameOfRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:0];
    return [self symbolNameAt:reloc.r_symbolnum];
}

-(long)offsetOfRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:0];
    return reloc.r_address;
}

-(int)typeOfRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:0];
    return reloc.r_type;
}



-(bool)isExternalRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:0];
    return reloc.r_extern != 0;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachOReader(testing) 

+(instancetype)readerForTestfile:(NSString*)name
{
    NSData *addmacho=[self frameworkResource:name category:@"macho"];
    MPWMachOReader *reader=[[[self alloc] initWithData:addmacho] autorelease];
    return reader;
}

+(instancetype)readerForAdd
{
    return [self readerForTestfile:@"add"];
}

+(instancetype)readerForExternalFunction
{
    return [self readerForTestfile:@"call-external-fn"];
}

+(instancetype)readerForObjectiveCClass
{
    return [self readerForTestfile:@"class-with-method"];
}

+(void)testCanIdentifyHeader
{
    MPWMachOReader *reader=[self readerForAdd];
    EXPECTTRUE([reader isHeaderValid], @"got the right header");
    NSData *notamacho = [@"Hello World!" asData];
    reader=[[[self alloc] initWithData:notamacho] autorelease];
    EXPECTFALSE([reader isHeaderValid], @"not a Mach-O header");
}

+(void)testFiletype
{
    MPWMachOReader *reader=[self readerForAdd];
    INTEXPECT([reader filetype], MH_OBJECT, @"should be an object file");
}

+(void)testCPUType
{
    MPWMachOReader *reader=[self readerForAdd];
    INTEXPECT([reader cputype], CPU_TYPE_ARM64, @"should be ARM");
    INTEXPECT([reader cpusubtype], 0, @"subytep");
}

+(void)testLoadCommands
{
    MPWMachOReader *reader=[self readerForAdd];
    INTEXPECT([reader numLoadCommands], 4, @"number of load commands");
    INTEXPECT([reader sizeOfLoadCommands], 360, @"size of load commands");
    struct load_command first=[reader loadCommandAtIndex:0];
    INTEXPECT(first.cmd, LC_SEGMENT_64, @"first load command is LC_SEGMENT");
    INTEXPECT(first.cmdsize, 232, @"segment size");

    struct load_command second=[reader loadCommandAtIndex:1];
    INTEXPECT(second.cmd, LC_BUILD_VERSION, @"second load command minimum build version");
    INTEXPECT(second.cmdsize, 24, @"second load command size");
    
    struct load_command third=[reader loadCommandAtIndex:2];
    INTEXPECT(third.cmd, LC_SYMTAB, @"third load command: symtab");
    INTEXPECT(third.cmdsize, 24, @"symtab size");
    
    struct load_command last=[reader loadCommandAtIndex:3];
    INTEXPECT(last.cmd, LC_DYSYMTAB, @"last load command: dynamic link-edit symbol table info");
    INTEXPECT(last.cmdsize, 80, @" size");
    
}

+(void)testReadSegment
{
    MPWMachOReader *reader=[self readerForAdd];
    struct segment_command_64 *segment=[reader segment];
    INTEXPECT( segment->nsects, 2, @"number of sections");
    INTEXPECT( segment->cmdsize, sizeof(struct segment_command_64)+2*sizeof(struct section_64),@"correct size");
    INTEXPECT( segment->fileoff, 392, @"segment offset");
    INTEXPECT( segment->filesize, 64, @"segment size");
    NSString *segmentName = @(segment->segname);
    IDEXPECT( segmentName, @"", @"segment name");
    struct section_64 *text_section = ((void*)segment) + sizeof *segment;
    NSString *sect1Name = @(text_section->sectname);
    IDEXPECT( sect1Name, @"__text", @"section 1 name");
    INTEXPECT( text_section->offset, 392,@"text section offset");
    INTEXPECT( text_section->size, 32,@"text section size");
    struct section_64 *unwind_section = ((void*)text_section) + sizeof *text_section;
    NSString *sect2Name = @(unwind_section->sectname);
    IDEXPECT( sect2Name, @"__compact_unwind__LD", @"section 2 name");
    INTEXPECT( unwind_section->offset, 424,@"unwind section offset");
    INTEXPECT( unwind_section->size, 32,@"unwind section size");
    NSData *textSection=[reader textSectionData];
    INTEXPECT(textSection.length,32,@"length of text section");
    const unsigned char *machineCode=[textSection bytes];
    const unsigned char expectedMachineCode[]={ 0xff, 0x43,0x00,0xd1, 0xe0, 0x0f, 0x00,0xb9 };
    for (int i=0; i<sizeof expectedMachineCode;i++ ) {
        INTEXPECT(machineCode[i],expectedMachineCode[i],@"machine code");
    }
}


+(void)testReadSymtab
{
    MPWMachOReader *reader=[self readerForAdd];
    struct symtab_command *symtab=[reader symtab];
    EXPECTNOTNIL(symtab,@"have a symtab");
    
    INTEXPECT([reader numSymbols],3,@"number of symbols");
    IDEXPECT([reader symbolNameAt:0],@"ltmp0",@"first symbol")
    IDEXPECT([reader symbolNameAt:1],@"ltmp1",@"2nd symbol")
    IDEXPECT([reader symbolNameAt:2],@"_add",@"3rd symbol")
    
    INTEXPECT([reader symbolOffsetAt:0],0,@"ltmp0 symbol offset")
    INTEXPECT([reader symbolOffsetAt:1],32,@"ltmp1 symbol offset")
    INTEXPECT([reader symbolOffsetAt:2],0,@"_add symbol offset")
    
    EXPECTFALSE([reader isSymbolGlobalAt:0],@"ltmp0 local")
    EXPECTFALSE([reader isSymbolGlobalAt:1],@"ltmp1 local")
    EXPECTTRUE([reader isSymbolGlobalAt:2],@"_add global")
    
    INTEXPECT(symtab->symoff,464,@"symtab offset");
    INTEXPECT(symtab->stroff,512,@"string table offset");
    INTEXPECT(symtab->strsize,24,@"string table size");

}

+(void)testReadStringTable
{
    MPWMachOReader *reader=[self readerForAdd];
    NSArray *strings = [reader stringTable];
    NSArray *expectedStrings=@[ @"_add",@"ltmp1",@"ltmp0" ];
    IDEXPECT( strings, expectedStrings, @"string table")
}

+(void)testReadMachOWithExternalSymbols
{
    MPWMachOReader *reader=[self readerForExternalFunction];
    INTEXPECT( reader.numLoadCommands, 4 , @"load commands");
    INTEXPECT( reader.numSections, 2 , @"load commands");
    IDEXPECT( [reader symbolNameAt:2],@"_fn",@"defined function");
    EXPECTFALSE( [reader isSymbolUndefined:2],@"_add should not be undefined");
    IDEXPECT( [reader symbolNameAt:3],@"_other",@"referenced function");
    EXPECTTRUE( [reader isSymbolUndefined:3],@"_other should be undefined");
    INTEXPECT([reader symbolOffsetAt:3],0,@"offset of undefined symbols is 0");
    INTEXPECT([reader numRelocEntries],1,@"number of undefined symbol reloc entries");
    INTEXPECT([reader relocEntryOffset],0x1c0,@"offset of undefined symbol reloc entries");
    INTEXPECT([reader typeOfRelocEntryAt:0],ARM64_RELOC_BRANCH26,@"reloc entry type");
    IDEXPECT([reader nameOfRelocEntryAt:0],@"_other",@"external symbol");
    INTEXPECT([reader offsetOfRelocEntryAt:0],8,@"address");
    EXPECTTRUE([reader isExternalRelocEntryAt:0],@"external");
}

+(void)testReadObjectiveCSections
{
    MPWMachOReader *reader=[self readerForObjectiveCClass];
    INTEXPECT( reader.numLoadCommands, 4 , @"load commands");
    INTEXPECT( reader.numSections, 9 , @"sections");
    IDEXPECT( [reader objcClassName], @"Hi", @"Objective-C classname");
    
}


+(NSArray*)testSelectors
{
   return @[
       @"testCanIdentifyHeader",
       @"testFiletype",
       @"testCPUType",
       @"testLoadCommands",
       @"testReadSegment",
       @"testReadSymtab",
       @"testReadStringTable",
       @"testReadMachOWithExternalSymbols",
       @"testReadObjectiveCSections",
			];
}

@end
