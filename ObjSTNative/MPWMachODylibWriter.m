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

    // Page-align the VM size
    self.textSegmentSize = (textSegmentFileSize + 0xFFF) & ~0xFFF;
    if (self.textSegmentSize == 0) {
        self.textSegmentSize = 0x1000;  // Minimum one page
    }

    struct segment_command_64 segment = {};
    segment.cmd = LC_SEGMENT_64;
    segment.cmdsize = [self textSegmentCommandSize];
    strncpy(segment.segname, "__TEXT", 16);
    segment.vmaddr = 0;
    segment.vmsize = self.textSegmentSize;
    segment.fileoff = 0;
    segment.filesize = textSegmentFileSize;
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
    // vmsize must be page-aligned and cover all linkedit data
    long linkeditVmSize = (self.linkeditSize + 0xFFF) & ~0xFFF;
    if (linkeditVmSize == 0) linkeditVmSize = 0x1000;
    segment.vmsize = linkeditVmSize;
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
    // Build a minimal exports trie
    // For now, compute size based on exported symbols
    int size = 0;
    for (NSString *symbol in self.globalSymbolOffsets.allKeys) {
        size += 1 + [symbol length] + 1 + 10;  // node info + symbol + terminator + uleb128 data
    }
    size += 16;  // Root node overhead
    size = MAX(size, 8);
    // Pad to 8-byte alignment for proper symbol table alignment
    size = (size + 7) & ~7;
    return size;
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

-(void)writeULEB128:(uint64_t)value
{
    do {
        uint8_t byte = value & 0x7F;
        value >>= 7;
        if (value != 0) {
            byte |= 0x80;
        }
        [self appendBytes:&byte length:1];
    } while (value != 0);
}

-(NSData*)buildExportsTrie
{
    // Build a minimal exports trie
    // Format: each node has terminal info (if exported) + edges to children

    NSMutableData *trie = [NSMutableData data];
    NSArray *symbols = [self.globalSymbolOffsets allKeys];

    if (symbols.count == 0) {
        // Empty trie: just a root node with no exports and no children
        uint8_t emptyNode[] = {0x00, 0x00};  // no terminal info, no children
        [trie appendBytes:emptyNode length:2];
        return trie;
    }

    // Simple trie: root node with edges to each symbol
    // This is not optimal but works for small numbers of symbols

    // First, compute total size needed
    NSMutableData *nodesData = [NSMutableData data];
    NSMutableArray *nodeOffsets = [NSMutableArray array];

    // Create terminal nodes for each symbol first
    for (NSString *symbol in symbols) {
        [nodeOffsets addObject:@(nodesData.length)];

        // Terminal node: flags + address (ULEB128 encoded)
        uint8_t flags = 0x00;  // EXPORT_SYMBOL_FLAGS_KIND_REGULAR
        [nodesData appendBytes:&flags length:1];

        // Get symbol address
        long address = 0x1000;  // Base address in __TEXT
        NSNumber *offsetNum = self.globalSymbolOffsets[symbol];
        if (offsetNum) {
            // The offset stored is relative to text section, we need vmaddr
            address += [offsetNum longValue];
        }

        // Write address as ULEB128
        uint64_t addr = address;
        do {
            uint8_t byte = addr & 0x7F;
            addr >>= 7;
            if (addr != 0) byte |= 0x80;
            [nodesData appendBytes:&byte length:1];
        } while (addr != 0);

        // Write terminal size (we'll fix this)
        // No children for terminal nodes
        uint8_t zero = 0x00;
        [nodesData appendBytes:&zero length:1];  // no children
    }

    // Now build root node
    NSMutableData *rootNode = [NSMutableData data];

    // Root has no terminal info
    uint8_t terminalSize = 0;
    [rootNode appendBytes:&terminalSize length:1];

    // Number of children = number of symbols
    uint8_t numChildren = (uint8_t)symbols.count;
    [rootNode appendBytes:&numChildren length:1];

    // Each child edge: label string + node offset
    long currentNodeOffset = rootNode.length + nodesData.length;
    for (int i = 0; i < symbols.count; i++) {
        NSString *symbol = symbols[i];
        const char *label = [[symbol substringFromIndex:1] UTF8String];  // Skip leading underscore for trie
        if ([symbol hasPrefix:@"_"]) {
            label = [symbol UTF8String] + 1;
        } else {
            label = [symbol UTF8String];
        }

        [rootNode appendBytes:label length:strlen(label) + 1];  // Include null terminator

        // Node offset (ULEB128)
        // Point to terminal node
        long offset = rootNode.length + [[nodeOffsets objectAtIndex:i] longValue];
        // This is getting complex - let's simplify
    }

    // Simplified approach: put everything inline
    // Root node has terminal info for first symbol if only one, otherwise edges

    // Actually, let's use an even simpler format that dyld accepts
    trie = [NSMutableData data];

    // For a single symbol, we can use a simpler structure
    if (symbols.count == 1) {
        NSString *symbol = symbols[0];
        const char *name = [symbol UTF8String];
        // Skip leading underscore
        if (name[0] == '_') name++;

        long address = 0x1000;
        NSNumber *offsetNum = self.globalSymbolOffsets[symbols[0]];
        if (offsetNum) {
            address += [offsetNum longValue];
        }

        // Root node: no terminal, one child
        uint8_t rootTerminalSize = 0;
        [trie appendBytes:&rootTerminalSize length:1];

        uint8_t numChildren = 1;
        [trie appendBytes:&numChildren length:1];

        // Edge: label + offset to child
        [trie appendBytes:name length:strlen(name) + 1];

        // Offset to child node (right after this)
        long childOffset = trie.length + 1;  // +1 for this ULEB
        uint8_t offsetByte = (uint8_t)childOffset;
        [trie appendBytes:&offsetByte length:1];

        // Child node: terminal with address, no children
        // Terminal size
        NSMutableData *terminalInfo = [NSMutableData data];
        uint8_t flags = 0x00;
        [terminalInfo appendBytes:&flags length:1];

        uint64_t addr = address;
        do {
            uint8_t byte = addr & 0x7F;
            addr >>= 7;
            if (addr != 0) byte |= 0x80;
            [terminalInfo appendBytes:&byte length:1];
        } while (addr != 0);

        uint8_t termSize = (uint8_t)terminalInfo.length;
        [trie appendBytes:&termSize length:1];
        [trie appendData:terminalInfo];

        // No children
        uint8_t noChildren = 0;
        [trie appendBytes:&noChildren length:1];
    } else {
        // Multiple symbols - simplified approach
        // Root with no terminal, edges to each symbol
        uint8_t rootTerminalSize = 0;
        [trie appendBytes:&rootTerminalSize length:1];

        uint8_t numChildren = (uint8_t)symbols.count;
        [trie appendBytes:&numChildren length:1];

        // We need to compute offsets first
        // For simplicity, compute where each terminal node will be
        NSMutableArray *edgeData = [NSMutableArray array];
        long currentOffset = 2;  // After root header

        // First pass: compute edge data sizes
        for (NSString *symbol in symbols) {
            const char *name = [symbol UTF8String];
            if (name[0] == '_') name++;
            currentOffset += strlen(name) + 1 + 1;  // name + null + offset byte
        }

        // Now write edges
        for (int i = 0; i < symbols.count; i++) {
            NSString *symbol = symbols[i];
            const char *name = [symbol UTF8String];
            if (name[0] == '_') name++;

            [trie appendBytes:name length:strlen(name) + 1];

            // Offset to this symbol's terminal node
            uint8_t nodeOffset = (uint8_t)currentOffset;
            [trie appendBytes:&nodeOffset length:1];

            currentOffset += 5;  // Approximate terminal node size
        }

        // Write terminal nodes
        for (NSString *symbol in symbols) {
            long address = 0x1000;
            NSNumber *offsetNum = self.globalSymbolOffsets[symbol];
            if (offsetNum) {
                address += [offsetNum longValue];
            }

            // Terminal info
            NSMutableData *terminalInfo = [NSMutableData data];
            uint8_t flags = 0x00;
            [terminalInfo appendBytes:&flags length:1];

            uint64_t addr = address;
            do {
                uint8_t byte = addr & 0x7F;
                addr >>= 7;
                if (addr != 0) byte |= 0x80;
                [terminalInfo appendBytes:&byte length:1];
            } while (addr != 0);

            uint8_t termSize = (uint8_t)terminalInfo.length;
            [trie appendBytes:&termSize length:1];
            [trie appendData:terminalInfo];

            // No children
            uint8_t noChildren = 0;
            [trie appendBytes:&noChildren length:1];
        }
    }

    return trie;
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

    // Page-align linkedit offset
    self.linkeditOffset = (headerAndLoadCommands + textDataSize + 0xFFF) & ~0xFFF;
    self.linkeditSize = [self exportTrieSize] + [self symbolTableSize] + [self.stringTableWriter length];

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
        @"testCanWriteDylibHeader",
        @"testDylibHasIdLoadCommand",
        @"testDylibHasMultipleSegments",
        @"testDylibHasExportsTrie",
        @"testDylibExportsSymbol",
        @"testMinimalDylibCanBeLoaded",
    ];
}

@end
