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
#import "Mach_O_Structs.h"
#import "MPWMachOSection.h"
#import "MPWMachOSectionWriter.h"

@interface MPWMachOWriter()

@property (nonatomic, assign) int numLoadCommands;
@property (nonatomic, assign) int cputype;
@property (nonatomic, assign) int filetype;
@property (nonatomic, assign) int loadCommandSize;
@property (nonatomic, assign) long totalSegmentSize;
@property (nonatomic, strong) NSMutableDictionary *stringTableOffsets;
@property (nonatomic, strong) MPWByteStream *stringTableWriter;

@property (nonatomic, strong) NSMutableDictionary *globalSymbolOffsets;
@property (nonatomic, strong) NSDictionary *externalSymbols;

@property (nonatomic, strong) MPWMachOSectionWriter *textSectionWriter;
@property (nonatomic, strong) NSMutableArray<MPWMachOSectionWriter*>* sectionWriters;

//@property (nonatomic, strong) NSMutableDictionary *relocationEntries;



@end


@implementation MPWMachOWriter
{
    symtab_entry *symtab;
    int symtabCount;
    int symtabCapacity;
}


-(void)addSectionWriter:(MPWMachOSectionWriter*)newWriter
{
    int sectionNumber = (int)self.sectionWriters.count;
    newWriter.sectionNumber = sectionNumber;
    newWriter.symbolWriter = self;

    [self.sectionWriters addObject:newWriter];
}

-(NSArray<MPWMachOSectionWriter*>*)activeSectionWriters
{
    NSMutableArray *active=[NSMutableArray array];
    for (MPWMachOSectionWriter *writer in self.sectionWriters) {
        if ( writer.isActive) {
            [active addObject:writer];
        }
    }
    return active;
}

-(MPWMachOSectionWriter*)addSectionWriterWithSegName:(NSString*)segname sectName:(NSString*)sectname flags:(int)flags
{
    if (!self.sectionWriters) {
        self.sectionWriters = [NSMutableArray array];
    }
    MPWMachOSectionWriter *writer=[MPWMachOSectionWriter stream];
    writer.segname = segname;
    writer.sectname = sectname;
    writer.flags = flags;
    [self addSectionWriter:writer];
    return writer;
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
        self.textSectionWriter = [self addSectionWriterWithSegName:@"__TEXT" sectName:@"__text" flags:S_ATTR_PURE_INSTRUCTIONS | S_ATTR_SOME_INSTRUCTIONS];
        self.textSectionWriter.relocationType=ARM64_RELOC_BRANCH26;
        [self addSectionWriterWithSegName:@"__DATA" sectName:@"_objectclasslist" flags:0];
        symtabCapacity = 10;
        [self growSymtab];
        
        
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

-(int)segmentOffset
{
    return self.loadCommandSize + sizeof(struct mach_header_64);
}

-(int)symbolTableOffset
{
    return [self segmentOffset] + self.totalSegmentSize;
}


-(int)numSymbols
{
    return symtabCount;
}

-(int)symbolTableSize
{
    return [self numSymbols] * sizeof(symtab_entry);
}

-(int)stringTableOffset
{
    return [self symbolTableOffset] + [self symbolTableSize];
}

-(int)segmentCommandSize
{
    return sizeof(struct segment_command_64) + ([self activeSectionWriters].count * sizeof(struct section_64));
}

-(void)adjustSymtabEntries
{
    int numSections = [self sectionWriters].count;
    int sectionNumberRemap[numSections];
    int segmentToSectionOfffset[numSections];
    int offsets[[self activeSectionWriters].count ];
    NSArray<MPWMachOSectionWriter*> *activeWriters=[self sectionWriters];
    
//    for (int i=0,max=activeWriters.count;i<max;i++) {
//        sectionNumberRemap[activeWriters[i].sectionNumber]=i;
//    }
    
    for (int i=0;i<symtabCount;i++) {
//        NSLog(@"before: symtab[%d] section: %d address: %ld",i,symtab[i].section,symtab[i].address);
//        symtab[i].section=sectionNumberRemap[symtab[i].section];
        symtab[i].address += activeWriters[symtab[i].section].address;
//        NSLog(@"after: symtab[%d] section: %d address: %ld",i,symtab[i].section,symtab[i].address);
   }
}

-(void)writeSegmentLoadCommand
{
    long segmentOffset = [self segmentOffset];
    NSArray *writers = [self activeSectionWriters];
    long sectionOffset = 0;
    long segmentSize = 0;
    
    //--- compute section data offsets
    
    for ( MPWMachOSectionWriter *writer in writers) {
        writer.offset = sectionOffset + segmentOffset;
        writer.address = sectionOffset;
        segmentSize += writer.sectionDataSize;
        sectionOffset += writer.sectionDataSize;
    }
    
    long relocOffset = sectionOffset;
    for ( MPWMachOSectionWriter *writer in writers) {
        writer.relocationEntryOffset = relocOffset + segmentOffset;
        segmentSize += writer.relocEntrySize;
        relocOffset += writer.relocEntrySize;
    }
    self.totalSegmentSize = segmentSize;
    
    [self adjustSymtabEntries];
    
    struct segment_command_64 segment={};
    segment.cmd = LC_SEGMENT_64;
    segment.cmdsize = [self segmentCommandSize];
    segment.nsects = [self activeSectionWriters].count;
    segment.fileoff=segmentOffset;
    segment.filesize=segmentSize;
    segment.vmsize = segmentSize;
    segment.initprot = VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE;
    segment.maxprot = VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE;
    [self appendBytes:&segment length:sizeof segment];

    for ( MPWMachOSectionWriter *writer in writers) {
        [writer writeSectionLoadCommandOnWriter:self];
    }
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

-(void)addTextSectionData:(NSData*)data
{
    [self.textSectionWriter writeData:data];
}

-(void)writeSections
{
//    NSLog(@"sections to write: %@",self.activeSectionWriters);
    NSAssert2(self.length == [self segmentOffset], @"Actual symbol table offset %ld does not match computed %d", (long)self.length,[self symbolTableOffset]);
    for ( MPWMachOSectionWriter *sectionWriter in [self activeSectionWriters]) {
        NSLog(@"%@ write %ld bytes length now %ld",[sectionWriter sectname],[sectionWriter sectionDataSize],self.length);
        [sectionWriter writeSectionDataOn:self];
        NSLog(@"after writing %ld bytes length now %ld",[sectionWriter sectionDataSize],self.length);
    }
    for ( MPWMachOSectionWriter *sectionWriter in [self activeSectionWriters]) {
        NSLog(@"%@ write %ld bytes length now %ld",[sectionWriter sectname],[sectionWriter sectionDataSize],self.length);
        [sectionWriter writeRelocationEntriesOn:self];
        NSLog(@"after writing %ld bytes length now %ld",[sectionWriter sectionDataSize],self.length);
    }
//     [self writeData:self.textSection];
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

-(int)declareGlobalSymbol:(NSString*)symbol atOffset:(int)offset type:(int)theType section:(int)theSection
{
    int entryIndex = 0;
    NSNumber *offsetEntry = self.globalSymbolOffsets[symbol];
    if ( offsetEntry == nil ) {
        entryIndex = symtabCount;
//        NSLog(@"symtab[%d]=%@",symtabCount,symbol);
        self.globalSymbolOffsets[symbol]=@(symtabCount);
        symtab_entry entry={};
        entry.type = theType;
        entry.section = theSection;
        entry.string_offset=[self stringTableOffsetOfString:symbol];
//        NSLog(@"for symbol %@ offset is %d",symbol,offset);
        entry.address = offset;
        if ( symtabCount >= symtabCapacity ) {
            [self growSymtab];
        }
        symtab[symtabCount++]=entry;

    } else {
        entryIndex = [offsetEntry intValue];
    }
    return entryIndex;
}

-(int)declareGlobalSymbol:(NSString*)symbol atOffset:(int)offset
{
    return [self declareGlobalSymbol:symbol atOffset:offset type:0xf section:1];
}

-(int)declareExternalSymbol:(NSString*)symbol
{
    return [self declareGlobalSymbol:symbol atOffset:0 type:0x1 section:0];
}

-(void)writeSymbolTable
{
    NSAssert2(self.length == [self symbolTableOffset], @"Actual symbol table offset %ld does not match computed %d", (long)self.length,[self symbolTableOffset]);
    [self appendBytes:symtab length:symtabCount * sizeof(symtab_entry)];
}


-(NSData*)data
{
    NSData *data = (NSData*)self.target;
    if ( data.length == 0 ) {
        [self writeFile];
    }
    return data;
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
    [self writeSections];
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
#import "MPWMachOClassReader.h"
#import "MPWMachOSection.h"
#import "MPWMachOClassWriter.h"
#import "Mach_O_Structs.h"
#import "MPWMachORelocationPointer.h"

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
    [writer declareGlobalSymbol:@"_add" atOffset:10];
    NSData *machineCode = [self frameworkResource:@"add" category:@"aarch64"];
    [writer addTextSectionData: machineCode];
    //    INTEXPECT(writer.textSectionSize,8,@"bytes in text section");
    
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
    [writer declareGlobalSymbol:@"_add" atOffset:10];
    NSData *machineCode = [self frameworkResource:@"add" category:@"aarch64"];
    [writer addTextSectionData:machineCode];
    [writer writeFile];
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/add.o" atomically:YES];
    
}

+(void)testWriteFunctionWithRelocationEntries
{
    MPWMachOWriter *writer = [self stream];
    
    [writer.textSectionWriter addRelocationEntryForSymbol:@"_other" atOffset:12];
    NSData *machineCode = [self frameworkResource:@"add" category:@"aarch64"];
    [writer addTextSectionData:machineCode];
    [writer writeFile];
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/reloc.o" atomically:YES];
    
    MPWMachOReader *reader = [[[MPWMachOReader alloc] initWithData:macho] autorelease];
    INTEXPECT([[reader textSection] numRelocEntries],1,@"number of undefined symbol reloc entries");
    INTEXPECT([[reader textSection] relocEntryOffset],224,@"offset of undefined symbol reloc entries");
    IDEXPECT( [[reader textSection] nameOfRelocEntryAt:0],@"_other",@"name");
    INTEXPECT( [[reader textSection] offsetOfRelocEntryAt:0],12,@"address");
    INTEXPECT([[reader textSection] typeOfRelocEntryAt:0],ARM64_RELOC_BRANCH26,@"reloc entry type");
}

+(void)testWriteClassPartsAndReadPartsManually
{
    MPWMachOWriter *writer = [self stream];
    NSString *testclassNameSymbolName=@"_TestClass_name";
    [writer addTextSectionData:[self frameworkResource:@"add" category:@"aarch64"]];
    
    //  class name goes in its own section
    
    MPWMachOSectionWriter *classNameWriter = [writer addSectionWriterWithSegName:@"__TEXT" sectName:@"__objc_classname" flags:0];
    [classNameWriter declareGlobalSymbol:testclassNameSymbolName];
    [classNameWriter writeNullTerminatedString:@"TestClass"];
    
    // RO Part
    
    MPWMachOSectionWriter *classROWriter = [writer addSectionWriterWithSegName:@"__DATA" sectName:@"__objc_const" flags:0];
    NSString *roClassPartSymbol = @"__OBJC_CLASS_RO_TestClass";
    Mach_O_Class_RO roClassPart={};
    long name_ptr_offset = ((void*)&roClassPart.name) - ((void*)&roClassPart);
    
    [classROWriter addRelocationEntryForSymbol:testclassNameSymbolName atOffset:classROWriter.length + name_ptr_offset];
    roClassPart.instanceSize = 8;
    [classROWriter declareGlobalSymbol:roClassPartSymbol];
    [classROWriter appendBytes:&roClassPart length:sizeof roClassPart];
    
    // RW Part
    
    MPWMachOSectionWriter *classDataWriter = [writer addSectionWriterWithSegName:@"__DATA" sectName:@"__objc_data" flags:0];
    NSString *classPartSymbol = @"__OBJC_CLASS_$_TestClass";
    Mach_O_Class classInfo={};
    long ro_ptr_offset = ((void*)&classInfo.data) - ((void*)&classInfo);
    [classDataWriter declareGlobalSymbol:classPartSymbol];
    [classDataWriter addRelocationEntryForSymbol:roClassPartSymbol atOffset:classDataWriter.length + ro_ptr_offset];
    [classDataWriter appendBytes:&classInfo length:sizeof classInfo];
    
    // Pointers
    
    MPWMachOSectionWriter *classListWriter = [writer addSectionWriterWithSegName:@"__DATA" sectName:@"__objc_classlist" flags:0];
    char zerobytes[80];
    memset(zerobytes,0,80);
    [classListWriter addRelocationEntryForSymbol:classPartSymbol atOffset:0];
    [classListWriter appendBytes:zerobytes length:8];
    
    
    [writer writeFile];
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/class.o" atomically:YES];
    
    
    MPWMachOReader *machoReader = [[[MPWMachOReader alloc] initWithData:macho] autorelease];
    INTEXPECT( machoReader.numSections, 5,@"number of sections");
    //    for (int i=1;i<machoReader.numSections;i++) {
    //        MPWMachOSection *s=[machoReader sectionAtIndex:i];
    //        NSLog(@"section %@, segname='%@' sectname='%@'",s,s.segmentName,s.sectionName);
    //    }
    //    NSArray *classptrs = machoReader.classPointers;
    int classNameSymbolEntry = [machoReader indexOfSymbolNamed:testclassNameSymbolName];
    INTEXPECT(classNameSymbolEntry,0,@"symtab entry");
    
    //  read classname
    
    MPWMachOSection *classnameSection=[machoReader sectionAtIndex:[machoReader sectionForSymbolAt:classNameSymbolEntry]];
    EXPECTNOTNIL(classnameSection, @"have a class name section");
    IDEXPECT(classnameSection.sectionName,@"__objc_classname",@"");
    INTEXPECT( [classnameSection strings].count, 1, @"Objective-C classname");
    IDEXPECT( [classnameSection strings].firstObject, @"TestClass", @"Objective-C classname");
    
    // read RO part
    
    int roClassSmbolIndex=[machoReader indexOfSymbolNamed:roClassPartSymbol];
    INTEXPECT(roClassSmbolIndex, 1,@"symbol index");
    
    MPWMachOSection *roClassPartSection=[machoReader sectionAtIndex:[machoReader sectionForSymbolAt:roClassSmbolIndex]];
    const struct Mach_O_Class_RO *roClassPartCheck=[roClassPartSection bytes];
    EXPECTNOTNIL(roClassPartSection, @"objc const section");
    IDEXPECT(roClassPartSection.sectionName,@"__objc_const",@"");
    EXPECTNOTNIL(roClassPartCheck, @"objc const section data");
    INTEXPECT( roClassPartCheck->instanceSize, 8, @"instance size");
    
    //  read classname via RO part
    
    MPWMachORelocationPointer *classNamePtr = [[[MPWMachORelocationPointer alloc] initWithSection:roClassPartSection relocEntryIndex:0] autorelease];
    IDEXPECT( [classNamePtr targetName],@"_TestClass_name",@"");
    
    INTEXPECT( [[classNamePtr section] typeOfRelocEntryAt:0],0,@"");
    INTEXPECT( [classNamePtr targetOffset],0,@"target offset");
    NSString *className = [NSString stringWithUTF8String:[[classNamePtr targetPointer] bytes]];
    IDEXPECT( className,@"TestClass",@"");
    
    // read data part (and find RO part)
    
    int rwClassSmbolIndex=[machoReader indexOfSymbolNamed:classPartSymbol];
    INTEXPECT(rwClassSmbolIndex, 2,@"symbol index");
    MPWMachOSection *rwClassPartSection=[machoReader sectionAtIndex:[machoReader sectionForSymbolAt:rwClassSmbolIndex]];
    MPWMachORelocationPointer *roClassViaRWPointer = [[[MPWMachORelocationPointer alloc] initWithSection:rwClassPartSection relocEntryIndex:0] autorelease];
    IDEXPECT( [roClassViaRWPointer targetName],@"__OBJC_CLASS_RO_TestClass",@"RO part of class def via RW part");
    
    //  read the class pointers section
    
    NSArray <MPWMachORelocationPointer*>* classPtrs = [machoReader classPointers];
    INTEXPECT( classPtrs.count, 1, @"number of classes defined");
    MPWMachORelocationPointer *firstClassPtr=classPtrs.firstObject;
    IDEXPECT(firstClassPtr.targetName,@"__OBJC_CLASS_$_TestClass",@"");
    
    MPWMachOClassReader *reader=[[[MPWMachOClassReader alloc] initWithPointer:firstClassPtr] autorelease];
    IDEXPECT(reader.nameOfClass,@"TestClass",@"");
    INTEXPECT(reader.instanceSize,8,@"instance size");
    
}

+(void)testRelocationEntriesComeAfterAllSegmentData
{
    MPWMachOWriter *writer = [self stream];
    MPWMachOClassWriter *classwriter=[MPWMachOClassWriter writerWithWriter:writer];
    classwriter.nameOfClass = @"TestClass";
    classwriter.nameOfSuperClass = @"NSObject";
    [classwriter writeClass];
    MPWMachOReader *reader=[MPWMachOReader readerWithData:[writer data]];
    MPWMachOSection *firstSection = [reader sectionAtIndex:3];
    MPWMachOSection *lastSection = [reader sectionAtIndex:reader.numSections];
    int firstRelocationOffset = [firstSection relocEntryOffset];
//    INTEXPECT(firstRelocationOffset,712,@"");
    int lastDataOffset = lastSection.offset;
//    INTEXPECT(lastDataOffset,864,@"");
    EXPECTTRUE(firstRelocationOffset > lastDataOffset, @"all relocation entries should be after all data in segment");
}


+(NSArray*)testSelectors
{
   return @[
       @"testCanWriteHeader",
       @"testCanWriteStringsToStringTable",
       @"testCanWriteGlobalSymboltable",
//       @"testWriteLinkableAddFunction",
       @"testWriteFunctionWithRelocationEntries",
       @"testWriteClassPartsAndReadPartsManually",
       @"testRelocationEntriesComeAfterAllSegmentData"
		];
}

@end
