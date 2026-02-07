//
//  MPWMachODylibWriter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.01.26.
//

#import "MPWMachODylibWriter.h"
#import "MPWBindOpcodeWriter.h"
#import "MPWChainedFixupWriter.h"
#import "MPWExportsTrieWriter.h"
#import "MPWMachOSection.h"
#import "MPWMachOSectionWriter.h"
#import "MPWMachOSegment.h"
#import "MPWMachOWriter+Private.h"
#import "MPWStringTableWriter.h"
#import "STJittableData.h"
#import <dlfcn.h>
#import <mach-o/loader.h>
#import <mach-o/arm64/reloc.h>
#import "STNativeCompiler.h"
#import "STBundle+ObjSTNative.h"
#import "MPWMachOObjectSerializer.h"


@interface MPWMachODylibWriter ()

@property(nonatomic, assign) long textSegmentSize;
@property(nonatomic, assign) long dataConstSegmentOffset;
@property(nonatomic, assign) long dataConstSegmentSize;
@property(nonatomic, assign) long dataSegmentOffset;
@property(nonatomic, assign) long dataSegmentSize;
@property(nonatomic, assign) long linkeditOffset;
@property(nonatomic, assign) long linkeditSize;
@property(nonatomic, strong) MPWChainedFixupWriter *chainedFixupWriter;
@property(nonatomic, strong) NSMutableDictionary *stubOffsets;
@property(nonatomic, strong) NSMutableDictionary *gotOffsets;
@property(nonatomic, strong) NSMutableArray *frameworks;
@property(nonatomic, strong) NSMutableArray *externalLibraries;
// ObjC message send support
@property(nonatomic, strong) NSMutableDictionary *objcStubOffsets;      // selector -> offset in __objc_stubs
@property(nonatomic, strong) NSMutableDictionary *objcMethnameOffsets;  // selector -> offset in __objc_methname
@property(nonatomic, strong) NSMutableDictionary *objcSelrefOffsets;    // selector -> offset in __objc_selrefs

@end

@interface MPWExternalLibrary : NSObject
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *path;
@property(nonatomic, strong) NSMutableSet<NSString *> *symbols;
@property(nonatomic, strong) NSArray<NSString *> *prefixes;
- (instancetype)initWithName:(NSString *)name
                        path:(NSString *)path
                     symbols:(NSArray<NSString *> *)symbols
                    prefixes:(NSArray<NSString *> *)prefixes;
- (BOOL)matchesSymbol:(NSString *)symbol;
- (BOOL)matchesPrefix:(NSString *)symbol;
@end

@implementation MPWExternalLibrary

- (instancetype)initWithName:(NSString *)name
                        path:(NSString *)path
                     symbols:(NSArray<NSString *> *)symbols
                    prefixes:(NSArray<NSString *> *)prefixes {
  self = [super init];
  if (self) {
    self.name = name;
    self.path = path;
    self.symbols = [NSMutableSet setWithArray:symbols ?: @[]];
    self.prefixes = prefixes ?: @[];
  }
  return self;
}

- (BOOL)matchesSymbol:(NSString *)symbol {
  return [self.symbols containsObject:symbol];
}

- (BOOL)matchesPrefix:(NSString *)symbol {
  for (NSString *prefix in self.prefixes) {
    if ([symbol hasPrefix:prefix]) {
      return YES;
    }
  }
  return NO;
}

@end

@interface MPWMachODylibWriter ()
- (void)generateStringTable;
@end

@implementation MPWMachODylibWriter

- (instancetype)initWithTarget:(id)aTarget {
  self = [super initWithTarget:aTarget];
  if (self) {
    self.filetype = MH_DYLIB;
    self.cputype = CPU_TYPE_ARM64;
    // Fix text section number to match Mach-O 1-based convention
    // (base class addSectionWriter: assigns 0-based, but textSectionNumber returns 1)
    self.textSectionWriter.sectionNumber = 1;
    self.currentVersion = 0x10000;       // 1.0.0
    self.compatibilityVersion = 0x10000; // 1.0.0
    self.chainedFixupWriter =
        [[[MPWChainedFixupWriter alloc] init] autorelease];
    self.stubOffsets = [NSMutableDictionary dictionary];
    self.gotOffsets = [NSMutableDictionary dictionary];
    self.frameworks = [NSMutableArray array];
    self.externalLibraries = [NSMutableArray array];
    [self addExternalLibraryPath:@"/usr/lib/libSystem.B.dylib"];
    [self addExternalLibraryPath:@"/usr/lib/libobjc.A.dylib"];
    // ObjC message send support
    self.objcStubOffsets = [NSMutableDictionary dictionary];
    self.objcMethnameOffsets = [NSMutableDictionary dictionary];
    self.objcSelrefOffsets = [NSMutableDictionary dictionary];
  }
  return self;
}

// Get all active section writers (both __TEXT and __DATA)
- (NSArray<MPWMachOSectionWriter *> *)activeSectionWriters {
  NSMutableArray *active = [NSMutableArray array];
  for (MPWMachOSectionWriter *writer in self.sectionWriters) {
    if (writer.isActive) {
      [active addObject:writer];
    }
  }
  return active;
}

// Get only __TEXT segment section writers
- (NSArray<MPWMachOSectionWriter *> *)textSectionWriters {
  NSMutableArray *writers = [NSMutableArray array];
  for (MPWMachOSectionWriter *writer in self.sectionWriters) {
    if (writer.isActive && [writer.segname isEqualToString:@"__TEXT"]) {
      [writers addObject:writer];
    }
  }
  return writers;
}

// Sections that belong in __DATA_CONST (read-only after fixups)
// Note: __objc_selrefs is NOT in DATA_CONST - it goes in __DATA because it needs rebasing
- (BOOL)sectionBelongsInDataConst:(NSString *)sectname {
  return [sectname isEqualToString:@"__got"] ||
         [sectname isEqualToString:@"__objc_classlist"] ||
         [sectname isEqualToString:@"__objc_imageinfo"] ||
         [sectname isEqualToString:@"__cfstring"] ||
         [sectname isEqualToString:@"__objc_protolist"] ||
         [sectname isEqualToString:@"__objc_protorefs"] ||
         [sectname isEqualToString:@"__objc_classrefs"] ||
         [sectname isEqualToString:@"__objc_superrefs"];
}

// Get only __DATA_CONST segment section writers
- (NSArray<MPWMachOSectionWriter *> *)dataConstSectionWriters {
  NSMutableArray *writers = [NSMutableArray array];
  for (MPWMachOSectionWriter *writer in self.sectionWriters) {
    if (writer.isActive && [writer.segname isEqualToString:@"__DATA_CONST"]) {
      [writers addObject:writer];
    }
    // Also include __DATA sections that belong in __DATA_CONST (legacy support)
    else if (writer.isActive && [writer.segname isEqualToString:@"__DATA"]) {
      if ([self sectionBelongsInDataConst:writer.sectname]) {
        [writers addObject:writer];
      }
    }
  }
  return writers;
}

// Get only __DATA segment section writers (excluding __DATA_CONST sections)
- (NSArray<MPWMachOSectionWriter *> *)dataSectionWriters {
  NSMutableArray *writers = [NSMutableArray array];
  for (MPWMachOSectionWriter *writer in self.sectionWriters) {
    if (writer.isActive && [writer.segname isEqualToString:@"__DATA"]) {
      // Exclude sections that go in __DATA_CONST
      if (![self sectionBelongsInDataConst:writer.sectname]) {
        [writers addObject:writer];
      }
    }
  }
  return writers;
}

- (BOOL)hasDataConstSegment {
  return [self dataConstSectionWriters].count > 0;
}

- (BOOL)hasDataSegment {
  return [self dataSectionWriters].count > 0;
}

- (BOOL)hasChainedFixups {
  return self.stubOffsets.count > 0 || self.gotOffsets.count > 0;
}

// Override to suppress section-level relocations for dylibs
// Dylibs use chained fixups instead of section relocations
- (MPWMachOSectionWriter *)addSectionWriterWithSegName:(NSString *)segname
                                              sectName:(NSString *)sectname
                                                 flags:(int)flags {
  MPWMachOSectionWriter *writer = [super addSectionWriterWithSegName:segname
                                                            sectName:sectname
                                                               flags:flags];
  writer.suppressRelocationInfo = YES;
  return writer;
}

- (MPWMachOSectionWriter *)stubSectionWriter {
  return [self
      addSectionWriterWithSegName:@"__TEXT"
                         sectName:@"__stubs"
                            flags:S_SYMBOL_STUBS | S_ATTR_SOME_INSTRUCTIONS |
                                  S_ATTR_PURE_INSTRUCTIONS];
}

- (MPWMachOSectionWriter *)objcStubSectionWriter {
  MPWMachOSectionWriter *writer = [self
      addSectionWriterWithSegName:@"__TEXT"
                         sectName:@"__objc_stubs"
                            flags:S_ATTR_SOME_INSTRUCTIONS |
                                  S_ATTR_PURE_INSTRUCTIONS];
  writer.alignment = 5; // 32-byte alignment like reference
  return writer;
}

- (MPWMachOSectionWriter *)objcMethnameSectionWriter {
  return [self
      addSectionWriterWithSegName:@"__TEXT"
                         sectName:@"__objc_methname"
                            flags:S_CSTRING_LITERALS];
}

- (MPWMachOSectionWriter *)objcSelrefsSectionWriter {
  // __objc_selrefs goes in __DATA (not __DATA_CONST) for rebase
  MPWMachOSectionWriter *writer =
      [self addSectionWriterWithSegName:@"__DATA"
                               sectName:@"__objc_selrefs"
                                  flags:S_LITERAL_POINTERS | S_ATTR_NO_DEAD_STRIP];
  writer.alignment = 3; // 8-byte alignment
  return writer;
}

- (MPWMachOSectionWriter *)gotSectionWriter {
  // __got goes in __DATA_CONST segment
  MPWMachOSectionWriter *writer =
      [self addSectionWriterWithSegName:@"__DATA_CONST"
                               sectName:@"__got"
                                  flags:S_NON_LAZY_SYMBOL_POINTERS];
  writer.alignment = 3; // 8-byte alignment
  return writer;
}

// Override to intercept external symbol declarations and _objc_msgSend$ symbols
// Route them through declareExternalSymbol: for stub/GOT creation
- (int)declareGlobalSymbol:(NSString *)symbol atOffset:(int)offset type:(int)theType section:(int)theSection {
  // ALWAYS intercept _objc_msgSend$ symbols - these are ObjC stubs, not real exports
  // They can come from declareExternalFunction (section=0) or addRelocationEntryForSymbol (section=1)
  NSString *selector = nil;
  if ([self isObjcMsgSendSymbol:symbol selector:&selector]) {
    // If we already have a stub for this selector, return its offset
    if (self.objcStubOffsets[selector]) {
      return [self.stubOffsets[symbol] intValue];
    }
    // Otherwise create the ObjC stub structures
    return [self declareObjcMsgSendForSelector:selector];
  }

  // Check if this symbol was already declared as an internal symbol
  // (e.g., from an explicit declareGlobalSymbol:atOffset: call with valid section)
  NSDictionary *existingInfo = self.symbolAddressInfo[symbol];
  if (existingInfo && [existingInfo[@"section"] intValue] > 0) {
    // Return the existing symbol index - don't re-declare
    return [self.globalSymbolOffsets[symbol] intValue];
  }

  // Check if this symbol was already declared as external (via declareExternalSymbol:).
  // This happens when addRelocationEntryForSymbol: re-calls declareGlobalSymbol
  // with a non-zero section (the cfstring section) for symbols like
  // ___CFConstantStringClassReference. We must NOT let it fall through to super,
  // which would add it to the symbol table as a defined symbol.
  if ([self.externalSymbolNames containsObject:symbol]) {
    return [self.stubOffsets[symbol] intValue];
  }

  // Only intercept external symbol declarations from code generator (section=0)
  // Don't intercept calls from within declareExternalSymbol -> super chain
  if (theSection == 0 && !self.stubOffsets[symbol]) {
    // External symbol not yet registered - create stubs and GOT entries
    return [self declareExternalSymbol:symbol];
  }
  return [super declareGlobalSymbol:symbol atOffset:offset type:theType section:theSection];
}

- (BOOL)isObjcMsgSendSymbol:(NSString *)symbol selector:(NSString **)outSelector {
  NSString *prefix = @"_objc_msgSend$";
  if ([symbol hasPrefix:prefix]) {
    if (outSelector) {
      *outSelector = [symbol substringFromIndex:prefix.length];
    }
    return YES;
  }
  return NO;
}

- (int)declareObjcMsgSendForSelector:(NSString *)selector {
  // Check if we already have an ObjC stub for this selector
  if (self.objcStubOffsets[selector]) {
    // Return stub offset for relocation
    NSString *fullSymbol = [@"_objc_msgSend$" stringByAppendingString:selector];
    return [self.stubOffsets[fullSymbol] intValue];
  }

  // Ensure _objc_msgSend is declared as external (only once)
  if (!self.gotOffsets[@"_objc_msgSend"]) {
    MPWMachOSectionWriter *gotWriter = [self gotSectionWriter];
    self.gotOffsets[@"_objc_msgSend"] = @(gotWriter.length);
    uint64_t dummy = 0;
    [gotWriter appendBytes:&dummy length:sizeof(dummy)];
    // Note: We don't call [super declareExternalSymbol:] here to avoid exporting
    // Instead, we manually add it to the bind info later
  }

  // 1. Add selector string to __objc_methname
  MPWMachOSectionWriter *methnameWriter = [self objcMethnameSectionWriter];
  self.objcMethnameOffsets[selector] = @(methnameWriter.length);
  const char *selectorCStr = [selector UTF8String];
  [methnameWriter appendBytes:selectorCStr length:strlen(selectorCStr) + 1];

  // 2. Add selector reference to __objc_selrefs
  MPWMachOSectionWriter *selrefsWriter = [self objcSelrefsSectionWriter];
  self.objcSelrefOffsets[selector] = @(selrefsWriter.length);
  uint64_t placeholder = 0; // Will be patched later with actual address
  [selrefsWriter appendBytes:&placeholder length:sizeof(placeholder)];

  // 3. Create ObjC stub (8 instructions = 32 bytes, aligned to 32 bytes)
  // The stub:
  //   adrp x1, __objc_selrefs@PAGE
  //   ldr  x1, [x1, __objc_selrefs@PAGEOFF]  ; load selector
  //   adrp x16, __got@PAGE
  //   ldr  x16, [x16, __got@PAGEOFF]         ; load _objc_msgSend
  //   br   x16
  //   brk  #0x1  ; padding
  //   brk  #0x1  ; padding
  //   brk  #0x1  ; padding
  MPWMachOSectionWriter *objcStubWriter = [self objcStubSectionWriter];

  // Store stub offset for this selector
  NSString *fullSymbol = [@"_objc_msgSend$" stringByAppendingString:selector];
  self.stubOffsets[fullSymbol] = @(objcStubWriter.length);
  self.objcStubOffsets[selector] = @(objcStubWriter.length);

  // Write placeholder instructions (will be patched in patchObjcStubs)
  uint32_t stubCode[8] = {
      0xd503201f, 0xd503201f, // nop, nop (adrp x1, ldr x1)
      0xd503201f, 0xd503201f, // nop, nop (adrp x16, ldr x16)
      0xd61f0200,             // br x16
      0xd4200020, 0xd4200020, 0xd4200020 // brk #1 padding
  };
  [objcStubWriter appendBytes:stubCode length:sizeof(stubCode)];

  // Return the index (stub offset) - don't call super to avoid exporting
  return (int)[self.stubOffsets[fullSymbol] intValue];
}

- (int)declareExternalSymbol:(NSString *)symbol {
  // If this symbol is already defined internally, don't treat it as external.
  // This happens when addClassReferenceForClass: calls declareExternalSymbol:
  // for a class that is being defined in this same dylib.
  NSDictionary *existingInfo = self.symbolAddressInfo[symbol];
  if (existingInfo && [existingInfo[@"section"] intValue] > 0) {
    return [self.globalSymbolOffsets[symbol] intValue];
  }

  // Check if this is an _objc_msgSend$ symbol
  NSString *selector = nil;
  if ([self isObjcMsgSendSymbol:symbol selector:&selector]) {
    return [self declareObjcMsgSendForSelector:selector];
  }

  // Regular external symbol handling
  if (!self.stubOffsets[symbol]) {
    MPWMachOSectionWriter *stubWriter = [self stubSectionWriter];
    self.stubOffsets[symbol] = @(stubWriter.length);

    // Initial placeholder for stub (3 instructions, 12 bytes)
    uint32_t stubCode[3] = {0xd503201f, 0xd503201f, 0xd503201f}; // 3x nop
    [stubWriter appendBytes:stubCode length:sizeof(stubCode)];

    MPWMachOSectionWriter *gotWriter = [self gotSectionWriter];
    self.gotOffsets[symbol] = @(gotWriter.length);
    uint64_t dummy = 0;
    [gotWriter appendBytes:&dummy length:sizeof(dummy)];
  }
  // For dylibs, external symbols are handled via chained fixups imports,
  // NOT via the symbol table. Don't call super - that would add the symbol
  // to the symbol table as a "common" symbol instead of an undefined external.
  // Just track in externalSymbolNames for reference.
  [self.externalSymbolNames addObject:symbol];
  return 0;
}

- (void)patchStubs {
  MPWMachOSectionWriter *stubWriter = [self stubSectionWriter];
  MPWMachOSectionWriter *gotWriter = [self gotSectionWriter];
  if (!stubWriter.isActive || !gotWriter.isActive) {
    return;
  }
  long gotAddr = gotWriter.address;
  long stubAddr = stubWriter.address;
  NSMutableData *stubData = (NSMutableData *)stubWriter.target;

  for (NSString *symbol in self.stubOffsets.allKeys) {
    // Skip ObjC stubs - they're handled by patchObjcStubs
    if ([self isObjcMsgSendSymbol:symbol selector:nil]) {
      continue;
    }
    // Also skip if this symbol doesn't have a GOT entry (e.g., internal symbols)
    if (!self.gotOffsets[symbol]) {
      continue;
    }

    long curStubOffset = [self.stubOffsets[symbol] longValue];
    long curStubAddr = stubAddr + curStubOffset;
    long curGotAddr = gotAddr + [self.gotOffsets[symbol] longValue];

    long pcPage = curStubAddr & ~0xFFF;
    long gotPage = curGotAddr & ~0xFFF;
    long pageDiff = (gotPage - pcPage) >> 12;

    uint32_t adrp = 0x90000010; // adrp x16, 0
    adrp |= (uint32_t)((pageDiff & 0x3) << 29);
    adrp |= (uint32_t)((pageDiff & 0x1FFFFC) << 3);

    uint32_t ldr = 0xf9400210; // ldr x16, [x16, #0]
    ldr |= (uint32_t)(((curGotAddr & 0xFFF) >> 3) << 10);

    uint32_t br = 0xd61f0200; // br x16

    uint32_t code[3] = {adrp, ldr, br};
    [stubData replaceBytesInRange:NSMakeRange(curStubOffset, sizeof(code))
                        withBytes:code];
  }
}

- (void)patchObjcStubs {
  MPWMachOSectionWriter *objcStubWriter = [self objcStubSectionWriter];
  MPWMachOSectionWriter *selrefsWriter = [self objcSelrefsSectionWriter];
  MPWMachOSectionWriter *gotWriter = [self gotSectionWriter];

  if (!objcStubWriter.isActive) {
    return;
  }

  long objcStubAddr = objcStubWriter.address;
  long selrefsAddr = selrefsWriter.address;
  long gotAddr = gotWriter.address;
  NSMutableData *objcStubData = (NSMutableData *)objcStubWriter.target;

  // Get the GOT offset for _objc_msgSend
  NSNumber *msgSendGotOffset = self.gotOffsets[@"_objc_msgSend"];
  if (!msgSendGotOffset) {
    return;
  }
  long msgSendGotAddr = gotAddr + [msgSendGotOffset longValue];

  for (NSString *selector in self.objcStubOffsets.allKeys) {
    long stubOffset = [self.objcStubOffsets[selector] longValue];
    long selrefOffset = [self.objcSelrefOffsets[selector] longValue];

    long curStubAddr = objcStubAddr + stubOffset;
    long curSelrefAddr = selrefsAddr + selrefOffset;

    // Generate: adrp x1, __objc_selrefs@PAGE
    long selrefPage = curSelrefAddr & ~0xFFF;
    long stubPage = curStubAddr & ~0xFFF;
    long selrefPageDiff = (selrefPage - stubPage) >> 12;

    uint32_t adrp_x1 = 0x90000001; // adrp x1, 0
    adrp_x1 |= (uint32_t)((selrefPageDiff & 0x3) << 29);
    adrp_x1 |= (uint32_t)((selrefPageDiff & 0x1FFFFC) << 3);

    // ldr x1, [x1, selref@PAGEOFF]
    uint32_t ldr_x1 = 0xf9400021; // ldr x1, [x1, #0]
    ldr_x1 |= (uint32_t)(((curSelrefAddr & 0xFFF) >> 3) << 10);

    // Generate: adrp x16, __got@PAGE (for _objc_msgSend)
    long gotPage = msgSendGotAddr & ~0xFFF;
    long stubAddr4 = (curStubAddr + 8) & ~0xFFF; // PC after 2 instructions
    long gotPageDiff = (gotPage - stubAddr4) >> 12;

    uint32_t adrp_x16 = 0x90000010; // adrp x16, 0
    adrp_x16 |= (uint32_t)((gotPageDiff & 0x3) << 29);
    adrp_x16 |= (uint32_t)((gotPageDiff & 0x1FFFFC) << 3);

    // ldr x16, [x16, got@PAGEOFF]
    uint32_t ldr_x16 = 0xf9400210; // ldr x16, [x16, #0]
    ldr_x16 |= (uint32_t)(((msgSendGotAddr & 0xFFF) >> 3) << 10);

    uint32_t br_x16 = 0xd61f0200; // br x16
    uint32_t brk = 0xd4200020;    // brk #1

    uint32_t code[8] = {adrp_x1, ldr_x1, adrp_x16, ldr_x16, br_x16, brk, brk, brk};
    [objcStubData replaceBytesInRange:NSMakeRange(stubOffset, sizeof(code)) withBytes:code];
  }
}

- (void)patchObjcSelrefs {
  MPWMachOSectionWriter *methnameWriter = [self objcMethnameSectionWriter];
  MPWMachOSectionWriter *selrefsWriter = [self objcSelrefsSectionWriter];

  if (!selrefsWriter.isActive || !methnameWriter.isActive) {
    return;
  }

  long methnameAddr = methnameWriter.address;
  NSMutableData *selrefsData = (NSMutableData *)selrefsWriter.target;

  for (NSString *selector in self.objcSelrefOffsets.allKeys) {
    long selrefOffset = [self.objcSelrefOffsets[selector] longValue];
    long methnameOffset = [self.objcMethnameOffsets[selector] longValue];

    // Selector reference points to the selector string in __objc_methname
    uint64_t selectorAddr = methnameAddr + methnameOffset;

    [selrefsData replaceBytesInRange:NSMakeRange(selrefOffset, sizeof(selectorAddr))
                           withBytes:&selectorAddr];
  }
}

- (long)resolveSymbolAddress:(NSString *)symbolName {
  // Check if this is an ObjC stub (for _objc_msgSend$selector)
  NSString *selector = nil;
  if ([self isObjcMsgSendSymbol:symbolName selector:&selector]) {
    MPWMachOSectionWriter *objcStubWriter = [self objcStubSectionWriter];
    if (self.objcStubOffsets[selector]) {
      return objcStubWriter.address + [self.objcStubOffsets[selector] longValue];
    }
  } else if (self.stubOffsets[symbolName]) {
    // Regular external symbol stub in __stubs section
    return self.stubSectionWriter.address +
                   [self.stubOffsets[symbolName] longValue];
  } else {
    // Internal symbol - use symbolAddressInfo to find correct section
    NSDictionary *info = self.symbolAddressInfo[symbolName];
    if (info) {
      int sectionNum = [info[@"section"] intValue];
      long offsetInSection = [info[@"offset"] longValue];
      for (MPWMachOSectionWriter *sw in self.sectionWriters) {
        if (sw.sectionNumber == sectionNum) {
          return sw.address + offsetInSection;
        }
      }
    }
  }
  return 0;
}

- (void)applyRelocations {
  for (MPWMachOSectionWriter *sectionWriter in [self activeSectionWriters]) {
    // Skip __DATA and __DATA_CONST sections - their relocations are handled
    // via chained fixups in buildChainedFixups, not via ARM64 instruction patching
    if ([sectionWriter.segname isEqualToString:@"__DATA"] ||
        [sectionWriter.segname isEqualToString:@"__DATA_CONST"]) {
      continue;
    }
    NSMutableData *sectionData = (NSMutableData *)sectionWriter.target;
    for (int i = 0; i < sectionWriter.numRelocationEntries; i++) {
      NSString *symbolName = [sectionWriter symbolNameForRelocationAtIndex:i];
      int offset = [sectionWriter offsetForRelocationAtIndex:i];
      int relocType = [sectionWriter typeOfRelocationAtIndex:i];

      if ([sectionWriter.segname isEqualToString:@"__DATA_CONST"] &&
          ([sectionWriter.sectname isEqualToString:@"__objc_arrayobj"] ||
           [sectionWriter.sectname isEqualToString:@"__objc_arraydata"])) {
        uint64_t before = 0;
        if (sectionData.length >= (NSUInteger)offset + 8) {
          [sectionData getBytes:&before range:NSMakeRange((NSUInteger)offset, 8)];
        }
        NSLog(@"applyRelocations BEFORE %@.%@ offset=0x%x relocType=%d symbol=%@ value=0x%llx",
              sectionWriter.segname, sectionWriter.sectname, offset, relocType, symbolName, before);
      }

      long targetAddr = [self resolveSymbolAddress:symbolName];

      if (targetAddr != 0) {
        long pcAddr = sectionWriter.address + offset;
        uint32_t instr;
        [sectionData getBytes:&instr range:NSMakeRange(offset, 4)];

        if (relocType == ARM64_RELOC_PAGE21) {
          // ADRP instruction: encode page-relative offset
          long pcPage = pcAddr & ~0xFFF;
          long targetPage = targetAddr & ~0xFFF;
          long pageDiff = (targetPage - pcPage) >> 12;
          // ADRP encoding: immhi (bits 5-23), immlo (bits 29-30)
          instr &= 0x9F00001F; // preserve opcode and Rd
          instr |= (uint32_t)((pageDiff & 0x3) << 29);     // immlo
          instr |= (uint32_t)(((pageDiff >> 2) & 0x7FFFF) << 5); // immhi
          [sectionData replaceBytesInRange:NSMakeRange(offset, 4)
                                 withBytes:&instr];
        } else if (relocType == ARM64_RELOC_PAGEOFF12) {
          // ADD immediate instruction: encode page offset (low 12 bits)
          long pageOff = targetAddr & 0xFFF;
          instr &= 0xFFC003FF; // preserve everything except imm12
          instr |= (uint32_t)((pageOff & 0xFFF) << 10);
          [sectionData replaceBytesInRange:NSMakeRange(offset, 4)
                                 withBytes:&instr];
        } else {
          // ARM64_RELOC_BRANCH26: branch instruction
          long delta = (targetAddr - pcAddr);
          instr &= 0xfc000000;
          instr |= (uint32_t)((delta >> 2) & 0x03ffffff);
          [sectionData replaceBytesInRange:NSMakeRange(offset, 4)
                                 withBytes:&instr];
        }
      }

    }
  }
}

- (MPWExternalLibrary *)libraryForPath:(NSString *)path {
  for (MPWExternalLibrary *library in self.externalLibraries) {
    if ([library.path isEqualToString:path]) {
      return library;
    }
  }
  return nil;
}

- (MPWExternalLibrary *)knownLibraryForPath:(NSString *)path {
  NSString *name = [path lastPathComponent];
  if ([name isEqualToString:@"libSystem.B.dylib"]) {
    return [[[MPWExternalLibrary alloc] initWithName:@"libSystem"
                                                path:path
                                             symbols:@[]
                                            prefixes:@[]] autorelease];
  }
  if ([name isEqualToString:@"libobjc.A.dylib"]) {
    return [[[MPWExternalLibrary alloc] initWithName:@"libobjc"
                                                path:path
                                             symbols:@[
                                               @"_objc_msgSend",
                                               @"__objc_empty_cache",
                                             ]
                                            prefixes:@[
                                              @"_OBJC_CLASS_$_",
                                              @"_OBJC_METACLASS_$_",
                                            ]] autorelease];
  }
  if ([name isEqualToString:@"CoreFoundation"]) {
    return [[[MPWExternalLibrary alloc] initWithName:@"CoreFoundation"
                                                path:path
                                             symbols:@[
                                               @"_OBJC_CLASS_$_NSConstantArray",
                                               @"_OBJC_CLASS_$_NSConstantDictionary",
                                               @"_OBJC_CLASS_$_NSConstantData",
                                               @"_OBJC_CLASS_$_NSConstantDate",
                                             ]
                                            prefixes:@[]] autorelease];
  }
  if ([name isEqualToString:@"Foundation"]) {
    return [[[MPWExternalLibrary alloc] initWithName:@"Foundation"
                                                path:path
                                             symbols:@[
                                               @"___CFConstantStringClassReference",
                                               @"_OBJC_CLASS_$_NSConstantIntegerNumber",
                                               @"_OBJC_CLASS_$_NSConstantDoubleNumber",
                                               @"_OBJC_CLASS_$_NSConstantFloatNumber",
                                             ]
                                            prefixes:@[]] autorelease];
  }
  if ([name isEqualToString:@"MPWFoundation"]) {
    return [[[MPWExternalLibrary alloc] initWithName:@"MPWFoundation"
                                                path:path
                                             symbols:@[]
                                            prefixes:@[@"_MPW"]] autorelease];
  }
  return [[[MPWExternalLibrary alloc] initWithName:name
                                              path:path
                                           symbols:@[]
                                          prefixes:@[]] autorelease];
}

- (MPWExternalLibrary *)externalLibraryForPath:(NSString *)path {
  MPWExternalLibrary *existing = [self libraryForPath:path];
  if (existing) {
    return existing;
  }
  MPWExternalLibrary *library = [self knownLibraryForPath:path];
  [self.externalLibraries addObject:library];
  return library;
}

- (void)addExternalLibraryPath:(NSString *)path {
  if (![self.frameworks containsObject:path]) {
    [self.frameworks addObject:path];
  }
  [self externalLibraryForPath:path];
}

- (int)ordinalForSymbol:(NSString *)symbol {
  int ordinal = 1; // Default to libSystem
  if (self.externalLibraries.count == 0) {
    return ordinal;
  }

  for (int i = 0; i < self.externalLibraries.count; i++) {
    MPWExternalLibrary *library = self.externalLibraries[i];
    if ([library matchesSymbol:symbol]) {
      return i + 1;
    }
  }

  for (int i = 0; i < self.externalLibraries.count; i++) {
    MPWExternalLibrary *library = self.externalLibraries[i];
    if ([library matchesPrefix:symbol]) {
      return i + 1;
    }
  }

  return ordinal;
}

- (void)buildChainedFixups {
  MPWMachOSectionWriter *gotWriter = [self gotSectionWriter];
  if (!gotWriter.isActive)
    return;

  // 1. Register binds for GOT entries in ChainedFixupWriter
  for (NSString *symbol in self.gotOffsets.allKeys) {
    long offset = [self.gotOffsets[symbol] longValue];
    int ordinal = [self ordinalForSymbol:symbol];
    int importOrdinal = [self.chainedFixupWriter addImport:symbol
                                                 fromDylib:ordinal];
    long dataConstVmaddr = self.textSegmentSize;
    long segmentOffset = gotWriter.address - dataConstVmaddr;
    [self.chainedFixupWriter addBindAtSegment:1 // __DATA_CONST
                                       offset:segmentOffset + offset
                                      ordinal:importOrdinal];
  }

  // 2. Register rebases for __objc_selrefs (if any)
  MPWMachOSectionWriter *selrefsWriter = [self objcSelrefsSectionWriter];
  MPWMachOSectionWriter *methnameWriter = [self objcMethnameSectionWriter];
  if (selrefsWriter.isActive && methnameWriter.isActive && self.objcSelrefOffsets.count > 0) {
    // __DATA segment index:
    // If we have __DATA_CONST: __TEXT=0, __DATA_CONST=1, __DATA=2
    // If no __DATA_CONST: __TEXT=0, __DATA=1
    int dataSegmentIndex = [self hasDataConstSegment] ? 2 : 1;

    // Calculate __DATA segment base address
    long dataSegmentVmaddr = self.textSegmentSize;
    if ([self hasDataConstSegment]) {
      long dataConstVmsize = (self.dataConstSegmentSize + 0x3FFF) & ~0x3FFF;
      if (dataConstVmsize == 0) dataConstVmsize = 0x4000;
      dataSegmentVmaddr += dataConstVmsize;
    }

    for (NSString *selector in self.objcSelrefOffsets.allKeys) {
      long selrefOffset = [self.objcSelrefOffsets[selector] longValue];
      long methnameOffset = [self.objcMethnameOffsets[selector] longValue];

      // The rebase target is the address of the selector string in __objc_methname
      uint64_t selectorStringAddr = methnameWriter.address + methnameOffset;

      // Offset within __DATA segment
      long selrefSegmentOffset = selrefsWriter.address - dataSegmentVmaddr + selrefOffset;

      [self.chainedFixupWriter addRebaseAtSegment:dataSegmentIndex
                                           offset:selrefSegmentOffset
                                           target:selectorStringAddr];
    }
  }

  // 2b. Process relocations from __DATA sections (like __string for constant NSStrings)
  // These have relocation entries that need to be converted to chained fixups
  int dataSegmentIndex = [self hasDataConstSegment] ? 2 : 1;
  long dataSegmentVmaddr = self.textSegmentSize;
  if ([self hasDataConstSegment]) {
    long dataConstVmsize = (self.dataConstSegmentSize + 0x3FFF) & ~0x3FFF;
    if (dataConstVmsize == 0) dataConstVmsize = 0x4000;
    dataSegmentVmaddr += dataConstVmsize;
  }

  for (MPWMachOSectionWriter *sectionWriter in [self dataSectionWriters]) {
    int numRelocs = [sectionWriter numRelocationEntries];
    if (numRelocs > 0) {
      for (int i = 0; i < numRelocs; i++) {
        NSString *symbolName = [sectionWriter symbolNameForRelocationAtIndex:i];
        int relocOffset = [sectionWriter offsetForRelocationAtIndex:i];
        long segmentOffset = sectionWriter.address - dataSegmentVmaddr + relocOffset;

        // Check if this is an external symbol (needs bind) or internal (needs rebase)
        // External symbols are tracked in gotOffsets
        if (self.gotOffsets[symbolName]) {
          // External symbol - needs a bind
          int ordinal = [self ordinalForSymbol:symbolName];
          int importOrdinal = [self.chainedFixupWriter addImport:symbolName fromDylib:ordinal];

          [self.chainedFixupWriter addBindAtSegment:dataSegmentIndex
                                             offset:segmentOffset
                                            ordinal:importOrdinal];
        } else {
          // Internal symbol - this is a rebase to a local address
          long targetAddr = [self resolveSymbolAddress:symbolName];
          [self.chainedFixupWriter addRebaseAtSegment:dataSegmentIndex
                                               offset:segmentOffset
                                               target:targetAddr];
        }
      }
    }
  }

  // 2c. Process relocations from __DATA_CONST sections (excluding __got, handled in step 1)
  // Sections like __objc_classlist have relocations that need chained fixups
  {
    long dataConstVmaddr2 = self.textSegmentSize;
    for (MPWMachOSectionWriter *sectionWriter in [self dataConstSectionWriters]) {
      if ([sectionWriter.sectname isEqualToString:@"__got"]) continue; // already handled in step 1
      int numRelocs = [sectionWriter numRelocationEntries];
      if (numRelocs > 0) {
        for (int i = 0; i < numRelocs; i++) {
          NSString *symbolName = [sectionWriter symbolNameForRelocationAtIndex:i];
          int relocOffset = [sectionWriter offsetForRelocationAtIndex:i];
          long segmentOffset = sectionWriter.address - dataConstVmaddr2 + relocOffset;

          if (self.gotOffsets[symbolName]) {
            int ordinal = [self ordinalForSymbol:symbolName];
            int importOrdinal = [self.chainedFixupWriter addImport:symbolName fromDylib:ordinal];
            NSLog(@"Step 2c: %@ ordinal=%d importOrdinal=%d segmentOffset=0x%lx", symbolName, ordinal, importOrdinal, segmentOffset);
            [self.chainedFixupWriter addBindAtSegment:1 offset:segmentOffset ordinal:importOrdinal];
          } else {
            long targetAddr = [self resolveSymbolAddress:symbolName];
            [self.chainedFixupWriter addRebaseAtSegment:1 offset:segmentOffset target:targetAddr];
          }
        }
      }
    }
  }

  // 3. Generate metadata to compute 'next' pointers
  [self.chainedFixupWriter fixupDataWithSegmentCount:[self segmentCount]];

  // 4. Patch __DATA_CONST section fixups (GOT binds, classlist rebases, etc.)
  {
    NSArray *segFixups = [self.chainedFixupWriter fixupsForSegment:1];
    NSLog(@"Step 4: segment 1 has %lu fixups", (unsigned long)segFixups.count);
    for (MPWChainedFixup *dbg in segFixups) {
        NSLog(@"  Fixup: offset=0x%llx ordinal=%d isRebase=%d", dbg.offset, dbg.ordinal, dbg.isRebase);
    }
    long dataConstVmaddr = self.textSegmentSize;

    for (MPWChainedFixup *f in segFixups) {
      // Find the section writer that contains this fixup offset
      BOOL foundSection = NO;
      for (MPWMachOSectionWriter *sectionWriter in [self dataConstSectionWriters]) {
        long sectionSegStart = sectionWriter.address - dataConstVmaddr;
        long sectionSegEnd = sectionSegStart + sectionWriter.length;

        if (f.offset >= sectionSegStart && f.offset < sectionSegEnd) {
          NSMutableData *sectionData = (NSMutableData *)sectionWriter.target;
          long f_section_offset = f.offset - sectionSegStart;

          if ([sectionWriter.sectname isEqualToString:@"__objc_arrayobj"]) {
            uint64_t before = 0;
            if (sectionData.length >= (NSUInteger)f_section_offset + 8) {
              [sectionData getBytes:&before range:NSMakeRange((NSUInteger)f_section_offset, 8)];
            }
            NSLog(@"BEFORE patch __objc_arrayobj[0x%lx] = 0x%llx", f_section_offset, before);
          }

          uint64_t bits;
          if (f.isRebase) {
            bits = [self.chainedFixupWriter rebase64Bits:f.rebaseTarget next:f.next];
          } else {
            bits = [self.chainedFixupWriter bind64Bits:f.ordinal next:f.next];
            NSLog(@"Step 4: patch bind ordinal=%d next=%d at section %@.%@ f_offset=0x%lx bits=0x%llx",
                  f.ordinal, f.next, sectionWriter.segname, sectionWriter.sectname, f_section_offset, bits);
          }
          [sectionData replaceBytesInRange:NSMakeRange((NSUInteger)f_section_offset, 8)
                                 withBytes:&bits];

          if ([sectionWriter.sectname isEqualToString:@"__objc_arrayobj"]) {
            uint64_t after = 0;
            [sectionData getBytes:&after range:NSMakeRange((NSUInteger)f_section_offset, 8)];
            NSLog(@"AFTER patch __objc_arrayobj[0x%lx] = 0x%llx", f_section_offset, after);
          }

          foundSection = YES;
          break;
        }
      }
      if (!foundSection) {
          NSLog(@"Step 4: WARNING - no section found for fixup at offset=0x%llx ordinal=%d isRebase=%d",
                f.offset, f.ordinal, f.isRebase);
      }
    }
  }

  // 5. Patch __DATA section fixups (selrefs, __string, etc.)
  {
    int dataSegIdx = [self hasDataConstSegment] ? 2 : 1;
    NSArray *dataSegFixups = [self.chainedFixupWriter fixupsForSegment:dataSegIdx];

    long dataSegVmaddr = self.textSegmentSize;
    if ([self hasDataConstSegment]) {
      long dataConstVmsize = (self.dataConstSegmentSize + 0x3FFF) & ~0x3FFF;
      if (dataConstVmsize == 0) dataConstVmsize = 0x4000;
      dataSegVmaddr += dataConstVmsize;
    }

    // For each fixup, find which section it belongs to and patch it
    for (MPWChainedFixup *f in dataSegFixups) {
      // Find the section writer that contains this fixup offset
      for (MPWMachOSectionWriter *sectionWriter in [self dataSectionWriters]) {
        long sectionSegStart = sectionWriter.address - dataSegVmaddr;
        long sectionSegEnd = sectionSegStart + sectionWriter.length;

        if (f.offset >= sectionSegStart && f.offset < sectionSegEnd) {
          NSMutableData *sectionData = (NSMutableData *)sectionWriter.target;
          long f_section_offset = f.offset - sectionSegStart;

          uint64_t bits;
          if (f.isRebase) {
            bits = [self.chainedFixupWriter rebase64Bits:f.rebaseTarget next:f.next];
          } else {
            bits = [self.chainedFixupWriter bind64Bits:f.ordinal next:f.next];
          }
          [sectionData replaceBytesInRange:NSMakeRange((NSUInteger)f_section_offset, 8)
                                 withBytes:&bits];
          break;
        }
      }
    }
  }
}

- (int)segmentCount {
  int count = 1; // __TEXT
  if ([self hasDataConstSegment])
    count++;
  if ([self hasDataSegment])
    count++;
  count++; // __LINKEDIT
  return count;
}

- (int)chainedFixupsSize {
  return (int)[self.chainedFixupWriter
             fixupDataWithSegmentCount:[self segmentCount]]
      .length;
}

- (int)alignedChainedFixupsSize {
  return ([self chainedFixupsSize] + 7) & ~7;
}

- (void)writeChainedFixupsLoadCommand {
  struct linkedit_data_command cmd = {};
  cmd.cmd = LC_DYLD_CHAINED_FIXUPS;
  cmd.cmdsize = sizeof(struct linkedit_data_command);

  uint32_t currentOffset = (uint32_t)self.linkeditOffset;
  currentOffset += [self alignedRebaseDataSize];
  currentOffset += [self alignedBindDataSize];
  currentOffset += [self exportTrieSize];

  cmd.dataoff = currentOffset;
  cmd.datasize = [self chainedFixupsSize];
  [self appendBytes:&cmd length:sizeof cmd];
}

#pragma mark - Header

- (void)writeHeader {
  struct mach_header_64 header = {};
  header.magic = MH_MAGIC_64;
  header.cputype = self.cputype;
  header.cpusubtype = CPU_SUBTYPE_ARM64_ALL;
  header.filetype = MH_DYLIB;
  header.ncmds = self.numLoadCommands;
  header.sizeofcmds = self.loadCommandSize;
  header.flags =
      MH_NOUNDEFS | MH_DYLDLINK | MH_TWOLEVEL | MH_NO_REEXPORTED_DYLIBS;
  [self appendBytes:&header length:sizeof header];
}

#pragma mark - Load Commands

- (int)idDylibCommandSize {
  // LC_ID_DYLIB: header + path string (padded to 8-byte alignment)
  int nameLen = (int)[self.installName length] + 1;
  int totalSize = sizeof(struct dylib_command) + nameLen;
  // Pad to 8-byte alignment
  totalSize = (totalSize + 7) & ~7;
  return totalSize;
}

- (void)writeIdDylibLoadCommand {
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

- (int)textSegmentCommandSize {
  return sizeof(struct segment_command_64) +
         ([self textSectionWriters].count * sizeof(struct section_64));
}

- (int)dataConstSegmentCommandSize {
  NSArray *dataConstSections = [self dataConstSectionWriters];
  if (dataConstSections.count == 0) {
    return 0;
  }
  return sizeof(struct segment_command_64) +
         (dataConstSections.count * sizeof(struct section_64));
}

- (int)dataSegmentCommandSize {
  NSArray *dataSections = [self dataSectionWriters];
  if (dataSections.count == 0) {
    return 0;
  }
  return sizeof(struct segment_command_64) +
         (dataSections.count * sizeof(struct section_64));
}

// Override: dylib has sections spread across multiple segments,
// so we match by sectionNumber property instead of array index.
-(void)adjustSymtabEntries
{
    symtab_entry *entries = [self symtabEntries];
    NSArray<MPWMachOSectionWriter*> *allWriters = self.sectionWriters;

    for (int i=0; i<symtabCount; i++) {
        int sect = entries[i].section;
        for (MPWMachOSectionWriter *w in allWriters) {
            if (w.sectionNumber == sect) {
                entries[i].address += w.address;
                break;
            }
        }
    }
}

- (void)writeTextSegmentLoadCommand {
  NSArray *writers = [self textSectionWriters];

  // Use pre-computed values from writeFile
  // textSegmentSize and linkeditOffset are already computed

  // __TEXT filesize goes up to the next segment
  long textFilesize;
  if ([self hasDataConstSegment]) {
    textFilesize = self.dataConstSegmentOffset;
  } else if ([self hasDataSegment]) {
    textFilesize = self.dataSegmentOffset;
  } else {
    textFilesize = self.linkeditOffset;
  }

  struct segment_command_64 segment = {};
  segment.cmd = LC_SEGMENT_64;
  segment.cmdsize = [self textSegmentCommandSize];
  strncpy(segment.segname, "__TEXT", 16);
  segment.vmaddr = 0;
  segment.vmsize = self.textSegmentSize;
  segment.fileoff = 0;
  segment.filesize = textFilesize;
  segment.maxprot = VM_PROT_READ | VM_PROT_EXECUTE;
  segment.initprot = VM_PROT_READ | VM_PROT_EXECUTE;
  segment.nsects = (uint32_t)writers.count;
  segment.flags = 0;

  [self appendBytes:&segment length:sizeof segment];

  for (MPWMachOSectionWriter *writer in writers) {
    //    writer.writeRelocationInfo = NO;          // FIXME: this used to be
    //    here
    [writer writeSectionLoadCommandOnWriter:self];
  }

  // Adjust symbol table entries to use actual vmaddrs
  [self adjustSymtabEntries];
}


- (void)writeDataConstSegmentLoadCommand {
  NSArray *writers = [self dataConstSectionWriters];
  if (writers.count == 0)
    return;

  struct segment_command_64 segment = {};
  segment.cmd = LC_SEGMENT_64;
  segment.cmdsize = [self dataConstSegmentCommandSize];
  strncpy(segment.segname, "__DATA_CONST", 16);
  segment.vmaddr = self.dataConstSegmentOffset;
  segment.vmsize = self.dataConstSegmentSize;
  segment.fileoff = self.dataConstSegmentOffset;
  segment.fileoff = self.dataConstSegmentOffset;
  segment.filesize = self.dataConstSegmentSize;
  segment.maxprot = VM_PROT_READ | VM_PROT_WRITE;
  segment.initprot = VM_PROT_READ | VM_PROT_WRITE;
  segment.nsects = (uint32_t)writers.count;
  segment.flags = 0x10; // SG_READ_ONLY

  [self appendBytes:&segment length:sizeof segment];

  for (MPWMachOSectionWriter *writer in writers) {
    //    writer.writeRelocationInfo = NO;   // FIXME:  used to be here.
    [writer writeSectionLoadCommandOnWriter:self];
  }
}

- (void)writeDataSegmentLoadCommand {
  NSArray *writers = [self dataSectionWriters];
  if (writers.count == 0)
    return;

  struct segment_command_64 segment = {};
  segment.cmd = LC_SEGMENT_64;
  segment.cmdsize = [self dataSegmentCommandSize];
  strncpy(segment.segname, "__DATA", 16);
  segment.vmaddr = self.dataSegmentOffset;
  segment.vmsize = self.dataSegmentSize;
  segment.fileoff = self.dataSegmentOffset;
  segment.fileoff = self.dataSegmentOffset;
  segment.filesize = self.dataSegmentSize;
  segment.maxprot = VM_PROT_READ | VM_PROT_WRITE;
  segment.initprot = VM_PROT_READ | VM_PROT_WRITE;
  segment.nsects = (uint32_t)writers.count;
  segment.flags = 0;

  [self appendBytes:&segment length:sizeof segment];

  for (MPWMachOSectionWriter *writer in writers) {
    //    writer.writeRelocationInfo = NO;   // FIXME:  this used to be here.
    [writer writeSectionLoadCommandOnWriter:self];
  }
}

- (void)writeLinkeditSegmentLoadCommand {
  // __LINKEDIT vmaddr is after __TEXT, __DATA_CONST, and __DATA
  long linkeditVmaddr = self.textSegmentSize;
  if ([self hasDataConstSegment]) {
    long dataConstVmsize = (self.dataConstSegmentSize + 0x3FFF) & ~0x3FFF;
    if (dataConstVmsize == 0)
      dataConstVmsize = 0x4000;
    linkeditVmaddr += dataConstVmsize;
  }
  if ([self hasDataSegment]) {
    long dataVmsize = (self.dataSegmentSize + 0x3FFF) & ~0x3FFF;
    if (dataVmsize == 0)
      dataVmsize = 0x4000;
    linkeditVmaddr += dataVmsize;
  }

  struct segment_command_64 segment = {};
  segment.cmd = LC_SEGMENT_64;
  segment.cmdsize = sizeof(struct segment_command_64);
  strncpy(segment.segname, "__LINKEDIT", 16);
  segment.vmaddr = linkeditVmaddr;
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

- (int)exportTrieSize {
  // Use class method to compute size from symbol names alone
  return [MPWExportsTrieWriter
      trieSizeForSymbols:self.globalSymbolOffsets.allKeys];
}

- (BOOL)hasBindData {
  return self.bindOpcodeWriter != nil;
}

- (int)rebaseDataSize {
  if (!self.bindOpcodeWriter)
    return 0;
  return (int)[self.bindOpcodeWriter rebaseOpcodeData].length;
}

- (int)bindDataSize {
  if (!self.bindOpcodeWriter)
    return 0;
  return (int)[self.bindOpcodeWriter bindOpcodeData].length;
}

// Helper to compute 8-byte aligned size
- (int)alignedRebaseDataSize {
  int size = [self rebaseDataSize];
  return (size + 7) & ~7; // Round up to 8-byte boundary
}

- (int)alignedBindDataSize {
  int size = [self bindDataSize];
  return (size + 7) & ~7; // Round up to 8-byte boundary
}

- (void)writeDyldInfoLoadCommand {
  if (![self hasBindData])
    return;

  struct dyld_info_command cmd = {};
  cmd.cmd = LC_DYLD_INFO_ONLY;
  cmd.cmdsize = sizeof(struct dyld_info_command);

  // Layout in __LINKEDIT: rebase, (padding), bind, (padding), exports, symtab,
  // strtab Each section must be 8-byte aligned
  uint32_t currentOffset = (uint32_t)self.linkeditOffset;

  cmd.rebase_off = currentOffset;
  cmd.rebase_size = [self rebaseDataSize];
  currentOffset +=
      [self alignedRebaseDataSize]; // Use aligned size for next offset

  cmd.bind_off = currentOffset;
  cmd.bind_size = [self bindDataSize];
  currentOffset +=
      [self alignedBindDataSize]; // Use aligned size for next offset

  // We don't use weak_bind or lazy_bind
  cmd.weak_bind_off = 0;
  cmd.weak_bind_size = 0;
  cmd.lazy_bind_off = 0;
  cmd.lazy_bind_size = 0;

  // Exports trie comes after bind data (aligned)
  cmd.export_off = currentOffset;
  cmd.export_size = [self exportTrieSize];

  [self appendBytes:&cmd length:sizeof cmd];
}

// Compute offset where exports trie starts in __LINKEDIT
- (long)exportsTrieOffset {
  // __LINKEDIT layout: rebase, (padding), bind, (padding), exports, symtab,
  // strtab
  return self.linkeditOffset + [self alignedRebaseDataSize] +
         [self alignedBindDataSize];
}

- (void)writeExportsTrieLoadCommand {
  // Only write if we don't have LC_DYLD_INFO_ONLY (which includes exports)
  if ([self hasBindData])
    return;

  struct linkedit_data_command cmd = {};
  cmd.cmd = LC_DYLD_EXPORTS_TRIE;
  cmd.cmdsize = sizeof(struct linkedit_data_command);
  cmd.dataoff = (uint32_t)[self exportsTrieOffset];
  cmd.datasize = [self exportTrieSize];

  [self appendBytes:&cmd length:sizeof cmd];
}

- (void)writeSymbolTableLoadCommand {
  struct symtab_command symtab = {};
  symtab.cmd = LC_SYMTAB;
  symtab.cmdsize = sizeof symtab;
  symtab.nsyms = [self numSymbols];
  uint32_t offset =
      (uint32_t)([self exportsTrieOffset] + [self exportTrieSize]);
  if ([self hasChainedFixups]) {
    offset += [self alignedChainedFixupsSize];
  }
  symtab.symoff = offset;
  symtab.stroff = (uint32_t)(symtab.symoff + [self symbolTableSize]);
  symtab.strsize = (uint32_t)[self.stringTableWriter length];
  [self appendBytes:&symtab length:sizeof symtab];
}

- (void)writeDysymtabLoadCommand {
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
- (void)writePlatformLoadCommand {
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

- (void)writeUUIDLoadCommand {
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
  uuid.uuid[6] = (uuid.uuid[6] & 0x0F) | 0x40; // Version 4
  uuid.uuid[8] = (uuid.uuid[8] & 0x3F) | 0x80; // Variant

  [self appendBytes:&uuid length:sizeof uuid];
}

- (int)loadDylibCommandSizeForPath:(NSString *)path {
  int nameLen = (int)[path length] + 1;
  int totalSize = sizeof(struct dylib_command) + nameLen;
  // Pad to 8-byte alignment
  totalSize = (totalSize + 7) & ~7;
  return totalSize;
}

- (void)writeLoadDylibCommand:(NSString *)path {
  int cmdSize = [self loadDylibCommandSizeForPath:path];
  struct dylib_command cmd = {};
  cmd.cmd = LC_LOAD_DYLIB;
  cmd.cmdsize = cmdSize;
  cmd.dylib.name.offset = sizeof(struct dylib_command);
  cmd.dylib.timestamp = 2;
  cmd.dylib.current_version = 0x10000; // 1.0.0
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

- (NSData *)buildExportsTrie {
  MPWExportsTrieWriter *trieWriter =
      [[[MPWExportsTrieWriter alloc] init] autorelease];

  // Add all global symbols to the exports trie writer
  // EXCEPT: _objc_msgSend$ symbols which are ObjC stubs, not real exports
  for (NSString *symbol in self.globalSymbolOffsets.allKeys) {
    // Skip _objc_msgSend$ symbols - they are internal stubs, not real exports
    if ([self isObjcMsgSendSymbol:symbol selector:nil]) {
      continue;
    }

    // Use resolveSymbolAddress: to get correct address for symbols in any section
    long address = [self resolveSymbolAddress:symbol];
    if ([symbol containsString:@"constant_ns"]) {
      NSDictionary *info = self.symbolAddressInfo[symbol];
      NSLog(@"exportsTrie: symbol=%@ address=0x%lx info=%@", symbol, address, info);
    }
    [trieWriter addSymbol:symbol atAddress:address];
  }

  return [trieWriter trieData];
}

#pragma mark - Write Sections

- (void)writeSections {
  // Only write __TEXT segment sections here
  // __DATA_CONST and __DATA sections are written separately after padding
  NSArray *writers = [self textSectionWriters];

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

- (void)writeLinkeditData {
  // __LINKEDIT layout: rebase, bind, exports, symtab, strtab
  // Each section must be 8-byte aligned

  // Write rebase data (if any)
  if (self.bindOpcodeWriter) {
    NSData *rebaseData = [self.bindOpcodeWriter rebaseOpcodeData];
    [self appendBytes:rebaseData.bytes length:rebaseData.length];

    // Pad to 8-byte alignment before bind data
    long rebasePadding = (8 - (rebaseData.length % 8)) % 8;
    if (rebasePadding > 0) {
      char zeros[8] = {0};
      [self appendBytes:zeros length:rebasePadding];
    }
  }

  // Write bind data (if any)
  if (self.bindOpcodeWriter) {
    NSData *bindData = [self.bindOpcodeWriter bindOpcodeData];
    [self appendBytes:bindData.bytes length:bindData.length];

    // Pad to 8-byte alignment before exports trie
    long bindPadding = (8 - (bindData.length % 8)) % 8;
    if (bindPadding > 0) {
      char zeros[8] = {0};
      [self appendBytes:zeros length:bindPadding];
    }
  }

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

  // Chained fixups
  if ([self hasChainedFixups]) {
    NSData *fixupData =
        [self.chainedFixupWriter fixupDataWithSegmentCount:[self segmentCount]];
    [self appendBytes:fixupData.bytes length:fixupData.length];

    // Pad to maintain alignment
    long fixupPadding = [self alignedChainedFixupsSize] - fixupData.length;
    if (fixupPadding > 0) {
      char zeros[8] = {0};
      [self appendBytes:zeros length:fixupPadding];
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

- (void)writeFile {
  // Calculate sizes
  int idDylibSize = [self idDylibCommandSize];
  int textSegmentCmdSize = [self textSegmentCommandSize];
  int dataConstSegmentCmdSize = [self dataConstSegmentCommandSize];
  int dataSegmentCmdSize = [self dataSegmentCommandSize];
  int linkeditSegmentCmdSize = sizeof(struct segment_command_64);
  int symtabCmdSize = sizeof(struct symtab_command);
  int dysymtabCmdSize = sizeof(struct dysymtab_command);
  int buildVersionCmdSize = sizeof(struct build_version_command);
  int uuidCmdSize = sizeof(struct uuid_command);
  int loadLibSystemCmdSize =
      [self loadDylibCommandSizeForPath:@"/usr/lib/libSystem.B.dylib"];

  BOOL hasDataConst = [self hasDataConstSegment];
  BOOL hasData = [self hasDataSegment];
  BOOL hasBind = [self hasBindData];
  BOOL hasChained = [self hasChainedFixups];

  // Chained fixups command size
  int chainedFixupsCmdSize =
      hasChained ? sizeof(struct linkedit_data_command) : 0;

  // If we have bind data, use LC_DYLD_INFO_ONLY instead of LC_DYLD_EXPORTS_TRIE
  int dyldInfoCmdSize = hasBind ? sizeof(struct dyld_info_command)
                                : sizeof(struct linkedit_data_command);

  // Count load commands: base 8 + modifiers
  self.numLoadCommands = 8 + (int)self.frameworks.count +
                         (hasDataConst ? 1 : 0) + (hasData ? 1 : 0) +
                         (hasChained ? 1 : 0);
  int loadDylibsSize = 0;
  for (NSString *path in self.frameworks) {
    loadDylibsSize += [self loadDylibCommandSizeForPath:path];
  }

  self.loadCommandSize = textSegmentCmdSize + dataConstSegmentCmdSize +
                         dataSegmentCmdSize + linkeditSegmentCmdSize +
                         idDylibSize + uuidCmdSize + loadDylibsSize +
                         dyldInfoCmdSize + symtabCmdSize + dysymtabCmdSize +
                         buildVersionCmdSize + chainedFixupsCmdSize;

  // Generate string table before computing offsets
  [self generateStringTable];

  // Compute segment data start (reserve space for LC_CODE_SIGNATURE that
  // codesign will add)
  long headerAndLoadCommands =
      sizeof(struct mach_header_64) + self.loadCommandSize;
  long codeSignatureReserve = sizeof(struct linkedit_data_command);
  long sectionDataStart =
      (headerAndLoadCommands + codeSignatureReserve + 7) & ~7;

  // Compute __TEXT section offsets and addresses
  long textSectionOffset = 0;
  for (MPWMachOSectionWriter *writer in [self textSectionWriters]) {
    writer.offset = sectionDataStart + textSectionOffset;
    writer.address =
        sectionDataStart + textSectionOffset; // vmaddr = file offset for __TEXT
    textSectionOffset += writer.sectionDataSize;
  }
  long textDataSize = textSectionOffset;

  // Compute __DATA_CONST data size
  long dataConstDataSize = 0;
  for (MPWMachOSectionWriter *writer in [self dataConstSectionWriters]) {
    dataConstDataSize += writer.sectionDataSize;
  }

  // Compute __DATA data size
  long dataDataSize = 0;
  for (MPWMachOSectionWriter *writer in [self dataSectionWriters]) {
    dataDataSize += writer.sectionDataSize;
  }

  // __TEXT segment vmsize is page-aligned (16KB minimum)
  long textSegmentFileEnd = sectionDataStart + textDataSize;
  self.textSegmentSize = (textSegmentFileEnd + 0x3FFF) & ~0x3FFF;
  if (self.textSegmentSize == 0) {
    self.textSegmentSize = 0x4000; // Minimum 16KB
  }

  // Compute segment offsets and VM addresses: __TEXT -> __DATA_CONST -> __DATA
  // -> __LINKEDIT
  long currentOffset = self.textSegmentSize;
  long currentVmaddr = self.textSegmentSize;

  if (hasDataConst) {
    self.dataConstSegmentOffset = currentOffset;
    // vmsize should be page-aligned for segments
    self.dataConstSegmentSize = (dataConstDataSize + 0x3FFF) & ~0x3FFF;
    if (self.dataConstSegmentSize == 0)
      self.dataConstSegmentSize = 0x4000;

    [self.chainedFixupWriter setSegmentFileOffset:self.dataConstSegmentOffset
                                       forSegment:1];

    // Compute section offsets and addresses for __DATA_CONST sections
    long sectionOffset = 0;
    for (MPWMachOSectionWriter *writer in [self dataConstSectionWriters]) {
      writer.offset = self.dataConstSegmentOffset + sectionOffset;
      writer.address = currentVmaddr + sectionOffset;
      sectionOffset += writer.sectionDataSize;
    }

    currentOffset = (currentOffset + dataConstDataSize + 0x3FFF) & ~0x3FFF;
    currentVmaddr += self.dataConstSegmentSize;
  } else {
    self.dataConstSegmentOffset = 0;
    self.dataConstSegmentSize = 0;
  }

  if (hasData) {
    self.dataSegmentOffset = currentOffset;
    self.dataSegmentSize = (dataDataSize + 0x3FFF) & ~0x3FFF;
    if (self.dataSegmentSize == 0)
      self.dataSegmentSize = 0x4000;

    // Set segment file offset for chained fixups
    // Segment index is 2 if we have __DATA_CONST, otherwise 1
    int dataSegmentIndex = hasDataConst ? 2 : 1;
    [self.chainedFixupWriter setSegmentFileOffset:self.dataSegmentOffset
                                       forSegment:dataSegmentIndex];

    // Compute section offsets and addresses for __DATA sections
    long sectionOffset = 0;
    for (MPWMachOSectionWriter *writer in [self dataSectionWriters]) {
      writer.offset = self.dataSegmentOffset + sectionOffset;
      writer.address = currentVmaddr + sectionOffset;
      sectionOffset += writer.sectionDataSize;
    }

    currentOffset = (currentOffset + dataDataSize + 0x3FFF) & ~0x3FFF;
    currentVmaddr += self.dataSegmentSize;
  } else {
    self.dataSegmentOffset = 0;
    self.dataSegmentSize = 0;
  }

  self.linkeditOffset = currentOffset;
  self.linkeditSize =
      (uint32_t)currentVmaddr; // Temporary storage for total VM size if needed

  [self.chainedFixupWriter setSegmentFileOffset:0 forSegment:0]; // __TEXT

  // 4. Build chained fixups data if needed
  if (hasChained) {
    [self buildChainedFixups];
  }

  // __LINKEDIT size includes: rebase (aligned), bind (aligned), exports,
  // chained fixups (aligned), symtab, strtab
  long rawLinkeditSize = [self alignedRebaseDataSize] +
                         [self alignedBindDataSize] + [self exportTrieSize] +
                         (hasChained ? [self alignedChainedFixupsSize] : 0) +
                         [self symbolTableSize] +
                         [self.stringTableWriter length];
  // Pad linkedit size to 8-byte alignment (required for mmap)
  self.linkeditSize = (rawLinkeditSize + 7) & ~7;
  self.linkeditSize = (uint32_t)self.linkeditSize;

  // 5. Patch stubs and apply relocations
  [self patchStubs];
  [self patchObjcStubs];
  [self patchObjcSelrefs];
  [self applyRelocations];

  // Write everything
  [self writeHeader];
  [self writeTextSegmentLoadCommand];
  if (hasDataConst) {
    [self writeDataConstSegmentLoadCommand];
  }
  if (hasData) {
    [self writeDataSegmentLoadCommand];
  }
  [self writeLinkeditSegmentLoadCommand];
  [self writeIdDylibLoadCommand];
  for (NSString *path in self.frameworks) {
    [self writeLoadDylibCommand:path];
  }
  // Write either LC_DYLD_INFO_ONLY (if we have bind data) or
  // LC_DYLD_EXPORTS_TRIE
  if (hasBind) {
    [self writeDyldInfoLoadCommand];
  } else {
    [self writeExportsTrieLoadCommand];
  }
  [self writeSymbolTableLoadCommand];
  [self writeDysymtabLoadCommand];
  [self writeUUIDLoadCommand];
  if ([self hasChainedFixups]) {
    [self writeChainedFixupsLoadCommand];
  }
  [self writePlatformLoadCommand];

  // Write __TEXT section data
  [self writeSections];

  // If we have __DATA_CONST, pad to its offset and write __DATA_CONST sections
  if (hasDataConst) {
    long currentPos = self.length;
    if (currentPos < self.dataConstSegmentOffset) {
      long padding = self.dataConstSegmentOffset - currentPos;
      char *zeros = calloc(padding, 1);
      [self appendBytes:zeros length:padding];
      free(zeros);
    }
    // Write __DATA_CONST section data
    for (MPWMachOSectionWriter *sectionWriter in
         [self dataConstSectionWriters]) {
      if ([sectionWriter.sectname isEqualToString:@"__objc_arrayobj"]) {
        NSData *d = [sectionWriter data];
        if (d.length >= 8) {
          uint64_t v;
          [d getBytes:&v length:8];
          NSLog(@"Writing __objc_arrayobj: first 8 bytes = 0x%llx", v);
        }
      }
      [sectionWriter writeSectionDataOn:self];
    }
  }

  // If we have __DATA, pad to its offset and write __DATA sections
  if (hasData) {
    long currentPos = self.length;
    if (currentPos < self.dataSegmentOffset) {
      long padding = self.dataSegmentOffset - currentPos;
      char *zeros = calloc(padding, 1);
      [self appendBytes:zeros length:padding];
      free(zeros);
    }
    // Write __DATA section data
    for (MPWMachOSectionWriter *sectionWriter in [self dataSectionWriters]) {
      [sectionWriter writeSectionDataOn:self];
    }
  }

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


@implementation MPWMachODylibWriter (testing)

+(NSArray*)testSelectors {
    return  @[];
}

@end
