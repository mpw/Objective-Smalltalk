//
//  MPWMachOReader.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 09.09.22.
//

#import "MPWMachOReader.h"
#import <mach-o/loader.h>
#import <nlist.h>

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

-(struct mach_header_64*)header
{
    return (struct mach_header_64*)[[self data] bytes];
}

-(BOOL)isHeaderValid
{
    struct mach_header_64 *header=[self header];
    return header->magic == MH_MAGIC_64;
}

-(uint32_t)filetype
{
    return [self header]->filetype;
}

-(uint32_t)numLoadCommands
{
    return [self header]->ncmds;
}

-(uint32_t)sizeOfLoadCommands
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

-(struct segment_command_64*)segment
{
    const struct load_command *cur=[self.data bytes] + sizeof(struct mach_header_64);
    for (int i=0, max=[self numLoadCommands]; i<max; i++) {
        if ( cur->cmd == LC_SEGMENT_64) {
            return (struct segment_command_64 *)cur;
        }
        cur = ((void*)cur)+cur->cmdsize;
    }
    @throw [NSException exceptionWithName:@"nosegment" reason:@"No segment found" userInfo:nil];
}

-(struct symtab_command*)symtab
{
    const struct load_command *cur=[self.data bytes] + sizeof(struct mach_header_64);
    for (int i=0, max=[self numLoadCommands]; i<max; i++) {
        if ( cur->cmd == LC_SYMTAB) {
            return (struct symtab_command *)cur;
        }
        cur = ((void*)cur)+cur->cmdsize;
    }
    @throw [NSException exceptionWithName:@"nosymtab" reason:@"No symtab found" userInfo:nil];
    return nil;
}



@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachOReader(testing) 

+(instancetype)readerForAdd
{
    NSData *addmacho=[self frameworkResource:@"add" category:@"macho"];
    MPWMachOReader *reader=[[[self alloc] initWithData:addmacho] autorelease];
    return reader;
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
}

typedef struct {
    int string_offset;
    char a,b;
    short pad;
    long address;
} symtab_entry;

+(void)testReadSymtabAndStringTable
{
    MPWMachOReader *reader=[self readerForAdd];
    struct symtab_command *symtab=[reader symtab];
    EXPECTNOTNIL(symtab,@"have a symtab");
    INTEXPECT(symtab->nsyms,3,@"number of symbols");
    INTEXPECT(symtab->symoff,464,@"symtab offset");
    INTEXPECT(symtab->stroff,512,@"string table offset");
    INTEXPECT(symtab->strsize,24,@"string table size");
    
    INTEXPECT( ((symtab->stroff - symtab->symoff)), (sizeof(struct nlist) * 2),@"string table size");

    
    char *str1 = [reader.data bytes] + symtab->stroff +1;
    IDEXPECT(@(str1), @"_add",@"first string table entry");
    char *str2=str1 + strlen(str1)+1;
    IDEXPECT(@(str2), @"ltmp1",@"second string table entry");
    char *str3=str2 + strlen(str2)+1;
    IDEXPECT(@(str3), @"ltmp0",@"third string table entry");

    
    char *firstbyte = [reader.data bytes] + symtab->symoff;
    symtab_entry *entries = (symtab_entry*)firstbyte;
    INTEXPECT( entries[0].string_offset, 12, @"offset into string table of first symtab entry ");
    INTEXPECT( entries[1].string_offset, 6, @"offset into string table of second symtab entry ");
    INTEXPECT( entries[2].string_offset, 1, @"offset into string table of third symtab entry ");

    
    
}

+(NSArray*)testSelectors
{
   return @[
       @"testCanIdentifyHeader",
       @"testFiletype",
       @"testLoadCommands",
       @"testReadSegment",
       @"testReadSymtabAndStringTable",
			];
}

@end
