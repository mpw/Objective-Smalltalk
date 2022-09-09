//
//  MPWMachOReader.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 09.09.22.
//

#import "MPWMachOReader.h"
#import <mach-o/loader.h>

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
            struct segment_command_64 *segment=(struct segment_command_64 *)cur;
            return segment;
//            return [self.data subdataWithRange:NSMakeRange( segment->fileoff, segment->filesize)];
        }
    }
    @throw [NSException exceptionWithName:@"nosegment" reason:@"No segment found" userInfo:nil];
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
    NSString *segmentName = @(segment->segname);
    IDEXPECT( segmentName, @"", @"segment name");
    struct section_64 *first_section = ((void*)segment) + sizeof *segment;
    NSString *sect1Name = @(first_section->sectname);
    IDEXPECT( sect1Name, @"__text", @"section 1 name");

    struct section_64 *second_section = ((void*)first_section) + sizeof *first_section;
    NSString *sect2Name = @(second_section->sectname);
    IDEXPECT( sect2Name, @"__compact_unwind__LD", @"section 2 name");
}


+(NSArray*)testSelectors
{
   return @[
       @"testCanIdentifyHeader",
       @"testFiletype",
       @"testLoadCommands",
       @"testReadSegment",
			];
}

@end
