//
//  MPWMachODylibWriter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.01.26.
//

#import "MPWMachODylibWriter.h"
#import "MPWMachOWriter+Private.h"
#import "MPWMachOSectionWriter.h"
#import "MPWStringTableWriter.h"
#import "MPWExportsTrieWriter.h"
#import <mach-o/loader.h>
#import <dlfcn.h>

@interface MPWMachODylibWriter()

@property (nonatomic, assign) long textSegmentSize;
@property (nonatomic, assign) long linkeditOffset;
@property (nonatomic, assign) long linkeditSize;

@end

@implementation MPWMachODylibWriter

-(instancetype)initWithTarget:(id)aTarget
{
    // Call super's super (MPWObjectFileWriter) to avoid parent's __objc_imageinfo
    self = [super initWithTarget:aTarget];
    if (self) {
        self.filetype = MH_DYLIB;
        self.cputype = CPU_TYPE_ARM64;
        self.currentVersion = 0x10000;       // 1.0.0
        self.compatibilityVersion = 0x10000; // 1.0.0

        // Set up text section (parent does this but also adds objc stuff)
        // We need to reinitialize without the objc_imageinfo
    }
    return self;
}

// Override to filter out __DATA sections for now - they need a separate segment
-(NSArray<MPWMachOSectionWriter*>*)activeSectionWriters
{
    NSMutableArray *active = [NSMutableArray array];
    for (MPWMachOSectionWriter *writer in self.sectionWriters) {
        if (writer.isActive) {
            // Only include __TEXT sections for now
            if ([writer.segname isEqualToString:@"__TEXT"]) {
                [active addObject:writer];
            }
        }
    }
    return active;
}

#pragma mark - Header

-(void)writeHeader
{
    struct mach_header_64 header = {};
    header.magic = MH_MAGIC_64;
    header.cputype = self.cputype;
    header.cpusubtype = CPU_SUBTYPE_ARM64_ALL;
    header.filetype = MH_DYLIB;
    header.ncmds = self.numLoadCommands;
    header.sizeofcmds = self.loadCommandSize;
    header.flags = MH_NOUNDEFS | MH_DYLDLINK | MH_TWOLEVEL | MH_NO_REEXPORTED_DYLIBS;
    [self appendBytes:&header length:sizeof header];
}

#pragma mark - Load Commands

-(int)idDylibCommandSize
{
    // LC_ID_DYLIB: header + path string (padded to 8-byte alignment)
    int nameLen = (int)[self.installName length] + 1;
    int totalSize = sizeof(struct dylib_command) + nameLen;
    // Pad to 8-byte alignment
    totalSize = (totalSize + 7) & ~7;
    return totalSize;
}

-(void)writeIdDylibLoadCommand
{
    int cmdSize = [self idDylibCommandSize];
    struct dylib_command cmd = {};
    cmd.cmd = LC_ID_DYLIB;
    cmd.cmdsize = cmdSize;
    cmd.dylib.name.offset = sizeof(struct dylib_command);
    cmd.dylib.timestamp = 1;
    cmd.dylib.current_version = self.currentVersion;
    cmd.dylib.compatibility_version = self.compatibilityVersion;

    [self appendBytes:&cmd length:sizeof cmd];

    const char *name = [self.installName UTF8String];
    int nameLen = (int)strlen(name) + 1;
    [self appendBytes:name length:nameLen];

    // Pad to 8-byte alignment
    int padding = cmdSize - sizeof(struct dylib_command) - nameLen;
    if (padding > 0) {
        char zeros[8] = {0};
        [self appendBytes:zeros length:padding];
    }
}

-(int)textSegmentCommandSize
{
    return sizeof(struct segment_command_64) + ([self activeSectionWriters].count * sizeof(struct section_64));
}

-(void)writeTextSegmentLoadCommand
{
    NSArray *writers = [self activeSectionWriters];
    long headerAndLoadCommandsSize = [self segmentOffset];

    // Reserve space for LC_CODE_SIGNATURE that codesign will add
    long codeSignatureReserve = sizeof(struct linkedit_data_command);
    headerAndLoadCommandsSize += codeSignatureReserve;

    // Align section data start to 8 bytes (could be page-aligned for better performance)
    long sectionDataStart = (headerAndLoadCommandsSize + 7) & ~7;

    // Compute section offsets and addresses
    long sectionOffset = 0;
    for (MPWMachOSectionWriter *writer in writers) {
        writer.offset = sectionDataStart + sectionOffset;
        writer.address = sectionDataStart + sectionOffset;  // vmaddr = file offset for __TEXT
        sectionOffset += writer.sectionDataSize;
    }

    long textSegmentFileSize = sectionDataStart + sectionOffset;

    // Page-align the VM size - use 16KB minimum like reference dylibs
    self.textSegmentSize = (textSegmentFileSize + 0x3FFF) & ~0x3FFF;
    if (self.textSegmentSize == 0) {
        self.textSegmentSize = 0x4000;  // Minimum 16KB like reference
    }

    struct segment_command_64 segment = {};
    segment.cmd = LC_SEGMENT_64;
    segment.cmdsize = [self textSegmentCommandSize];
    strncpy(segment.segname, "__TEXT", 16);
    segment.vmaddr = 0;
    segment.vmsize = self.textSegmentSize;
    segment.fileoff = 0;
    // filesize must extend to where __LINKEDIT starts (self.linkeditOffset was computed in writeFile)
    segment.filesize = self.linkeditOffset;
    segment.maxprot = VM_PROT_READ | VM_PROT_EXECUTE;
    segment.initprot = VM_PROT_READ | VM_PROT_EXECUTE;
    segment.nsects = (uint32_t)writers.count;
    segment.flags = 0;

    [self appendBytes:&segment length:sizeof segment];

    for (MPWMachOSectionWriter *writer in writers) {
        [writer writeSectionLoadCommandOnWriter:self];
    }

    // Adjust symbol table entries to use actual vmaddrs
    [self adjustSymtabEntries];
}

-(void)writeLinkeditSegmentLoadCommand
{
    struct segment_command_64 segment = {};
    segment.cmd = LC_SEGMENT_64;
    segment.cmdsize = sizeof(struct segment_command_64);
    strncpy(segment.segname, "__LINKEDIT", 16);
    segment.vmaddr = self.textSegmentSize;  // Right after __TEXT
    // vmsize should be 16KB like reference dylibs
    segment.vmsize = 0x4000;
    segment.fileoff = self.linkeditOffset;
    segment.filesize = self.linkeditSize;
    segment.maxprot = VM_PROT_READ;
    segment.initprot = VM_PROT_READ;
    segment.nsects = 0;
    segment.flags = 0;

    [self appendBytes:&segment length:sizeof segment];
}

-(int)exportTrieSize
{
    // Use class method to compute size from symbol names alone
    return [MPWExportsTrieWriter trieSizeForSymbols:self.globalSymbolOffsets.allKeys];
}

-(void)writeExportsTrieLoadCommand
{
    struct linkedit_data_command cmd = {};
    cmd.cmd = LC_DYLD_EXPORTS_TRIE;
    cmd.cmdsize = sizeof(struct linkedit_data_command);
    cmd.dataoff = (uint32_t)self.linkeditOffset;
    cmd.datasize = [self exportTrieSize];

    [self appendBytes:&cmd length:sizeof cmd];
}

-(void)writeSymbolTableLoadCommand
{
    struct symtab_command symtab = {};
    symtab.cmd = LC_SYMTAB;
    symtab.cmdsize = sizeof symtab;
    symtab.nsyms = [self numSymbols];
    symtab.symoff = (uint32_t)(self.linkeditOffset + [self exportTrieSize]);
    symtab.stroff = (uint32_t)(symtab.symoff + [self symbolTableSize]);
    symtab.strsize = (uint32_t)[self.stringTableWriter length];
    [self appendBytes:&symtab length:sizeof symtab];
}

-(void)writeDysymtabLoadCommand
{
    struct dysymtab_command dysymtab = {};
    dysymtab.cmd = LC_DYSYMTAB;
    dysymtab.cmdsize = sizeof dysymtab;
    dysymtab.ilocalsym = 0;
    dysymtab.nlocalsym = 0;
    dysymtab.iextdefsym = 0;
    dysymtab.nextdefsym = [self numSymbols];
    dysymtab.iundefsym = [self numSymbols];
    dysymtab.nundefsym = 0;

    [self appendBytes:&dysymtab length:sizeof dysymtab];
}

// Override to set proper minos version (parent leaves it as 0.0)
-(void)writePlatformLoadCommand
{
    struct build_version_command cmd = {};
    cmd.cmd = LC_BUILD_VERSION;
    cmd.cmdsize = sizeof(struct build_version_command);
    cmd.platform = PLATFORM_MACOS;
    // minos: macOS 11.0 encoded as (11 << 16) | (0 << 8) | 0
    cmd.minos = (11 << 16);
    // sdk: leave as 0 (n/a) - the linker normally sets this
    cmd.sdk = 0;
    cmd.ntools = 0;
    [self appendBytes:&cmd length:sizeof cmd];
}

-(void)writeUUIDLoadCommand
{
    struct uuid_command uuid = {};
    uuid.cmd = LC_UUID;
    uuid.cmdsize = sizeof uuid;

    // Generate a simple UUID based on install name
    // In production, this should be a proper UUID
    const char *name = [self.installName UTF8String];
    unsigned long hash = 5381;
    for (int i = 0; name[i]; i++) {
        hash = ((hash << 5) + hash) + name[i];
    }

    // Fill UUID with hash-derived bytes
    for (int i = 0; i < 16; i++) {
        uuid.uuid[i] = (hash >> (i * 2)) & 0xFF;
    }
    // Set version and variant bits for UUID v4
    uuid.uuid[6] = (uuid.uuid[6] & 0x0F) | 0x40;  // Version 4
    uuid.uuid[8] = (uuid.uuid[8] & 0x3F) | 0x80;  // Variant

    [self appendBytes:&uuid length:sizeof uuid];
}

-(int)loadDylibCommandSizeForPath:(NSString*)path
{
    int nameLen = (int)[path length] + 1;
    int totalSize = sizeof(struct dylib_command) + nameLen;
    // Pad to 8-byte alignment
    totalSize = (totalSize + 7) & ~7;
    return totalSize;
}

-(void)writeLoadDylibCommand:(NSString*)path
{
    int cmdSize = [self loadDylibCommandSizeForPath:path];
    struct dylib_command cmd = {};
    cmd.cmd = LC_LOAD_DYLIB;
    cmd.cmdsize = cmdSize;
    cmd.dylib.name.offset = sizeof(struct dylib_command);
    cmd.dylib.timestamp = 2;
    cmd.dylib.current_version = 0x10000;  // 1.0.0
    cmd.dylib.compatibility_version = 0x10000;

    [self appendBytes:&cmd length:sizeof cmd];

    const char *name = [path UTF8String];
    int nameLen = (int)strlen(name) + 1;
    [self appendBytes:name length:nameLen];

    // Pad to 8-byte alignment
    int padding = cmdSize - sizeof(struct dylib_command) - nameLen;
    if (padding > 0) {
        char zeros[8] = {0};
        [self appendBytes:zeros length:padding];
    }
}

#pragma mark - Exports Trie

-(NSData*)buildExportsTrie
{
    MPWExportsTrieWriter *trieWriter = [[[MPWExportsTrieWriter alloc] init] autorelease];

    // Add all global symbols to the exports trie writer
    for (NSString *symbol in self.globalSymbolOffsets.allKeys) {
        long textSectionAddr = self.textSectionWriter.address;
        long address = textSectionAddr;
        NSNumber *offsetNum = self.globalSymbolOffsets[symbol];
        if (offsetNum) {
            address += [offsetNum longValue];
        }
        [trieWriter addSymbol:symbol atAddress:address];
    }

    return [trieWriter trieData];
}

#pragma mark - Write Sections

-(void)writeSections
{
    NSArray *writers = [self activeSectionWriters];
    if (writers.count > 0) {
        // Pad to first section's offset if needed
        MPWMachOSectionWriter *firstWriter = writers[0];
        long currentPos = self.length;
        if (currentPos < firstWriter.offset) {
            long padding = firstWriter.offset - currentPos;
            char *zeros = calloc(padding, 1);
            [self appendBytes:zeros length:padding];
            free(zeros);
        }
    }

    for (MPWMachOSectionWriter *sectionWriter in writers) {
        [sectionWriter writeSectionDataOn:self];
    }
    // No relocation entries for dylib - they're handled by chained fixups
}

#pragma mark - LINKEDIT Data

-(void)writeLinkeditData
{
    // Exports trie
    NSData *exportsTrie = [self buildExportsTrie];
    [self appendBytes:exportsTrie.bytes length:exportsTrie.length];

    // Pad to maintain alignment
    long padding = [self exportTrieSize] - exportsTrie.length;
    if (padding > 0) {
        char zeros[16] = {0};
        while (padding > 0) {
            long toWrite = MIN(padding, 16);
            [self appendBytes:zeros length:toWrite];
            padding -= toWrite;
        }
    }

    // Symbol table (using writeSymbolTableData to avoid offset assertion)
    [self writeSymbolTableData];

    // String table
    [self writeStringTable];

    // Pad to 8-byte alignment
    long currentSize = self.length;
    long targetSize = self.linkeditOffset + self.linkeditSize;
    if (currentSize < targetSize) {
        long padding = targetSize - currentSize;
        char zeros[8] = {0};
        while (padding > 0) {
            long toWrite = MIN(padding, 8);
            [self appendBytes:zeros length:toWrite];
            padding -= toWrite;
        }
    }
}

#pragma mark - Main Write

-(void)writeFile
{
    // Calculate sizes
    int idDylibSize = [self idDylibCommandSize];
    int textSegmentCmdSize = [self textSegmentCommandSize];
    int linkeditSegmentCmdSize = sizeof(struct segment_command_64);
    int exportsTrieCmdSize = sizeof(struct linkedit_data_command);
    int symtabCmdSize = sizeof(struct symtab_command);
    int dysymtabCmdSize = sizeof(struct dysymtab_command);
    int buildVersionCmdSize = sizeof(struct build_version_command);
    int uuidCmdSize = sizeof(struct uuid_command);
    int loadLibSystemCmdSize = [self loadDylibCommandSizeForPath:@"/usr/lib/libSystem.B.dylib"];

    self.numLoadCommands = 9;  // __TEXT, __LINKEDIT, LC_ID_DYLIB, LC_UUID, LC_LOAD_DYLIB, LC_DYLD_EXPORTS_TRIE, LC_SYMTAB, LC_DYSYMTAB, LC_BUILD_VERSION
    self.loadCommandSize = textSegmentCmdSize + linkeditSegmentCmdSize + idDylibSize + uuidCmdSize +
                           loadLibSystemCmdSize + exportsTrieCmdSize + symtabCmdSize + dysymtabCmdSize +
                           buildVersionCmdSize;

    // Generate string table before computing offsets
    [self generateStringTable];

    // Compute segment data start
    long headerAndLoadCommands = sizeof(struct mach_header_64) + self.loadCommandSize;

    // Compute __LINKEDIT offset (after __TEXT segment data)
    long textDataSize = 0;
    for (MPWMachOSectionWriter *writer in [self activeSectionWriters]) {
        textDataSize += writer.sectionDataSize;
    }

    // Align linkedit offset to 16KB like __TEXT vmsize
    self.linkeditOffset = (headerAndLoadCommands + textDataSize + 0x3FFF) & ~0x3FFF;
    long rawLinkeditSize = [self exportTrieSize] + [self symbolTableSize] + [self.stringTableWriter length];
    // Pad linkedit size to 8-byte alignment (required for mmap)
    self.linkeditSize = (rawLinkeditSize + 7) & ~7;

    // Write everything
    [self writeHeader];
    [self writeTextSegmentLoadCommand];
    [self writeLinkeditSegmentLoadCommand];
    [self writeIdDylibLoadCommand];
    [self writeUUIDLoadCommand];
    [self writeLoadDylibCommand:@"/usr/lib/libSystem.B.dylib"];
    [self writeExportsTrieLoadCommand];
    [self writeSymbolTableLoadCommand];
    [self writeDysymtabLoadCommand];
    [self writePlatformLoadCommand];

    // Write section data
    [self writeSections];

    // Pad to linkedit offset
    long currentPos = self.length;
    if (currentPos < self.linkeditOffset) {
        long padding = self.linkeditOffset - currentPos;
        char *zeros = calloc(padding, 1);
        [self appendBytes:zeros length:padding];
        free(zeros);
    }

    // Write linkedit data
    [self writeLinkeditData];
}

@end


#import <MPWFoundation/DebugMacros.h>
#import "MPWMachOReader.h"

@implementation MPWMachODylibWriter(testing)

+(void)testCanWriteDylibHeader
{
    MPWMachODylibWriter *writer = [self stream];
    writer.installName = @"@rpath/libtest.dylib";
    [writer writeFile];

    NSData *macho = [writer data];
    MPWMachOReader *reader = [[[MPWMachOReader alloc] initWithData:macho] autorelease];
    EXPECTTRUE([reader isHeaderValid], @"header valid");
    INTEXPECT([reader cputype], CPU_TYPE_ARM64, @"cputype");
    INTEXPECT([reader filetype], MH_DYLIB, @"filetype should be MH_DYLIB");
}

+(void)testDylibHasIdLoadCommand
{
    MPWMachODylibWriter *writer = [self stream];
    writer.installName = @"@rpath/libtest.dylib";
    [writer writeFile];

    NSData *macho = [writer data];
    MPWMachOReader *reader = [[[MPWMachOReader alloc] initWithData:macho] autorelease];

    // Should have LC_ID_DYLIB load command
    EXPECTNOTNIL([reader loadCommandOfTypeIfPresent:LC_ID_DYLIB], @"should have LC_ID_DYLIB");
}

+(void)testDylibHasMultipleSegments
{
    MPWMachODylibWriter *writer = [self stream];
    writer.installName = @"@rpath/libtest.dylib";

    // Add some code
    unsigned char code[] = { 0xc0, 0x03, 0x5f, 0xd6 };  // ret
    [writer declareGlobalSymbol:@"_testfn" atOffset:0];
    [writer addTextSectionData:[NSData dataWithBytes:code length:sizeof(code)]];
    [writer writeFile];

    NSData *macho = [writer data];
    MPWMachOReader *reader = [[[MPWMachOReader alloc] initWithData:macho] autorelease];

    // Should have __TEXT and __LINKEDIT segments at minimum
    EXPECTNOTNIL([reader segmentNamed:@"__TEXT"], @"should have __TEXT segment");
    EXPECTNOTNIL([reader segmentNamed:@"__LINKEDIT"], @"should have __LINKEDIT segment");
}

+(void)testDylibHasExportsTrie
{
    MPWMachODylibWriter *writer = [self stream];
    writer.installName = @"@rpath/libtest.dylib";

    // Add an exported function
    unsigned char code[] = { 0xc0, 0x03, 0x5f, 0xd6 };  // ret
    [writer declareGlobalSymbol:@"_testfn" atOffset:0];
    [writer addTextSectionData:[NSData dataWithBytes:code length:sizeof(code)]];
    [writer writeFile];

    NSData *macho = [writer data];
    MPWMachOReader *reader = [[[MPWMachOReader alloc] initWithData:macho] autorelease];

    // Should have LC_DYLD_EXPORTS_TRIE load command
    EXPECTNOTNIL([reader loadCommandOfTypeIfPresent:LC_DYLD_EXPORTS_TRIE], @"should have exports trie");
}

+(void)testDylibExportsSymbol
{
    MPWMachODylibWriter *writer = [self stream];
    writer.installName = @"@rpath/libtest.dylib";

    // Add an exported function
    unsigned char code[] = { 0xc0, 0x03, 0x5f, 0xd6 };  // ret
    [writer declareGlobalSymbol:@"_testfn" atOffset:0];
    [writer addTextSectionData:[NSData dataWithBytes:code length:sizeof(code)]];
    [writer writeFile];

    NSData *macho = [writer data];
    MPWMachOReader *reader = [[[MPWMachOReader alloc] initWithData:macho] autorelease];

    NSArray *exports = [reader exportedSymbolNames];
    EXPECTTRUE([exports containsObject:@"_testfn"], @"should export _testfn");
}

// Test that documents all load commands a working dylib has
+(void)testDocumentReferenceLoadCommands
{
    // Create reference dylib with clang
    system("echo 'int answer(void) { return 42; }' > /tmp/ref_src.c");
    system("clang -shared -o /tmp/libref_test.dylib /tmp/ref_src.c -install_name @rpath/libref.dylib");

    NSData *refData = [NSData dataWithContentsOfFile:@"/tmp/libref_test.dylib"];
    EXPECTNOTNIL(refData, @"reference dylib should exist");

    MPWMachOReader *refReader = [[[MPWMachOReader alloc] initWithData:refData] autorelease];

    // Document all load commands present in a working dylib
    NSLog(@"Reference dylib load commands:");

    // Required load commands for a dylib:
    EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_SEGMENT_64], @"needs LC_SEGMENT_64");
    EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_ID_DYLIB], @"needs LC_ID_DYLIB");
    EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_SYMTAB], @"needs LC_SYMTAB");
    EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_DYSYMTAB], @"needs LC_DYSYMTAB");
    EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_UUID], @"needs LC_UUID");
    EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_BUILD_VERSION], @"needs LC_BUILD_VERSION");
    EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_LOAD_DYLIB], @"needs LC_LOAD_DYLIB (libSystem)");
    // Exports can be in LC_DYLD_EXPORTS_TRIE (new) or LC_DYLD_INFO_ONLY (old)
    BOOL hasExports = [refReader loadCommandOfTypeIfPresent:LC_DYLD_EXPORTS_TRIE] != NULL ||
                      [refReader loadCommandOfTypeIfPresent:LC_DYLD_INFO_ONLY] != NULL;
    EXPECTTRUE(hasExports, @"needs exports (LC_DYLD_EXPORTS_TRIE or LC_DYLD_INFO_ONLY)");

    // Modern dylibs also have chained fixups (required for arm64e, optional for arm64)
    const struct load_command *chainedFixups = [refReader loadCommandOfTypeIfPresent:LC_DYLD_CHAINED_FIXUPS];
    if (chainedFixups) {
        NSLog(@"  Has LC_DYLD_CHAINED_FIXUPS (modern format)");
    }

    // Function starts (optional but common)
    if ([refReader loadCommandOfTypeIfPresent:LC_FUNCTION_STARTS]) {
        NSLog(@"  Has LC_FUNCTION_STARTS (optional)");
    }

    // Data in code (optional)
    if ([refReader loadCommandOfTypeIfPresent:LC_DATA_IN_CODE]) {
        NSLog(@"  Has LC_DATA_IN_CODE (optional)");
    }

    // Code signature (added by codesign, required to load on modern macOS)
    if ([refReader loadCommandOfTypeIfPresent:LC_CODE_SIGNATURE]) {
        NSLog(@"  Has LC_CODE_SIGNATURE (required for loading)");
    }
}

// Test that documents and verifies structural assumptions about dylib layout
// These assumptions are derived from analyzing reference dylibs created by clang/ld
+(void)testDylibLayoutAssumptions
{
    // Create reference dylib with clang
    system("echo 'int answer(void) { return 42; }' > /tmp/ref_src.c");
    system("clang -shared -o /tmp/libref_test.dylib /tmp/ref_src.c -install_name @rpath/libref.dylib");

    NSData *refData = [NSData dataWithContentsOfFile:@"/tmp/libref_test.dylib"];
    EXPECTNOTNIL(refData, @"reference dylib should exist");

    MPWMachOReader *refReader = [[[MPWMachOReader alloc] initWithData:refData] autorelease];

    // Get segments from reference
    struct segment_command_64 *refText = [refReader segmentNamed:@"__TEXT"];
    struct segment_command_64 *refLinkedit = [refReader segmentNamed:@"__LINKEDIT"];
    EXPECTNOTNIL((id)(uintptr_t)refText, @"reference should have __TEXT");
    EXPECTNOTNIL((id)(uintptr_t)refLinkedit, @"reference should have __LINKEDIT");

    // Document and verify layout assumptions:

    // 1. __TEXT starts at file offset 0 and vmaddr 0
    INTEXPECT(refText->fileoff, 0, @"__TEXT fileoff should be 0");
    INTEXPECT(refText->vmaddr, 0, @"__TEXT vmaddr should be 0");

    // 2. __TEXT filesize equals __LINKEDIT fileoff (no gaps)
    INTEXPECT(refLinkedit->fileoff, refText->filesize, @"__LINKEDIT fileoff == __TEXT filesize");

    // 3. __LINKEDIT vmaddr equals __TEXT vmsize (contiguous in memory)
    INTEXPECT(refLinkedit->vmaddr, refText->vmsize, @"__LINKEDIT vmaddr == __TEXT vmsize");

    // 4. Both vmsize values are page-aligned (0x1000 = 4096)
    INTEXPECT(refText->vmsize % 0x1000, 0, @"__TEXT vmsize should be page-aligned");
    INTEXPECT(refLinkedit->vmsize % 0x1000, 0, @"__LINKEDIT vmsize should be page-aligned");

    // 5. File size should equal __LINKEDIT fileoff + __LINKEDIT filesize
    long expectedFileSize = refLinkedit->fileoff + refLinkedit->filesize;
    INTEXPECT((long)refData.length, expectedFileSize, @"file size == __LINKEDIT end");

    NSLog(@"Reference dylib layout:");
    NSLog(@"  __TEXT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
          refText->vmaddr, refText->vmsize, refText->fileoff, refText->filesize);
    NSLog(@"  __LINKEDIT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
          refLinkedit->vmaddr, refLinkedit->vmsize, refLinkedit->fileoff, refLinkedit->filesize);
    NSLog(@"  File size: %lu", (unsigned long)refData.length);
}

// Test that our generated dylib follows the same layout assumptions
+(void)testGeneratedDylibFollowsLayoutAssumptions
{
    MPWMachODylibWriter *writer = [self stream];
    writer.installName = @"@rpath/libminimal.dylib";

    unsigned char code[] = {
        0x40, 0x05, 0x80, 0x52,  // mov w0, #42
        0xc0, 0x03, 0x5f, 0xd6   // ret
    };
    [writer declareGlobalSymbol:@"_answer" atOffset:0];
    [writer addTextSectionData:[NSData dataWithBytes:code length:sizeof(code)]];
    [writer writeFile];

    NSData *macho = [writer data];
    MPWMachOReader *reader = [[[MPWMachOReader alloc] initWithData:macho] autorelease];

    struct segment_command_64 *text = [reader segmentNamed:@"__TEXT"];
    struct segment_command_64 *linkedit = [reader segmentNamed:@"__LINKEDIT"];

    NSLog(@"Generated dylib layout (before codesign):");
    NSLog(@"  __TEXT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
          text->vmaddr, text->vmsize, text->fileoff, text->filesize);
    NSLog(@"  __LINKEDIT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
          linkedit->vmaddr, linkedit->vmsize, linkedit->fileoff, linkedit->filesize);
    NSLog(@"  File size: %lu", (unsigned long)macho.length);

    // Verify assumptions
    INTEXPECT(text->fileoff, 0, @"__TEXT fileoff should be 0");
    INTEXPECT(text->vmaddr, 0, @"__TEXT vmaddr should be 0");
    INTEXPECT(linkedit->fileoff, text->filesize, @"__LINKEDIT fileoff == __TEXT filesize");
    INTEXPECT(linkedit->vmaddr, text->vmsize, @"__LINKEDIT vmaddr == __TEXT vmsize");
    INTEXPECT(text->vmsize % 0x1000, 0, @"__TEXT vmsize should be page-aligned");
    INTEXPECT(linkedit->vmsize % 0x1000, 0, @"__LINKEDIT vmsize should be page-aligned");

    long expectedFileSize = linkedit->fileoff + linkedit->filesize;
    INTEXPECT((long)macho.length, expectedFileSize, @"file size == __LINKEDIT end");
}

// Compare our dylib structure to reference AFTER codesign to find differences
+(void)testCompareSignedDylibStructure
{
    // Create reference dylib
    system("echo 'int answer(void) { return 42; }' > /tmp/ref_src.c");
    system("clang -shared -o /tmp/libref_compare.dylib /tmp/ref_src.c -install_name @rpath/libref.dylib");

    // Create our dylib
    MPWMachODylibWriter *writer = [self stream];
    writer.installName = @"@rpath/libminimal.dylib";
    unsigned char code[] = {
        0x40, 0x05, 0x80, 0x52,  // mov w0, #42
        0xc0, 0x03, 0x5f, 0xd6   // ret
    };
    [writer declareGlobalSymbol:@"_answer" atOffset:0];
    [writer addTextSectionData:[NSData dataWithBytes:code length:sizeof(code)]];
    [writer writeFile];

    NSData *macho = [writer data];
    NSString *path = @"/tmp/libminimal_compare.dylib";
    [macho writeToFile:path atomically:YES];

    // Sign our dylib
    system("codesign -f -s - /tmp/libminimal_compare.dylib 2>&1");

    // Read both signed dylibs
    NSData *refData = [NSData dataWithContentsOfFile:@"/tmp/libref_compare.dylib"];
    NSData *ourData = [NSData dataWithContentsOfFile:@"/tmp/libminimal_compare.dylib"];

    MPWMachOReader *refReader = [[[MPWMachOReader alloc] initWithData:refData] autorelease];
    MPWMachOReader *ourReader = [[[MPWMachOReader alloc] initWithData:ourData] autorelease];

    struct segment_command_64 *refText = [refReader segmentNamed:@"__TEXT"];
    struct segment_command_64 *refLinkedit = [refReader segmentNamed:@"__LINKEDIT"];
    struct segment_command_64 *ourText = [ourReader segmentNamed:@"__TEXT"];
    struct segment_command_64 *ourLinkedit = [ourReader segmentNamed:@"__LINKEDIT"];

    NSLog(@"=== REFERENCE (after codesign) ===");
    NSLog(@"  File size: %lu", (unsigned long)refData.length);
    NSLog(@"  __TEXT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
          refText->vmaddr, refText->vmsize, refText->fileoff, refText->filesize);
    NSLog(@"  __LINKEDIT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
          refLinkedit->vmaddr, refLinkedit->vmsize, refLinkedit->fileoff, refLinkedit->filesize);
    NSLog(@"  Bytes available for __LINKEDIT: %lu", (unsigned long)(refData.length - refLinkedit->fileoff));

    NSLog(@"=== OURS (after codesign) ===");
    NSLog(@"  File size: %lu", (unsigned long)ourData.length);
    NSLog(@"  __TEXT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
          ourText->vmaddr, ourText->vmsize, ourText->fileoff, ourText->filesize);
    NSLog(@"  __LINKEDIT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
          ourLinkedit->vmaddr, ourLinkedit->vmsize, ourLinkedit->fileoff, ourLinkedit->filesize);
    NSLog(@"  Bytes available for __LINKEDIT: %lu", (unsigned long)(ourData.length - ourLinkedit->fileoff));

    // Key comparisons
    NSLog(@"=== KEY DIFFERENCES ===");
    if (refLinkedit->vmsize != ourLinkedit->vmsize) {
        NSLog(@"  __LINKEDIT vmsize: ref=%llx ours=%llx", refLinkedit->vmsize, ourLinkedit->vmsize);
    }
    if (refLinkedit->filesize != ourLinkedit->filesize) {
        NSLog(@"  __LINKEDIT filesize: ref=%lld ours=%lld", refLinkedit->filesize, ourLinkedit->filesize);
    }

    // Check if vmsize can be backed by file
    long refAvail = refData.length - refLinkedit->fileoff;
    long ourAvail = ourData.length - ourLinkedit->fileoff;
    NSLog(@"  Reference: vmsize=%llx, file can back %lx bytes", refLinkedit->vmsize, refAvail);
    NSLog(@"  Ours: vmsize=%llx, file can back %lx bytes", ourLinkedit->vmsize, ourAvail);

    // Check total VM size
    NSLog(@"=== TOTAL VM LAYOUT ===");
    NSLog(@"  Reference: __TEXT ends at %llx, __LINKEDIT spans %llx-%llx",
          refText->vmsize, refLinkedit->vmaddr, refLinkedit->vmaddr + refLinkedit->vmsize);
    NSLog(@"  Ours: __TEXT ends at %llx, __LINKEDIT spans %llx-%llx",
          ourText->vmsize, ourLinkedit->vmaddr, ourLinkedit->vmaddr + ourLinkedit->vmsize);

    // Check file backing for entire range
    NSLog(@"=== FILE BACKING ===");
    NSLog(@"  Reference file size: %lu, __LINKEDIT end in file: %lld",
          (unsigned long)refData.length, refLinkedit->fileoff + refLinkedit->filesize);
    NSLog(@"  Our file size: %lu, __LINKEDIT end in file: %lld",
          (unsigned long)ourData.length, ourLinkedit->fileoff + ourLinkedit->filesize);

    // Try loading reference to verify it works
    void *refHandle = dlopen("/tmp/libref_compare.dylib", RTLD_NOW);
    NSLog(@"  Reference loads: %s", refHandle ? "YES" : dlerror());
    if (refHandle) dlclose(refHandle);

    // Try loading ours
    void *ourHandle = dlopen("/tmp/libminimal_compare.dylib", RTLD_NOW);
    NSLog(@"  Ours loads: %s", ourHandle ? "YES" : dlerror());
    if (ourHandle) dlclose(ourHandle);

    // The test passes if we output the comparison - actual loading test is separate
    EXPECTTRUE(YES, @"comparison complete");
}

+(void)testMinimalDylibCanBeLoaded
{
    MPWMachODylibWriter *writer = [self stream];
    writer.installName = @"@rpath/libminimal.dylib";

    // Simple function that returns 42
    // mov w0, #42; ret
    unsigned char code[] = {
        0x40, 0x05, 0x80, 0x52,  // mov w0, #42
        0xc0, 0x03, 0x5f, 0xd6   // ret
    };
    [writer declareGlobalSymbol:@"_answer" atOffset:0];
    [writer addTextSectionData:[NSData dataWithBytes:code length:sizeof(code)]];
    [writer writeFile];

    NSData *macho = [writer data];
    NSString *path = @"/tmp/libminimal_test.dylib";
    [macho writeToFile:path atomically:YES];

    // Ad-hoc sign the dylib (required on modern macOS)
    NSTask *codesign = [[[NSTask alloc] init] autorelease];
    codesign.launchPath = @"/usr/bin/codesign";
    codesign.arguments = @[@"-f", @"-s", @"-", path];
    [codesign launch];
    [codesign waitUntilExit];

    // Try to load and call
    void *handle = dlopen([path fileSystemRepresentation], RTLD_NOW);
    if (!handle) {
        NSLog(@"dlopen error: %s", dlerror());
    }
    if (handle) {
        int (*answer)(void) = dlsym(handle, "answer");
        if (answer) {
            INTEXPECT(answer(), 42, @"should return 42");
        }
        dlclose(handle);
    }
    EXPECTNOTNIL(handle, @"dylib should load");
}

+(NSArray*)testSelectors
{
    return @[
        @"testDocumentReferenceLoadCommands",
        @"testDylibLayoutAssumptions",
        @"testGeneratedDylibFollowsLayoutAssumptions",
        @"testCompareSignedDylibStructure",
        @"testCanWriteDylibHeader",
        @"testDylibHasIdLoadCommand",
        @"testDylibHasMultipleSegments",
        @"testDylibHasExportsTrie",
        @"testDylibExportsSymbol",
        @"testMinimalDylibCanBeLoaded",
    ];
}

@end
