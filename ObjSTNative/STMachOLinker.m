//
//  MPWMachOLinker.m
//  ObjSTNative
//
//  Internal linker: transforms object file data into a loadable dylib
//

#import "STMachOLinker.h"
#import "STMachOWriter.h"
#import "MPWMachOWriter+Private.h"
#import "MPWMachOSectionWriter.h"
#import "STMachODylibWriter.h"
#import "STBindOpcodeWriter.h"
#import "STNativeCompiler.h"
#import <dlfcn.h>

@implementation MPWInternalRelocation
@end

@implementation STMachOLinker

-(NSData*)linkToDylibWithInstallName:(NSString*)installName
                          fromWriter:(STMachOWriter*)objectWriter
{
    return [self linkToDylibWithInstallName:installName
                           sectionWriters:[objectWriter activeSectionWriters]
                             symbolWriter:objectWriter];
}

-(NSData*)linkToDylibWithInstallName:(NSString*)installName
                     sectionWriters:(NSArray<MPWMachOSectionWriter*>*)sections
                       symbolWriter:(STMachOWriter*)symbolSource
{
    STMachODylibWriter *dylibWriter = [STMachODylibWriter stream];
    dylibWriter.installName = installName;

    // Copy global symbols for export
    for (NSString *symbol in symbolSource.globalSymbolOffsets) {
        long offset = [symbolSource.globalSymbolOffsets[symbol] longValue];
        [dylibWriter declareGlobalSymbol:symbol atOffset:offset];
    }

    // Track section mappings: original section -> dylib section
    NSMutableDictionary<NSNumber*, MPWMachOSectionWriter*> *sectionMapping = [NSMutableDictionary dictionary];

    // Sections that go in __DATA_CONST: __got, __objc_classlist, __objc_imageinfo, __cfstring
    NSSet *dataConstSectionNames = [NSSet setWithObjects:@"__got", @"__objc_classlist",
                                                          @"__objc_imageinfo", @"__cfstring", nil];

    // Copy all __TEXT sections
    for (MPWMachOSectionWriter *section in sections) {
        if ([section.segname isEqualToString:@"__TEXT"]) {
            if ([section.sectname isEqualToString:@"__text"]) {
                [dylibWriter addTextSectionData:[section data]];
                sectionMapping[@((uintptr_t)section)] = dylibWriter.textSectionWriter;
            } else {
                MPWMachOSectionWriter *dylibSection = [dylibWriter addSectionWriterWithSegName:@"__TEXT"
                                                                                      sectName:section.sectname
                                                                                         flags:section.flags];
                [dylibSection appendBytes:[section data].bytes length:[section data].length];
                sectionMapping[@((uintptr_t)section)] = dylibSection;
            }
        }
    }

    // Check if we'll have a __DATA_CONST segment
    BOOL hasDataConstSegment = NO;
    for (MPWMachOSectionWriter *section in sections) {
        if ([section.segname isEqualToString:@"__DATA"] &&
            [dataConstSectionNames containsObject:section.sectname]) {
            hasDataConstSegment = YES;
            break;
        }
    }

    // Segment indices in the dylib:
    //   0: __TEXT
    //   1: __DATA_CONST (if present)
    //   2 or 1: __DATA
    //   last: __LINKEDIT
    int dataConstSegmentIndex = 1;
    int dataSegmentIndex = hasDataConstSegment ? 2 : 1;

    // Track section offsets within their segments
    // Sections within a segment are laid out sequentially
    NSMutableDictionary<NSNumber*, NSNumber*> *sectionOffsetWithinSegment = [NSMutableDictionary dictionary];
    long dataConstCurrentOffset = 0;
    long dataCurrentOffset = 0;

    // Copy all __DATA sections and track their offsets within segments
    for (MPWMachOSectionWriter *section in sections) {
        if ([section.segname isEqualToString:@"__DATA"]) {
            MPWMachOSectionWriter *dylibSection = [dylibWriter addSectionWriterWithSegName:@"__DATA"
                                                                                  sectName:section.sectname
                                                                                     flags:section.flags];
            [dylibSection appendBytes:[section data].bytes length:[section data].length];
            sectionMapping[@((uintptr_t)section)] = dylibSection;

            // Track offset within segment
            if ([dataConstSectionNames containsObject:section.sectname]) {
                sectionOffsetWithinSegment[@((uintptr_t)section)] = @(dataConstCurrentOffset);
                dataConstCurrentOffset += [section data].length;
                // Align to 8 bytes for next section
                dataConstCurrentOffset = (dataConstCurrentOffset + 7) & ~7;
            } else {
                sectionOffsetWithinSegment[@((uintptr_t)section)] = @(dataCurrentOffset);
                dataCurrentOffset += [section data].length;
                dataCurrentOffset = (dataCurrentOffset + 7) & ~7;
            }
        }
    }

    // Identify external symbols (undefined in the object file)
    NSMutableSet *externalSymbols = [NSMutableSet set];
    for (NSString *symbol in symbolSource.externalSymbolNames) {
        NSDictionary *info = symbolSource.symbolAddressInfo[symbol];
        int section = info ? [info[@"section"] intValue] : -1;
        if (info == nil || section == 0) {
            [externalSymbols addObject:symbol];
        }
    }

    // Create bind/rebase opcode writer
    STBindOpcodeWriter *bindWriter = [[[STBindOpcodeWriter alloc] init] autorelease];

    // Collect internal relocations for pointer patching
    NSMutableArray<MPWInternalRelocation*> *internalRelocations = [NSMutableArray array];

    // Process relocations and generate bind/rebase opcodes
    for (MPWMachOSectionWriter *section in sections) {
        int numRelocs = [section numRelocationEntries];
        if (numRelocs == 0) continue;

        MPWMachOSectionWriter *dylibSection = sectionMapping[@((uintptr_t)section)];
        if (!dylibSection) continue;

        // Determine segment index and base offset for this section
        int segIdx;
        long baseOffsetInSegment;

        if ([section.segname isEqualToString:@"__DATA"]) {
            if ([dataConstSectionNames containsObject:section.sectname]) {
                segIdx = dataConstSegmentIndex;
            } else {
                segIdx = dataSegmentIndex;
            }
            NSNumber *offsetNum = sectionOffsetWithinSegment[@((uintptr_t)section)];
            baseOffsetInSegment = offsetNum ? [offsetNum longValue] : 0;
        } else {
            // __TEXT relocations - shouldn't typically have bind/rebase
            continue;
        }

        for (int i = 0; i < numRelocs; i++) {
            NSString *symbolName = [section symbolNameForRelocationAtIndex:i];
            int sectionOffset = [section offsetForRelocationAtIndex:i];

            if (!symbolName) continue;

            // Compute segment-relative offset
            long segmentOffset = baseOffsetInSegment + sectionOffset;

            if ([externalSymbols containsObject:symbolName]) {
                // External symbol - needs bind opcode
                [bindWriter addBindForSymbol:symbolName atSegment:segIdx offset:segmentOffset];
//                NSLog(@"Linker: BIND %@ at segment %d offset 0x%lx", symbolName, segIdx, segmentOffset);
            } else {
                // Internal symbol - needs rebase opcode AND pointer patching
                [bindWriter addRebaseAtSegment:segIdx offset:segmentOffset];

                MPWInternalRelocation *reloc = [[[MPWInternalRelocation alloc] init] autorelease];
                reloc.symbolName = symbolName;
                reloc.patchSection = dylibSection;
                reloc.offsetInSection = sectionOffset;
                [internalRelocations addObject:reloc];
//                NSLog(@"Linker: REBASE+PATCH %@ at segment %d offset 0x%lx (section %@,%@)",
//                      symbolName, segIdx, segmentOffset, section.segname, section.sectname);
            }
        }
    }

    // Set bind opcode writer if we have any bindings or rebases
    NSData *bindData = [bindWriter bindOpcodeData];
    NSData *rebaseData = [bindWriter rebaseOpcodeData];
    if (bindData.length > 1 || rebaseData.length > 1) {
        dylibWriter.bindOpcodeWriter = bindWriter;
    }

    // Write the dylib file structure
    [dylibWriter generateMachO];

    // Patch internal pointers after section addresses are computed
    if (internalRelocations.count > 0) {
        // Build section number to dylib section mapping
        NSMutableDictionary<NSNumber*, MPWMachOSectionWriter*> *sectionNumToDylibSection = [NSMutableDictionary dictionary];
        int sectionNum = 1;
        for (MPWMachOSectionWriter *section in sections) {
            MPWMachOSectionWriter *dylibSection = sectionMapping[@((uintptr_t)section)];
            if (dylibSection) {
                sectionNumToDylibSection[@(sectionNum)] = dylibSection;
//                NSLog(@"Linker: section %d (%@,%@) -> dylib section at vmaddr=0x%lx",
//                      sectionNum, section.segname, section.sectname, dylibSection.address);
            } else {
//                NSLog(@"Linker: section %d (%@,%@) has NO dylib section mapping!",
//                      sectionNum, section.segname, section.sectname);
            }
            sectionNum++;
        }

        // Build symbol-to-address map
        NSMutableDictionary<NSString*, NSNumber*> *symbolAddresses = [NSMutableDictionary dictionary];
        for (NSString *symbol in symbolSource.symbolAddressInfo) {
            NSDictionary *info = symbolSource.symbolAddressInfo[symbol];
            int symbolSectionNum = [info[@"section"] intValue];
            long symbolOffset = [info[@"offset"] longValue];

            MPWMachOSectionWriter *dylibSection = sectionNumToDylibSection[@(symbolSectionNum)];
            if (dylibSection) {
                long symbolAddr = dylibSection.address + symbolOffset;
                symbolAddresses[symbol] = @(symbolAddr);
//                NSLog(@"Linker: symbol %@ -> section %d offset %ld -> vmaddr 0x%lx",
//                      symbol, symbolSectionNum, symbolOffset, symbolAddr);
            } else if (symbolSectionNum != 0) {
//                NSLog(@"Linker: symbol %@ in section %d NOT FOUND in sectionNumToDylibSection!",
//                      symbol, symbolSectionNum);
            }
        }

        // Patch each internal relocation
        NSMutableData *dylibData = (NSMutableData*)[dylibWriter target];
//        NSLog(@"Linker: patching %lu internal relocations", (unsigned long)internalRelocations.count);
        for (MPWInternalRelocation *reloc in internalRelocations) {
            NSNumber *targetAddrNum = symbolAddresses[reloc.symbolName];
            if (targetAddrNum) {
                long targetAddr = [targetAddrNum longValue];
                long sectionFileOffset = reloc.patchSection.offset;
                long pointerFileOffset = sectionFileOffset + reloc.offsetInSection;

                if (pointerFileOffset + 8 <= (long)dylibData.length) {
                    uint64_t *ptr = (uint64_t*)((uint8_t*)dylibData.mutableBytes + pointerFileOffset);
                    uint64_t oldValue = *ptr;
                    *ptr = (uint64_t)targetAddr;
//                    NSLog(@"Linker: PATCH %@ at file offset %ld: 0x%llx -> 0x%lx",
//                          reloc.symbolName, pointerFileOffset, oldValue, targetAddr);
                }
            } else {
                NSLog(@"Linker: FAILED to find address for %@", reloc.symbolName);
            }
        }
    }

    return [dylibWriter data];
}

@end


#import <MPWFoundation/DebugMacros.h>
#import <mach-o/loader.h>
#import "STMachOReader.h"

@implementation STMachOLinker(testing)

#pragma mark - Helper Methods

+(void)codesignDylibAtPath:(NSString*)path
{
    NSTask *task = [[[NSTask alloc] init] autorelease];
    task.launchPath = @"/usr/bin/codesign";
    task.arguments = @[@"-f", @"-s", @"-", path];
    task.standardOutput = [NSPipe pipe];
    task.standardError = [NSPipe pipe];
    [task launch];
    [task waitUntilExit];
}

#pragma mark - Basic Tests

+(void)testLinkEmptyWriterProducesDylib
{
    STMachOWriter *objectWriter = [STMachOWriter stream];

    unsigned char retCode[] = { 0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6 };
    [objectWriter.textSectionWriter declareGlobalTextSymbol:@"_testFunc"];
    [objectWriter addTextSectionData:[NSData dataWithBytes:retCode length:sizeof(retCode)]];

    STMachOLinker *linker = [[[self alloc] init] autorelease];
    NSData *dylib = [linker linkToDylibWithInstallName:@"@rpath/test.dylib" fromWriter:objectWriter];

    STMachOReader *reader = [[[STMachOReader alloc] initWithData:dylib] autorelease];
    EXPECTTRUE(reader.isHeaderValid, @"should produce valid Mach-O");
    INTEXPECT([reader filetype], MH_DYLIB, @"should be a dylib");
}

+(void)testLinkerExportsSymbols
{
    STMachOWriter *objectWriter = [STMachOWriter stream];

    unsigned char code[] = {
        0x40, 0x05, 0x80, 0x52,
        0xc0, 0x03, 0x5f, 0xd6
    };
    [objectWriter.textSectionWriter declareGlobalTextSymbol:@"_answer"];
    [objectWriter addTextSectionData:[NSData dataWithBytes:code length:sizeof(code)]];

    STMachOLinker *linker = [[[self alloc] init] autorelease];
    NSData *dylib = [linker linkToDylibWithInstallName:@"@rpath/test.dylib" fromWriter:objectWriter];

    STMachOReader *reader = [[[STMachOReader alloc] initWithData:dylib] autorelease];
    NSArray *exports = [reader exportedSymbolNames];
    EXPECTTRUE([exports containsObject:@"_answer"], @"symbol should be exported");

    NSString *path = @"/tmp/linker_test_exports.dylib";
    [dylib writeToFile:path atomically:YES];
    [self codesignDylibAtPath:path];

    void *handle = dlopen([path UTF8String], RTLD_NOW);
    EXPECTNOTNIL(handle, @"dylib should load");

    if (handle) {
        int (*answer)(void) = dlsym(handle, "answer");
        EXPECTNOTNIL(answer, @"symbol should be resolvable");
        if (answer) {
            INTEXPECT(answer(), 42, @"function should return 42");
        }
        dlclose(handle);
    }
}

+(void)testLinkerHandlesDataSections
{
    STMachOWriter *objectWriter = [STMachOWriter stream];

    unsigned char code[] = { 0xc0, 0x03, 0x5f, 0xd6 };
    [objectWriter.textSectionWriter declareGlobalTextSymbol:@"_dummy"];
    [objectWriter addTextSectionData:[NSData dataWithBytes:code length:sizeof(code)]];

    MPWMachOSectionWriter *dataSection = [objectWriter addSectionWriterWithSegName:@"__DATA"
                                                                          sectName:@"__mydata"
                                                                             flags:0];
    unsigned char someData[] = { 0x01, 0x02, 0x03, 0x04 };
    [dataSection appendBytes:someData length:sizeof(someData)];

    STMachOLinker *linker = [[[self alloc] init] autorelease];
    NSData *dylib = [linker linkToDylibWithInstallName:@"@rpath/test.dylib" fromWriter:objectWriter];

    STMachOReader *reader = [[[STMachOReader alloc] initWithData:dylib] autorelease];
    EXPECTTRUE(reader.isHeaderValid, @"should be valid Mach-O");
    EXPECTNOTNIL([reader segmentNamed:@"__DATA"], @"should have __DATA segment");

    NSString *path = @"/tmp/linker_test_data.dylib";
    [dylib writeToFile:path atomically:YES];
    [self codesignDylibAtPath:path];

    void *handle = dlopen([path UTF8String], RTLD_NOW);
    EXPECTNOTNIL(handle, @"dylib with __DATA section should load");
    if (handle) {
        dlclose(handle);
    }
}

+(void)testLinkerProducesValidSTClassDylib
{
    STNativeCompiler *compiler = [STNativeCompiler compiler];
    STClassDefinition *theClass = [compiler compile:@"class LinkerTestClass : NSObject { -<int>answerFortyTwo { 42. } }"];
    [compiler compileClassToMachoO:theClass];

    STMachOLinker *linker = [[[self alloc] init] autorelease];
    NSData *dylib = [linker linkToDylibWithInstallName:@"@rpath/LinkerTestClass.framework/LinkerTestClass"
                                            fromWriter:(STMachOWriter*)compiler.writer];

    STMachOReader *reader = [[[STMachOReader alloc] initWithData:dylib] autorelease];
    EXPECTTRUE(reader.isHeaderValid, @"should produce valid Mach-O");
    INTEXPECT([reader filetype], MH_DYLIB, @"should be a dylib");

    EXPECTNOTNIL([reader segmentNamed:@"__TEXT"], @"should have __TEXT segment");
    EXPECTNOTNIL([reader segmentNamed:@"__DATA"], @"should have __DATA segment");
    EXPECTNOTNIL([reader segmentNamed:@"__LINKEDIT"], @"should have __LINKEDIT segment");

    NSArray *exports = [reader exportedSymbolNames];
    EXPECTTRUE([exports containsObject:@"_OBJC_CLASS_$_LinkerTestClass"], @"should export class symbol");
    EXPECTTRUE([exports containsObject:@"_OBJC_METACLASS_$_LinkerTestClass"], @"should export metaclass symbol");
}

+(void)testLinkerIncludesBindAndRebaseOpcodes
{
    STNativeCompiler *compiler = [STNativeCompiler compiler];
    STClassDefinition *theClass = [compiler compile:@"class BindTestClass : NSObject { -<int>test { 42. } }"];
    [compiler compileClassToMachoO:theClass];

    STMachOLinker *linker = [[[self alloc] init] autorelease];
    NSData *dylib = [linker linkToDylibWithInstallName:@"@rpath/BindTestClass.framework/BindTestClass"
                                            fromWriter:(STMachOWriter*)compiler.writer];

    STMachOReader *reader = [[[STMachOReader alloc] initWithData:dylib] autorelease];
    EXPECTTRUE(reader.isHeaderValid, @"should have valid header");

    const struct dyld_info_command *dyldInfo =
        (const struct dyld_info_command*)[reader loadCommandOfTypeIfPresent:LC_DYLD_INFO_ONLY];
    EXPECTNOTNIL((id)(uintptr_t)dyldInfo, @"should have LC_DYLD_INFO_ONLY");

    if (dyldInfo) {
        EXPECTTRUE(dyldInfo->rebase_size > 0, @"should have rebase data");
        EXPECTTRUE(dyldInfo->bind_size > 0, @"should have bind data");
        EXPECTTRUE(dyldInfo->export_size > 0, @"should have export data");
    }
}

+(void)testExternalSymbolBindingProducesLoadableDylib
{
    STMachOWriter *objectWriter = [STMachOWriter stream];

    unsigned char code[] = { 0xc0, 0x03, 0x5f, 0xd6 };
    [objectWriter.textSectionWriter declareGlobalTextSymbol:@"_testfunc"];
    [objectWriter addTextSectionData:[NSData dataWithBytes:code length:sizeof(code)]];

    MPWMachOSectionWriter *dataSection = [objectWriter addSectionWriterWithSegName:@"__DATA"
                                                                          sectName:@"__got"
                                                                             flags:0];
    [objectWriter declareExternalSymbol:@"_malloc"];
    [dataSection addRelocationEntryForSymbol:@"_malloc" atOffset:0];
    char zeros[8] = {0};
    [dataSection appendBytes:zeros length:8];

    STMachOLinker *linker = [[[self alloc] init] autorelease];
    NSData *dylib = [linker linkToDylibWithInstallName:@"@rpath/test_bind.dylib" fromWriter:objectWriter];

    STMachOReader *reader = [[[STMachOReader alloc] initWithData:dylib] autorelease];
    EXPECTTRUE(reader.isHeaderValid, @"should be valid Mach-O");

    const struct dyld_info_command *dyldInfo =
        (const struct dyld_info_command*)[reader loadCommandOfTypeIfPresent:LC_DYLD_INFO_ONLY];
    EXPECTNOTNIL((id)(uintptr_t)dyldInfo, @"should have LC_DYLD_INFO_ONLY");
    if (dyldInfo) {
        EXPECTTRUE(dyldInfo->bind_size > 0, @"should have bind data for external symbol");
    }

    NSString *path = @"/tmp/test_bind.dylib";
    [dylib writeToFile:path atomically:YES];
    [self codesignDylibAtPath:path];

    void *handle = dlopen([path UTF8String], RTLD_NOW);
    EXPECTNOTNIL(handle, @"dylib with external binding should load");
    if (handle) {
        dlclose(handle);
    }
}

+(NSArray*)testSelectors
{
    return @[
        @"testLinkEmptyWriterProducesDylib",
        @"testLinkerExportsSymbols",
        @"testLinkerHandlesDataSections",
        @"testLinkerProducesValidSTClassDylib",
        @"testLinkerIncludesBindAndRebaseOpcodes",
        @"testExternalSymbolBindingProducesLoadableDylib",
    ];
}

@end
