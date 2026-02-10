//
//  STMachOObjectFileLoader.m
//  ObjSTNative
//
//  Loads Mach-O object files (.o) directly into executable memory
//  without dlopen, avoiding code signing requirements.
//

#import "STMachOObjectFileLoader.h"
#import "STMachOReader.h"
#import "STMachOSection.h"
#import "STJittableData.h"
#import <mach-o/loader.h>
#import <mach-o/reloc.h>
#import <mach-o/arm64/reloc.h>
#import <dlfcn.h>

@interface STMachOObjectFileLoader()

@property (nonatomic, strong) STMachOReader *reader;
@property (nonatomic, strong) STJittableData *executableMemory;
@property (nonatomic, strong) NSMutableArray<NSString*> *loadErrors;
// Maps section index (1-based, as in Mach-O) -> offset within executableMemory
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSNumber*> *sectionOffsets;
// Maps section index -> size
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSNumber*> *sectionSizes;

@end

@implementation STMachOObjectFileLoader

-(instancetype)initWithData:(NSData*)objectFileData
{
    self = [super init];
    if (self) {
        _reader = [[STMachOReader alloc] initWithData:objectFileData];
        _loadErrors = [[NSMutableArray alloc] init];
        _sectionOffsets = [[NSMutableDictionary alloc] init];
        _sectionSizes = [[NSMutableDictionary alloc] init];

        if (![_reader isHeaderValid]) {
            [_loadErrors addObject:@"Invalid Mach-O header"];
            return self;
        }
        if ([_reader filetype] != MH_OBJECT) {
            [_loadErrors addObject:[NSString stringWithFormat:@"Not an object file (filetype=%d)", [_reader filetype]]];
            return self;
        }

        [self loadSections];
        [self resolveRelocations];
        [_executableMemory makeExecutable];
    }
    return self;
}

-(void)loadSections
{
    // Calculate total size needed across all sections
    int numSections = [_reader numSections];
    long totalSize = 0;
    for (int i = 1; i <= numSections; i++) {
        STMachOSection *section = [_reader sectionAtIndex:i];
        long size = [section size];
        // Align each section to 8 bytes
        totalSize = (totalSize + 7) & ~7;
        _sectionOffsets[@(i)] = @(totalSize);
        _sectionSizes[@(i)] = @(size);
        totalSize += size;
    }

    // Allocate executable memory and copy all sections
    _executableMemory = [[STJittableData alloc] initWithCapacity:MAX(totalSize, 4096)];
    for (int i = 1; i <= numSections; i++) {
        STMachOSection *section = [_reader sectionAtIndex:i];
        long offset = [_sectionOffsets[@(i)] longValue];
        long size = [section size];
        if (size > 0) {
            NSData *sectionData = [section sectionData];
            memcpy((char*)[_executableMemory mutableBytes] + offset,
                   [sectionData bytes], size);
        }
    }
}

/// Resolve address of a symbol. For defined symbols, returns the address
/// in our loaded memory. For undefined (external) symbols, uses dlsym.
-(long)resolveSymbol:(NSString*)symbolName
{
    int symbolIndex = [_reader indexOfSymbolNamed:symbolName];
    if (symbolIndex < 0) {
        // Try dlsym — strip leading underscore for C symbols
        const char *cname = [symbolName UTF8String];
        if (cname[0] == '_') {
            cname++;
        }
        void *addr = dlsym(RTLD_DEFAULT, cname);
        if (addr) {
            return (long)addr;
        }
        [_loadErrors addObject:[NSString stringWithFormat:@"Unresolved symbol: %@", symbolName]];
        return 0;
    }

    if ([_reader isSymbolUndefined:symbolIndex]) {
        // External symbol — resolve via dlsym
        const char *cname = [symbolName UTF8String];
        if (cname[0] == '_') {
            cname++;
        }
        void *addr = dlsym(RTLD_DEFAULT, cname);
        if (addr) {
            return (long)addr;
        }
        [_loadErrors addObject:[NSString stringWithFormat:@"Unresolved external symbol: %@", symbolName]];
        return 0;
    }

    // Defined symbol — find its section and offset within our loaded memory
    int sectionNum = [_reader sectionForSymbolAt:symbolIndex];
    long symbolOffset = [_reader symbolOffsetAt:symbolIndex];

    if (sectionNum == 0) {
        // Absolute symbol
        return symbolOffset;
    }

    // In object files, symbolOffset is typically the address field which
    // equals the offset from the start of its section (since section addresses
    // in .o files start at 0 for the segment).
    STMachOSection *section = [_reader sectionAtIndex:sectionNum];
    long offsetInSection = symbolOffset - [section address];
    long sectionBase = [_sectionOffsets[@(sectionNum)] longValue];

    return (long)[_executableMemory bytes] + sectionBase + offsetInSection;
}

-(void)resolveRelocations
{
    int numSections = [_reader numSections];
    for (int secIdx = 1; secIdx <= numSections; secIdx++) {
        STMachOSection *section = [_reader sectionAtIndex:secIdx];
        int numRelocs = [section numRelocEntries];
        if (numRelocs == 0) continue;

        long sectionBase = [_sectionOffsets[@(secIdx)] longValue];
        void *sectionBytes = (char*)[_executableMemory mutableBytes] + sectionBase;

        for (int i = 0; i < numRelocs; i++) {
            int relocType = [section typeOfRelocEntryAt:i];
            long offset = [section offsetOfRelocEntryAt:i];
            long targetAddr;
            NSString *symbolName = nil;

            if ([section isExternalRelocEntryAt:i]) {
                // r_extern=1: r_symbolnum is a symbol table index
                symbolName = [section nameOfRelocEntryAt:i];
                targetAddr = [self resolveSymbol:symbolName];
            } else {
                // r_extern=0: r_symbolnum is a section number (1-based)
                // Target address is start of that section in our loaded memory
                int targetSectionNum = [section symbolNumberOfRelocEntryAt:i];
                symbolName = [NSString stringWithFormat:@"<section %d>", targetSectionNum];
                NSNumber *targetOffset = _sectionOffsets[@(targetSectionNum)];
                if (targetOffset) {
                    targetAddr = (long)[_executableMemory bytes] + [targetOffset longValue];
                } else {
                    targetAddr = 0;
                }
            }

            if (targetAddr == 0) {
                continue; // already logged in resolveSymbol:
            }

            long pcAddr = (long)[_executableMemory bytes] + sectionBase + offset;

            if (relocType == ARM64_RELOC_BRANCH26) {
                // BL/B instruction: 26-bit PC-relative displacement
                uint32_t instr;
                memcpy(&instr, (char*)sectionBytes + offset, 4);
                long delta = targetAddr - pcAddr;
                instr &= 0xFC000000; // preserve opcode
                instr |= (uint32_t)((delta >> 2) & 0x03FFFFFF);
                memcpy((char*)sectionBytes + offset, &instr, 4);

            } else if (relocType == ARM64_RELOC_PAGE21) {
                // ADRP instruction: page-relative offset
                uint32_t instr;
                memcpy(&instr, (char*)sectionBytes + offset, 4);
                long pcPage = pcAddr & ~0xFFF;
                long targetPage = targetAddr & ~0xFFF;
                long pageDiff = (targetPage - pcPage) >> 12;
                instr &= 0x9F00001F; // preserve opcode and Rd
                instr |= (uint32_t)((pageDiff & 0x3) << 29);          // immlo
                instr |= (uint32_t)(((pageDiff >> 2) & 0x7FFFF) << 5); // immhi
                memcpy((char*)sectionBytes + offset, &instr, 4);

            } else if (relocType == ARM64_RELOC_PAGEOFF12) {
                // ADD/LDR immediate: page offset (low 12 bits)
                uint32_t instr;
                memcpy(&instr, (char*)sectionBytes + offset, 4);
                long pageOff = targetAddr & 0xFFF;
                instr &= 0xFFC003FF; // preserve everything except imm12
                instr |= (uint32_t)((pageOff & 0xFFF) << 10);
                memcpy((char*)sectionBytes + offset, &instr, 4);

            } else if (relocType == ARM64_RELOC_UNSIGNED) {
                // 64-bit absolute pointer
                uint64_t addr = (uint64_t)targetAddr;
                memcpy((char*)sectionBytes + offset, &addr, 8);

            } else if (relocType == ARM64_RELOC_GOT_LOAD_PAGE21) {
                // GOT page21 — for our in-memory loading, treat like PAGE21
                // since we resolve the symbol directly (no GOT indirection needed).
                // NOTE: This only works if we also rewrite the corresponding
                // GOT_LOAD_PAGEOFF12 LDR to an ADD (to avoid double-indirection).
                // For now, log unsupported until we have test cases that need it.
                [_loadErrors addObject:[NSString stringWithFormat:
                    @"GOT_LOAD_PAGE21 relocation not yet fully supported for symbol %@", symbolName]];

            } else if (relocType == ARM64_RELOC_GOT_LOAD_PAGEOFF12) {
                // GOT pageoff12 — would need LDR→ADD rewriting to avoid
                // double-indirection. Not yet supported.
                [_loadErrors addObject:[NSString stringWithFormat:
                    @"GOT_LOAD_PAGEOFF12 relocation not yet fully supported for symbol %@", symbolName]];

            } else {
                [_loadErrors addObject:[NSString stringWithFormat:
                    @"Unsupported relocation type %d for symbol %@ at offset 0x%lx",
                    relocType, symbolName, offset]];
            }
        }
    }
}

-(void* _Nullable)functionPointerForSymbol:(NSString*)symbolName
{
    long addr = [self resolveSymbol:symbolName];
    return addr ? (void*)addr : NULL;
}

-(NSArray<NSString*>*)errors
{
    return [_loadErrors copy];
}

-(void)dealloc
{
    [_reader release];
    [_executableMemory release];
    [_loadErrors release];
    [_sectionOffsets release];
    [_sectionSizes release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STMachOObjectFileLoader(testing)

+(instancetype)loaderForTestFile:(NSString*)name
{
    NSData *data = [self frameworkResource:name category:@"macho"];
    return [[[self alloc] initWithData:data] autorelease];
}

+(void)testCanLoadSimpleObjectFile
{
    // The "add" test file contains a simple _add function
    STMachOObjectFileLoader *loader = [self loaderForTestFile:@"add"];
    EXPECTNOTNIL(loader, @"loader should exist");
    EXPECTNOTNIL(loader.executableMemory, @"should have executable memory");
    INTEXPECT(loader.errors.count, 0, @"should have no errors");
}

+(void)testCanCallLoadedFunction
{
    // _add(int a, int b) -> int  — returns a+b
    STMachOObjectFileLoader *loader = [self loaderForTestFile:@"add"];
    int (*addFn)(int, int) = [loader functionPointerForSymbol:@"_add"];
    EXPECTNOTNIL(addFn, @"should find _add symbol");
    if (addFn) {
        INTEXPECT(addFn(3, 4), 7, @"3 + 4 should be 7");
        INTEXPECT(addFn(10, 20), 30, @"10 + 20 should be 30");
        INTEXPECT(addFn(-5, 5), 0, @"-5 + 5 should be 0");
    }
}

+(void)testCanCallFunctionWithExternalReference
{
    // "call-external-fn" contains _fn that calls external _other
    // Since _other doesn't exist in this process, we expect a resolution error
    STMachOObjectFileLoader *loader = [self loaderForTestFile:@"call-external-fn"];
    EXPECTNOTNIL(loader, @"loader should exist");
    EXPECTTRUE(loader.errors.count > 0, @"should have unresolved symbol error");
}

+(void)testReturnsNullForUnknownSymbol
{
    STMachOObjectFileLoader *loader = [self loaderForTestFile:@"add"];
    void *fn = [loader functionPointerForSymbol:@"_nonexistent"];
    EXPECTNIL(fn, @"should return NULL for unknown symbol");
}

+(NSArray*)testSelectors
{
    return @[
        @"testCanLoadSimpleObjectFile",
        @"testCanCallLoadedFunction",
        @"testCanCallFunctionWithExternalReference",
        @"testReturnsNullForUnknownSymbol",
    ];
}

@end
