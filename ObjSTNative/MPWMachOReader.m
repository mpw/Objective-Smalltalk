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
#import "Mach_O_Structs.h"
#import "MPWMachOSection.h"
#import "MPWMachORelocationPointer.h"
#import "MPWMachOInSectionPointer.h"
#import "MPWMachOClassReader.h"

@interface MPWMachOReader()

@property (nonatomic, strong) NSData *data;

@end

@implementation MPWMachOReader


CONVENIENCEANDINIT(reader, WithData:(NSData*)machodata)
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

-(long)segmentOffset
{
    return [self segment]->fileoff;
}

-(long)segmentSize
{
    return [self segment]->filesize;
}

-(const void*)segmentBytes
{
    return [self bytes] + [self segmentOffset];
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

-(MPWMachOSection*)sectionWithSectionHeader:(struct section_64*)header
{
    return header ? [[[MPWMachOSection alloc] initWithSectionHeader:header inMacho:self] autorelease] : nil;
}

-(MPWMachOSection*)sectionWithName:(const char*)name
{
    return [self sectionWithSectionHeader:[self sectionHeaderWithName:name]];
}

-(MPWMachOSection*)textSection
{
    return [self sectionWithName:"__text"];
}

-(void)dumpRelocationsOn:(MPWByteStream*)s
{
    for (int i=1;i<[self numSections];i++) {
        [[self sectionAtIndex:i] dumpRelocationsOn:s];
    }
}

-(MPWMachOSection*)sectionAtIndex:(int)sectionIndex
{
    struct segment_command_64 *segment=[self segment];
    struct section_64 *sections=(struct section_64*)(segment + 1);
    NSAssert(sectionIndex >=1 && sectionIndex <= segment->nsects, @"section index out of range");
    return [self sectionWithSectionHeader:sections+sectionIndex-1];
}

-(MPWMachOSection*)objcClassNameSection
{
    return [self sectionWithName:"__objc_classname"];
}

-(MPWMachOSection*)objcClassReadOnlySection
{
    return [self sectionWithName:"__objc_const"];
}

-(MPWMachOSection*)objcDataSection
{
    return [self sectionWithName:"__objc_data"];
}

-(MPWMachOSection*)cfstringSection
{
    return [self sectionWithName:"__cfstring"];
}

-(MPWMachOSection*)objcClassListSection
{
    return [self sectionWithName:"__objc_classlist"];
}

-(MPWMachOSection*)objcClassReferenceSection
{
    return [self sectionWithName:"__objc_classref"];
}

-(MPWMachOSection*)objcMethodNamesSection
{
    return [self sectionWithName:"__objc_methname"];
}

-(int)numberOfClasses
{
    return [self.objcClassListSection numRelocEntries];
}


-(NSArray<MPWMachORelocationPointer*>*)classPointers
{
    MPWMachOSection *classListSection=self.objcClassListSection;
    NSMutableArray *classes = [NSMutableArray array];
    for (int i=0;i<[self numberOfClasses];i++) {
        [classes addObject:[[[MPWMachORelocationPointer alloc] initWithSection:classListSection relocEntryIndex:i] autorelease]];;
    }
    return classes;
}

-(int)numberOfClassReferences
{
    return [self.objcClassReferenceSection numRelocEntries];
}

-(NSArray<MPWMachORelocationPointer*>*)classReferences
{
    MPWMachOSection *classRefSection=self.objcClassReferenceSection;
    NSMutableArray *classes = [NSMutableArray array];
    for (int i=0;i<[self numberOfClassReferences];i++) {
        [classes addObject:[[[MPWMachORelocationPointer alloc] initWithSection:classRefSection relocEntryIndex:i] autorelease]];;
    }
    return classes;
}

-(NSArray<NSString*>*)classReferenceNames
{
    int prefixLen=@"_OBJC_CLASS_$_".length;
    NSArray *targetNames = [[[self classReferences] collect] targetName];
    NSArray *classNames = [[targetNames collect] substringFromIndex:prefixLen];
    return classNames;
}

-(NSArray<MPWMachOClassReader*>*)classReaders
{
    return [[MPWMachOClassReader collect] readerWithPointer:[[self classPointers] each] ];
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

-(int)sectionForSymbolAt:(int)which
{
    symtab_entry *entry=[self entryAt:which];
    return entry->section;
}

-(long)symbolOffsetAt:(int)which
{
    return [self entryAt:which]->address;
}

-(bool)isSymbolGlobalAt:(int)which
{
    return ([self entryAt:which]->type & N_EXT) != 0;
}

-(int)indexOfSymbolNamed:(NSString*)symbol
{
    struct symtab_command *symtab=[self symtab];
    for (int i=0; i< symtab->nsyms;i++) {
        if ( [[self symbolNameAt:i] isEqual:symbol]) {
            return i;
        }
    }
    return -1;
}

-(bool)isSymbolUndefined:(int)which
{
    symtab_entry *entry = [self entryAt:which];
    
    return (entry->section) == 0 && (entry->type & N_EXT);
}

-(MPWMachOInSectionPointer*)pointerForSymbolAt:(int)symbolIndex
{
    MPWMachOSection *section = [self sectionAtIndex:[self sectionForSymbolAt:symbolIndex]];
    
    return [[[MPWMachOInSectionPointer alloc] initWithSection:section offset:[self symbolOffsetAt:symbolIndex]-[section address]] autorelease];
}

-(void)verifyBlockDescriptor:(MPWMachOInSectionPointer*)descriptorPointer signature:(NSString*)signature signatureSymbol:(NSString*)symbol
{
    const Mach_O_BlockDescriptor *descriptor = [descriptorPointer bytes];
    INTEXPECT( descriptor->size, sizeof *descriptor, @"size");
    long signatureOffset = ((void*)&(descriptor->signature) - (void*)descriptor);
    INTEXPECT(signatureOffset,16,@"signatureoffset (from block descriptor)");
    MPWMachORelocationPointer *signaturePointer = [descriptorPointer relocationPointerAtOffset:signatureOffset];
    IDEXPECT( [signaturePointer targetName],symbol,@"symbol of signature");
    IDEXPECT( [[signaturePointer targetPointer] stringValue], signature, @"signature");
}

-(MPWMachOInSectionPointer*)verifyBlockAndReturnDescriptor:(MPWMachOInSectionPointer *)blockPointer codeSymbol:(NSString*)codeSymbol descriptorSymbol:(NSString*)descriptorSymbol
{
    struct Block_struct *b=(struct Block_struct*)[blockPointer bytes];
    long blockCodePointerOffset = ((void*)&(b->invoke) - (void*)b);
    long blockDescriptorPointerOffset = ((void*)&(b->descriptor) - (void*)b);
    INTEXPECT( blockDescriptorPointerOffset, 24,@"blockDescriptorPointerOffset");
    HEXEXPECT( b->flags, 0x50000000,@"flags");
    INTEXPECT( b->reserved, 0,@"reserved");
    IDEXPECT([[blockPointer relocationPointerAtOffset:blockCodePointerOffset] targetName],codeSymbol,@"invoke fn");
//    IDEXPECT([[blockPointer relocationPointer] targetName],@"__NSConcreteGlobalBlock",@"block class reference");
    MPWMachORelocationPointer *block2descriptor=[blockPointer relocationPointerAtOffset:blockDescriptorPointerOffset];
    IDEXPECT([block2descriptor targetName],descriptorSymbol,@"descriptor");
    MPWMachOInSectionPointer *descriptorPointer=[block2descriptor targetPointer];
    return descriptorPointer;
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachOReader(testing) 

+(instancetype)readerForTestFile:(NSString*)name
{
    NSData *addmacho=[self frameworkResource:name category:@"macho"];
    MPWMachOReader *reader=[[[self alloc] initWithData:addmacho] autorelease];
    return reader;
}

+(instancetype)readerForAdd
{
    return [self readerForTestFile:@"add"];
}

+(instancetype)readerForExternalFunction
{
    return [self readerForTestFile:@"call-external-fn"];
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
    NSData *textSection=[[reader textSection] sectionData];
    INTEXPECT(textSection.length,32,@"length of text section");
    const unsigned char *machineCode=[textSection bytes];
    const unsigned char expectedMachineCode[]={ 0xff, 0x43,0x00,0xd1, 0xe0, 0x0f, 0x00,0xb9 };
    for (int i=0; i<sizeof expectedMachineCode;i++ ) {
        INTEXPECT(machineCode[i],expectedMachineCode[i],@"machine code");
    }
    INTEXPECT([reader segmentOffset],392,@"segment offset");
    
}


+(void)testReadSymtab
{
    MPWMachOReader *reader=[self readerForAdd];
    struct symtab_command *symtab=[reader symtab];
    EXPECTNOTNIL(symtab,@"have a symtab");
    
    INTEXPECT([reader numSymbols],3,@"number of symbols");
    IDEXPECT([reader symbolNameAt:0],@"ltmp0",@"first symbol");
    IDEXPECT([reader symbolNameAt:1],@"ltmp1",@"2nd symbol");
    IDEXPECT([reader symbolNameAt:2],@"_add",@"3rd symbol");
    
    INTEXPECT([reader indexOfSymbolNamed:@"_add"],2,@"index of _add in table");
    INTEXPECT([reader indexOfSymbolNamed:@"_not_there"],-1,@"index of non-existent entry");
    INTEXPECT([reader indexOfSymbolNamed:@"ltmp1"],1,@"index of non-existent entry");

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
    INTEXPECT([[reader textSection] numRelocEntries],1,@"number of undefined symbol reloc entries");
    INTEXPECT([[reader textSection] relocEntryOffset],0x1c0,@"offset of undefined symbol reloc entries");
    INTEXPECT([[reader textSection] typeOfRelocEntryAt:0],ARM64_RELOC_BRANCH26,@"reloc entry type");
    IDEXPECT([[reader textSection] nameOfRelocEntryAt:0],@"_other",@"external symbol");
    INTEXPECT([[reader textSection] offsetOfRelocEntryAt:0],8,@"address");
    EXPECTTRUE([[reader textSection] isExternalRelocEntryAt:0],@"external");
}

+(void)testGetClassPointers
{
    MPWMachOReader *reader=[self readerForTestFile:@"two-classes"];
    NSArray<MPWMachORelocationPointer*> *classPointers = [reader classPointers];
    INTEXPECT( classPointers.count, 2, @"number of classes");
    IDEXPECT( classPointers[0].targetName, @"_OBJC_CLASS_$_SecondClass",@"First class in list");
    IDEXPECT( classPointers[1].targetName, @"_OBJC_CLASS_$_FirstClass",@"Last class in list");
//    NSLog(@"will dump relocations in two-clases.macho:");
 //   [reader dumpRelocationsOn:[MPWByteStream Stderr]];
    
}

+(void)testReadObjectiveC_StringConstant
{
    MPWMachOReader *reader=[self readerForTestFile:@"function-passing-nsstring"];
    int cfstringSymbolIndex = [reader indexOfSymbolNamed:@"l__unnamed_cfstring_"];
    INTEXPECT( cfstringSymbolIndex,1,@"index of the cfstring");
    MPWMachOInSectionPointer *stringPointer=[reader pointerForSymbolAt:cfstringSymbolIndex];
    EXPECTNOTNIL(stringPointer, @"stringPointer");
    IDEXPECT([[stringPointer section] sectionName],@"__cfstring",@"section");
    Mach_O_NSString *s=(Mach_O_NSString*)[stringPointer bytes];
    INTEXPECT(s->length,2,@"length");
    INTEXPECT(s->flags,1992,@"flags");
    INTEXPECT([stringPointer offset],0,@"offset");
    MPWMachORelocationPointer *stringClassPtr=[stringPointer relocationPointer];
    EXPECTNOTNIL(stringClassPtr, @"stringClassPtr");
    IDEXPECT(stringClassPtr.targetName,@"___CFConstantStringClassReference",@"string class name");
    long cStringPtrOffset = ((void*)&(s->cstring) - (void*)s);
    INTEXPECT( cStringPtrOffset,16,@"");
    MPWMachORelocationPointer *stringContentsPointer=[stringPointer relocationPointerAtOffset:cStringPtrOffset];
    EXPECTNOTNIL(stringContentsPointer, @"stringContentsPointer");
    IDEXPECT(stringContentsPointer.targetName,@"l_.str",@"");
    IDEXPECT([[stringContentsPointer targetPointer] stringValue],@"hi",@"actual string value");
}

#define VERIFYUSING( method, arg ) @try { [self method:arg]; } @catch (NSException *e) { \
NSString *reason=[NSString stringWithFormat:@"checking using %@ failed: %@",@""#method,[e reason]]; \
    EXPECTTRUE(false,reason);\
}


+(void)testReadBlock
{
    MPWMachOReader *reader=[self readerForTestFile:@"function-passing-block"];
    int blockIndex = [reader indexOfSymbolNamed:@"___block_literal_global"];
    MPWMachOInSectionPointer *blockPointer=[reader pointerForSymbolAt:blockIndex];
    EXPECTNOTNIL(blockPointer, @"block pointer");
    MPWMachOInSectionPointer *descriptorPointer=[reader verifyBlockAndReturnDescriptor:blockPointer codeSymbol:@"___bfn_block_invoke" descriptorSymbol:@"___block_descriptor_tmp"];
//    VERIFYUSING(verifyDescriptor, descriptorPointer);
    [reader verifyBlockDescriptor:descriptorPointer signature:@"i12@?0i8" signatureSymbol:@"l_.str"];

}

+(void)testReadClassReferences
{
    MPWMachOReader *reader=[self readerForTestFile:@"use_class"];
    EXPECTNOTNIL(reader, @"reader for use_class.macho");
    INTEXPECT(reader.numberOfClassReferences,2,@"number of class references");
    NSArray <MPWMachORelocationPointer*> *refs=[reader classReferences];
    INTEXPECT(refs.count,2,@"number of refs again");
    MPWMachORelocationPointer *first=refs.firstObject;
    MPWMachORelocationPointer *last=refs.lastObject;

    IDEXPECT(first.targetName, @"_OBJC_CLASS_$_NSObject",@"class ref");
    IDEXPECT(last.targetName, @"_OBJC_CLASS_$_NSNumber",@"class ref");
    NSArray *names=[reader classReferenceNames];
    NSArray *expectedNames = @[ @"NSObject", @"NSNumber"];
    IDEXPECT( names, expectedNames, @"class names");
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
       @"testGetClassPointers",
       @"testReadObjectiveC_StringConstant",
       @"testReadBlock",
       @"testReadClassReferences",

			];
}

@end
