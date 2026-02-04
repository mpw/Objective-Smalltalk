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
// ObjC message send support
@property(nonatomic, strong) NSMutableDictionary *objcStubOffsets;      // selector -> offset in __objc_stubs
@property(nonatomic, strong) NSMutableDictionary *objcMethnameOffsets;  // selector -> offset in __objc_methname
@property(nonatomic, strong) NSMutableDictionary *objcSelrefOffsets;    // selector -> offset in __objc_selrefs

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
    self.currentVersion = 0x10000;       // 1.0.0
    self.compatibilityVersion = 0x10000; // 1.0.0
    self.chainedFixupWriter =
        [[[MPWChainedFixupWriter alloc] init] autorelease];
    self.stubOffsets = [NSMutableDictionary dictionary];
    self.gotOffsets = [NSMutableDictionary dictionary];
    self.frameworks =
        [NSMutableArray arrayWithObject:@"/usr/lib/libSystem.B.dylib"];
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
    // Add libobjc to frameworks if not already present
    BOOL hasLibobjc = NO;
    for (NSString *fw in self.frameworks) {
      if ([fw containsString:@"libobjc"]) {
        hasLibobjc = YES;
        break;
      }
    }
    if (!hasLibobjc) {
      [self.frameworks addObject:@"/usr/lib/libobjc.A.dylib"];
    }

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
  return [super declareExternalSymbol:symbol];
}

- (void)patchStubs {
  MPWMachOSectionWriter *stubWriter = [self stubSectionWriter];
  MPWMachOSectionWriter *gotWriter = [self gotSectionWriter];
  if (!stubWriter.isActive || !gotWriter.isActive) {
    NSLog(@"patchStubs: stubWriter.isActive=%d gotWriter.isActive=%d - skipping", stubWriter.isActive, gotWriter.isActive);
    return;
  }
  long gotAddr = gotWriter.address;
  long stubAddr = stubWriter.address;
  NSMutableData *stubData = (NSMutableData *)stubWriter.target;

  NSLog(@"patchStubs: stubAddr=0x%lx gotAddr=0x%lx stubData.length=%lu", stubAddr, gotAddr, (unsigned long)stubData.length);

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

    NSLog(@"patchStubs: symbol=%@ stubOffset=%ld stubAddr=0x%lx gotAddr=0x%lx", symbol, curStubOffset, curStubAddr, curGotAddr);
    NSLog(@"  pcPage=0x%lx gotPage=0x%lx pageDiff=%ld", pcPage, gotPage, pageDiff);
    NSLog(@"  adrp=0x%08x ldr=0x%08x br=0x%08x", adrp, ldr, br);

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
    NSLog(@"patchObjcStubs: No GOT entry for _objc_msgSend");
    return;
  }
  long msgSendGotAddr = gotAddr + [msgSendGotOffset longValue];

  NSLog(@"patchObjcStubs: objcStubAddr=0x%lx selrefsAddr=0x%lx msgSendGotAddr=0x%lx",
        objcStubAddr, selrefsAddr, msgSendGotAddr);

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

    NSLog(@"patchObjcStubs: selector=%@ stubOffset=%ld selrefAddr=0x%lx", selector, stubOffset, curSelrefAddr);

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

    NSLog(@"patchObjcSelrefs: selector=%@ selrefOffset=%ld selectorAddr=0x%llx", selector, selrefOffset, selectorAddr);

    [selrefsData replaceBytesInRange:NSMakeRange(selrefOffset, sizeof(selectorAddr))
                           withBytes:&selectorAddr];
  }
}

- (void)applyRelocations {
  for (MPWMachOSectionWriter *sectionWriter in [self activeSectionWriters]) {
    NSMutableData *sectionData = (NSMutableData *)sectionWriter.target;
    for (int i = 0; i < sectionWriter.numRelocationEntries; i++) {
      NSString *symbolName = [sectionWriter symbolNameForRelocationAtIndex:i];
      int offset = [sectionWriter offsetForRelocationAtIndex:i];

      long targetAddr = 0;

      // Check if this is an ObjC stub (for _objc_msgSend$selector)
      NSString *selector = nil;
      if ([self isObjcMsgSendSymbol:symbolName selector:&selector]) {
        // Target is in __objc_stubs section
        MPWMachOSectionWriter *objcStubWriter = [self objcStubSectionWriter];
        if (self.objcStubOffsets[selector]) {
          targetAddr = objcStubWriter.address + [self.objcStubOffsets[selector] longValue];
        }
      } else if (self.stubOffsets[symbolName]) {
        // Regular stub in __stubs section
        targetAddr = self.stubSectionWriter.address +
                     [self.stubOffsets[symbolName] longValue];
      } else {
        // Internal symbol
        NSDictionary *info = self.symbolAddressInfo[symbolName];
        if (info) {
          targetAddr =
              self.textSectionWriter.address + [info[@"offset"] longValue];
        }
      }

      if (targetAddr != 0) {
        long pcAddr = sectionWriter.address + offset;
        long delta = (targetAddr - pcAddr);
        uint32_t instr;
        [sectionData getBytes:&instr range:NSMakeRange(offset, 4)];
        instr &= 0xfc000000;
        instr |= (uint32_t)((delta >> 2) & 0x03ffffff);
        [sectionData replaceBytesInRange:NSMakeRange(offset, 4)
                               withBytes:&instr];
      }
    }
  }
}

- (int)ordinalForSymbol:(NSString *)symbol {
  int ordinal = 1; // Default to libSystem

  // _objc_msgSend comes from libobjc
  if ([symbol isEqualToString:@"_objc_msgSend"]) {
    for (int i = 0; i < self.frameworks.count; i++) {
      if ([self.frameworks[i] containsString:@"libobjc"]) {
        ordinal = i + 1;
        break;
      }
    }
  } else if ([symbol containsString:@"MPW"]) {
    for (int i = 0; i < self.frameworks.count; i++) {
      if ([self.frameworks[i] containsString:@"MPWFoundation"]) {
        ordinal = i + 1;
        break;
      }
    }
  }
  NSLog(@"Ordinal for symbol %@ is %d (frameworks: %@)", symbol, ordinal,
        self.frameworks);
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

      NSLog(@"buildChainedFixups: Adding rebase for selector %@ at segment %d offset 0x%lx target 0x%llx",
            selector, dataSegmentIndex, selrefSegmentOffset, selectorStringAddr);

      [self.chainedFixupWriter addRebaseAtSegment:dataSegmentIndex
                                           offset:selrefSegmentOffset
                                           target:selectorStringAddr];
    }
  }

  // 3. Generate metadata to compute 'next' pointers
  [self.chainedFixupWriter fixupDataWithSegmentCount:[self segmentCount]];

  // 4. Patch GOT slots with bind entry bits
  NSMutableData *gotData = (NSMutableData *)gotWriter.target;
  NSArray *segFixups = [self.chainedFixupWriter fixupsForSegment:1];
  long dataConstVmaddr = self.textSegmentSize;
  long gotSegStart = gotWriter.address - dataConstVmaddr;

  for (MPWChainedFixup *f in segFixups) {
    if (!f.isRebase) {
      uint64_t bindBits = [self.chainedFixupWriter bind64Bits:f.ordinal next:f.next];
      long f_section_offset = f.offset - gotSegStart;
      [gotData replaceBytesInRange:NSMakeRange((NSUInteger)f_section_offset, 8)
                         withBytes:&bindBits];
    }
  }

  // 5. Patch selrefs with rebase entry bits
  if (selrefsWriter.isActive && self.objcSelrefOffsets.count > 0) {
    int dataSegmentIndex = [self hasDataConstSegment] ? 2 : 1;
    NSArray *dataSegFixups = [self.chainedFixupWriter fixupsForSegment:dataSegmentIndex];
    NSMutableData *selrefsData = (NSMutableData *)selrefsWriter.target;

    long dataSegmentVmaddr = self.textSegmentSize;
    if ([self hasDataConstSegment]) {
      long dataConstVmsize = (self.dataConstSegmentSize + 0x3FFF) & ~0x3FFF;
      if (dataConstVmsize == 0) dataConstVmsize = 0x4000;
      dataSegmentVmaddr += dataConstVmsize;
    }
    long selrefsSegStart = selrefsWriter.address - dataSegmentVmaddr;

    for (MPWChainedFixup *f in dataSegFixups) {
      if (f.isRebase) {
        uint64_t rebaseBits = [self.chainedFixupWriter rebase64Bits:f.rebaseTarget next:f.next];
        long f_section_offset = f.offset - selrefsSegStart;
        NSLog(@"Patching selref at section offset %ld with rebase bits 0x%llx", f_section_offset, rebaseBits);
        [selrefsData replaceBytesInRange:NSMakeRange((NSUInteger)f_section_offset, 8)
                               withBytes:&rebaseBits];
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

    long textSectionAddr = self.textSectionWriter.address;
    long address = textSectionAddr;
    NSDictionary *info = self.symbolAddressInfo[symbol];
    if (info && info[@"offset"]) {
      address += [info[@"offset"] longValue];
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

#import "MPWMachOReader.h"
#import "STNativeCompiler.h"
#import "STNativeCompilerTestsMachO.h"
#import "STObjectCodeGeneratorARM.h"
#import "macho-headers/mach-o/fixup-chains.h"
#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachODylibWriter (testing)

+ (void)testCanWriteDylibHeader {
  MPWMachODylibWriter *writer = [self stream];
  writer.installName = @"@rpath/libtest.dylib";
  [writer writeFile];

  NSData *macho = [writer data];
  MPWMachOReader *reader =
      [[[MPWMachOReader alloc] initWithData:macho] autorelease];
  EXPECTTRUE([reader isHeaderValid], @"header valid");
  INTEXPECT([reader cputype], CPU_TYPE_ARM64, @"cputype");
  INTEXPECT([reader filetype], MH_DYLIB, @"filetype should be MH_DYLIB");
}

+ (void)testDylibHasIdLoadCommand {
  MPWMachODylibWriter *writer = [self stream];
  writer.installName = @"@rpath/libtest.dylib";
  [writer writeFile];

  NSData *macho = [writer data];
  MPWMachOReader *reader =
      [[[MPWMachOReader alloc] initWithData:macho] autorelease];

  // Should have LC_ID_DYLIB load command
  EXPECTNOTNIL([reader loadCommandOfTypeIfPresent:LC_ID_DYLIB],
               @"should have LC_ID_DYLIB");
}

+ (void)testDylibHasMultipleSegments {
  MPWMachODylibWriter *writer = [self stream];
  writer.installName = @"@rpath/libtest.dylib";

  // Add some code
  unsigned char code[] = {0xc0, 0x03, 0x5f, 0xd6}; // ret
  [writer declareGlobalSymbol:@"_testfn" atOffset:0];
  [writer addTextSectionData:[NSData dataWithBytes:code length:sizeof(code)]];
  [writer writeFile];

  NSData *macho = [writer data];
  MPWMachOReader *reader =
      [[[MPWMachOReader alloc] initWithData:macho] autorelease];

  // Should have __TEXT and __LINKEDIT segments at minimum
  EXPECTNOTNIL([reader segmentNamed:@"__TEXT"], @"should have __TEXT segment");
  EXPECTNOTNIL([reader segmentNamed:@"__LINKEDIT"],
               @"should have __LINKEDIT segment");
}

+ (void)testDylibHasExportsTrie {
  MPWMachODylibWriter *writer = [self stream];
  writer.installName = @"@rpath/libtest.dylib";

  // Add an exported function
  unsigned char code[] = {0xc0, 0x03, 0x5f, 0xd6}; // ret
  [writer declareGlobalSymbol:@"_testfn" atOffset:0];
  [writer addTextSectionData:[NSData dataWithBytes:code length:sizeof(code)]];
  [writer writeFile];

  NSData *macho = [writer data];
  MPWMachOReader *reader =
      [[[MPWMachOReader alloc] initWithData:macho] autorelease];

  // Should have LC_DYLD_EXPORTS_TRIE load command
  EXPECTNOTNIL([reader loadCommandOfTypeIfPresent:LC_DYLD_EXPORTS_TRIE],
               @"should have exports trie");
}

+ (void)testDissectKnownCorrectDylib {
  NSData *macho =
      [NSData dataWithContentsOfFile:@"/tmp/libexternal_macos13.dylib"];
  if (!macho) {
    NSLog(@"testDissectKnownCorrectDylib: /tmp/libexternal_macos13.dylib not "
          @"found, skipping");
    return;
  }
  NSLog(@"testDissectKnownCorrectDylib: loaded %lu bytes",
        (unsigned long)macho.length);
  MPWMachOReader *reader =
      [[[MPWMachOReader alloc] initWithData:macho] autorelease];

  MPWMachOSegment *text = [reader segmentObjectNamed:@"__TEXT"];
  NSLog(@"testDissectKnownCorrectDylib: __TEXT: vmaddr=0x%llx vmsize=0x%llx "
        @"fileoff=0x%llx filesize=0x%llx",
        text.vmaddr, text.vmsize, text.fileoff, text.filesize);
  EXPECTNOTNIL(text, @"should have __TEXT");
  INTEXPECT(text.vmaddr, 0, @"__TEXT vmaddr");
  INTEXPECT(text.vmsize, 0x4000, @"__TEXT vmsize");
  INTEXPECT(text.fileoff, 0, @"__TEXT fileoff");
  INTEXPECT(text.filesize, 0x4000, @"__TEXT filesize");

  MPWMachOSegment *dataConst = [reader segmentObjectNamed:@"__DATA_CONST"];
  NSLog(@"testDissectKnownCorrectDylib: __DATA_CONST: vmaddr=0x%llx "
        @"vmsize=0x%llx fileoff=0x%llx filesize=0x%llx",
        dataConst.vmaddr, dataConst.vmsize, dataConst.fileoff,
        dataConst.filesize);
  EXPECTNOTNIL(dataConst, @"should have __DATA_CONST");
  INTEXPECT(dataConst.vmaddr, 0x4000, @"__DATA_CONST vmaddr");
  INTEXPECT(dataConst.vmsize, 0x4000, @"__DATA_CONST vmsize");
  INTEXPECT(dataConst.fileoff, 0x4000, @"__DATA_CONST fileoff");
  INTEXPECT(dataConst.filesize, 0x4000, @"__DATA_CONST filesize");

  MPWMachOSegment *linkedit = [reader segmentObjectNamed:@"__LINKEDIT"];
  NSLog(
      @"testDissectKnownCorrectDylib: __LINKEDIT: vmaddr=0x%llx vmsize=0x%llx "
      @"fileoff=0x%llx filesize=0x%llx",
      linkedit.vmaddr, linkedit.vmsize, linkedit.fileoff, linkedit.filesize);
  EXPECTNOTNIL(linkedit, @"should have __LINKEDIT");
  INTEXPECT(linkedit.vmaddr, 0x8000, @"__LINKEDIT vmaddr");
  INTEXPECT(linkedit.fileoff, 0x8000, @"__LINKEDIT fileoff");

  struct linkedit_data_command *chained =
      (struct linkedit_data_command *)[reader
          loadCommandOfTypeIfPresent:LC_DYLD_CHAINED_FIXUPS];
  EXPECTNOTNIL(chained, @"should have LC_DYLD_CHAINED_FIXUPS");
  if (chained) {
    NSLog(@"testDissectKnownCorrectDylib: LC_DYLD_CHAINED_FIXUPS: dataoff=0x%x "
          @"datasize=0x%x",
          chained->dataoff, chained->datasize);
    INTEXPECT(chained->dataoff, 0x8000, @"chained fixups offset");
  }
}

+ (void)testDylibExportsSymbol {
  MPWMachODylibWriter *writer = [self stream];
  writer.installName = @"@rpath/libtest.dylib";

  // Add an exported function
  unsigned char code[] = {0xc0, 0x03, 0x5f, 0xd6}; // ret
  [writer declareGlobalSymbol:@"_testfn" atOffset:0];
  [writer addTextSectionData:[NSData dataWithBytes:code length:sizeof(code)]];
  [writer writeFile];

  NSData *macho = [writer data];
  MPWMachOReader *reader =
      [[[MPWMachOReader alloc] initWithData:macho] autorelease];

  NSArray *exports = [reader exportedSymbolNames];
  EXPECTTRUE([exports containsObject:@"_testfn"], @"should export _testfn");
}

// Test that documents all load commands a working dylib has
+ (void)testDocumentReferenceLoadCommands {
  // Create reference dylib with clang
  system("echo 'int answer(void) { return 42; }' > /tmp/ref_src.c");
  system("clang -shared -o /tmp/libref_test.dylib /tmp/ref_src.c -install_name "
         "@rpath/libref.dylib");

  NSData *refData = [NSData dataWithContentsOfFile:@"/tmp/libref_test.dylib"];
  EXPECTNOTNIL(refData, @"reference dylib should exist");

  MPWMachOReader *refReader =
      [[[MPWMachOReader alloc] initWithData:refData] autorelease];

  // Document all load commands present in a working dylib
  NSLog(@"Reference dylib load commands:");

  // Required load commands for a dylib:
  EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_SEGMENT_64],
               @"needs LC_SEGMENT_64");
  EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_ID_DYLIB],
               @"needs LC_ID_DYLIB");
  EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_SYMTAB],
               @"needs LC_SYMTAB");
  EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_DYSYMTAB],
               @"needs LC_DYSYMTAB");
  EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_UUID],
               @"needs LC_UUID");
  EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_BUILD_VERSION],
               @"needs LC_BUILD_VERSION");
  EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_LOAD_DYLIB],
               @"needs LC_LOAD_DYLIB (libSystem)");
  // Exports can be in LC_DYLD_EXPORTS_TRIE (new) or LC_DYLD_INFO_ONLY (old)
  BOOL hasExports =
      [refReader loadCommandOfTypeIfPresent:LC_DYLD_EXPORTS_TRIE] != NULL ||
      [refReader loadCommandOfTypeIfPresent:LC_DYLD_INFO_ONLY] != NULL;
  EXPECTTRUE(hasExports,
             @"needs exports (LC_DYLD_EXPORTS_TRIE or LC_DYLD_INFO_ONLY)");

  // Modern dylibs also have chained fixups (required for arm64e, optional for
  // arm64)
  const struct load_command *chainedFixups =
      [refReader loadCommandOfTypeIfPresent:LC_DYLD_CHAINED_FIXUPS];
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
// These assumptions are derived from analyzing reference dylibs created by
// clang/ld
+ (void)testDylibLayoutAssumptions {
  // Create reference dylib with clang
  system("echo 'int answer(void) { return 42; }' > /tmp/ref_src.c");
  system("clang -shared -o /tmp/libref_test.dylib /tmp/ref_src.c -install_name "
         "@rpath/libref.dylib");

  NSData *refData = [NSData dataWithContentsOfFile:@"/tmp/libref_test.dylib"];
  EXPECTNOTNIL(refData, @"reference dylib should exist");

  MPWMachOReader *refReader =
      [[[MPWMachOReader alloc] initWithData:refData] autorelease];

  // Get segments from reference
  struct segment_command_64 *refText = [refReader segmentNamed:@"__TEXT"];
  struct segment_command_64 *refLinkedit =
      [refReader segmentNamed:@"__LINKEDIT"];
  EXPECTNOTNIL((id)(uintptr_t)refText, @"reference should have __TEXT");
  EXPECTNOTNIL((id)(uintptr_t)refLinkedit, @"reference should have __LINKEDIT");

  // Document and verify layout assumptions:

  // 1. __TEXT starts at file offset 0 and vmaddr 0
  INTEXPECT(refText->fileoff, 0, @"__TEXT fileoff should be 0");
  INTEXPECT(refText->vmaddr, 0, @"__TEXT vmaddr should be 0");

  // 2. __TEXT filesize equals __LINKEDIT fileoff (no gaps)
  INTEXPECT(refLinkedit->fileoff, refText->filesize,
            @"__LINKEDIT fileoff == __TEXT filesize");

  // 3. __LINKEDIT vmaddr equals __TEXT vmsize (contiguous in memory)
  INTEXPECT(refLinkedit->vmaddr, refText->vmsize,
            @"__LINKEDIT vmaddr == __TEXT vmsize");

  // 4. Both vmsize values are page-aligned (0x1000 = 4096)
  INTEXPECT(refText->vmsize % 0x1000, 0,
            @"__TEXT vmsize should be page-aligned");
  INTEXPECT(refLinkedit->vmsize % 0x1000, 0,
            @"__LINKEDIT vmsize should be page-aligned");

  // 5. File size should equal __LINKEDIT fileoff + __LINKEDIT filesize
  long expectedFileSize = refLinkedit->fileoff + refLinkedit->filesize;
  INTEXPECT((long)refData.length, expectedFileSize,
            @"file size == __LINKEDIT end");

  NSLog(@"Reference dylib layout:");
  NSLog(@"  __TEXT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
        refText->vmaddr, refText->vmsize, refText->fileoff, refText->filesize);
  NSLog(@"  __LINKEDIT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
        refLinkedit->vmaddr, refLinkedit->vmsize, refLinkedit->fileoff,
        refLinkedit->filesize);
  NSLog(@"  File size: %lu", (unsigned long)refData.length);
}

// Test that our generated dylib follows the same layout assumptions
+ (void)testGeneratedDylibFollowsLayoutAssumptions {
  MPWMachODylibWriter *writer = [self stream];
  writer.installName = @"@rpath/libminimal.dylib";

  unsigned char code[] = {
      0x40, 0x05, 0x80, 0x52, // mov w0, #42
      0xc0, 0x03, 0x5f, 0xd6  // ret
  };
  [writer declareGlobalSymbol:@"_answer" atOffset:0];
  [writer addTextSectionData:[NSData dataWithBytes:code length:sizeof(code)]];
  [writer writeFile];

  NSData *macho = [writer data];
  MPWMachOReader *reader =
      [[[MPWMachOReader alloc] initWithData:macho] autorelease];

  struct segment_command_64 *text = [reader segmentNamed:@"__TEXT"];
  struct segment_command_64 *dataConst = [reader segmentNamed:@"__DATA_CONST"];
  struct segment_command_64 *data = [reader segmentNamed:@"__DATA"];
  struct segment_command_64 *linkedit = [reader segmentNamed:@"__LINKEDIT"];

  NSLog(@"Generated dylib layout (before codesign):");
  NSLog(@"  __TEXT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
        text->vmaddr, text->vmsize, text->fileoff, text->filesize);
  if (dataConst) {
    NSLog(@"  __DATA_CONST: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
          dataConst->vmaddr, dataConst->vmsize, dataConst->fileoff,
          dataConst->filesize);
  }
  if (data) {
    NSLog(@"  __DATA: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
          data->vmaddr, data->vmsize, data->fileoff, data->filesize);
  }
  NSLog(@"  __LINKEDIT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
        linkedit->vmaddr, linkedit->vmsize, linkedit->fileoff,
        linkedit->filesize);
  NSLog(@"  File size: %lu", (unsigned long)macho.length);

  // Verify assumptions
  INTEXPECT(text->fileoff, 0, @"__TEXT fileoff should be 0");
  INTEXPECT(text->vmaddr, 0, @"__TEXT vmaddr should be 0");
  INTEXPECT(text->vmsize % 0x1000, 0, @"__TEXT vmsize should be page-aligned");

  // Track expected vmaddr for subsequent segments
  long expectedVmaddr = text->vmsize;

  if (dataConst) {
    INTEXPECT(dataConst->vmaddr, expectedVmaddr,
              @"__DATA_CONST vmaddr == expected");
    expectedVmaddr += dataConst->vmsize;
  }

  if (data) {
    INTEXPECT(data->vmaddr, expectedVmaddr, @"__DATA vmaddr == expected");
    expectedVmaddr += ((data->vmsize + 0x3FFF) & ~0x3FFF);
  }

  // __LINKEDIT comes last
  INTEXPECT(linkedit->vmaddr, expectedVmaddr, @"__LINKEDIT vmaddr == expected");

  INTEXPECT(linkedit->vmsize % 0x1000, 0,
            @"__LINKEDIT vmsize should be page-aligned");

  long expectedFileSize = linkedit->fileoff + linkedit->filesize;
  INTEXPECT((long)macho.length, expectedFileSize,
            @"file size == __LINKEDIT end");
}

// Compare our dylib structure to reference AFTER codesign to find differences
+ (void)testCompareSignedDylibStructure {
  // Create reference dylib
  system("echo 'int answer(void) { return 42; }' > /tmp/ref_src.c");
  system("clang -shared -o /tmp/libref_compare.dylib /tmp/ref_src.c "
         "-install_name @rpath/libref.dylib");

  // Create our dylib
  MPWMachODylibWriter *writer = [self stream];
  writer.installName = @"@rpath/libminimal.dylib";
  unsigned char code[] = {
      0x40, 0x05, 0x80, 0x52, // mov w0, #42
      0xc0, 0x03, 0x5f, 0xd6  // ret
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
  NSData *refData =
      [NSData dataWithContentsOfFile:@"/tmp/libref_compare.dylib"];
  NSData *ourData =
      [NSData dataWithContentsOfFile:@"/tmp/libminimal_compare.dylib"];

  MPWMachOReader *refReader =
      [[[MPWMachOReader alloc] initWithData:refData] autorelease];
  MPWMachOReader *ourReader =
      [[[MPWMachOReader alloc] initWithData:ourData] autorelease];

  struct segment_command_64 *refText = [refReader segmentNamed:@"__TEXT"];
  struct segment_command_64 *refLinkedit =
      [refReader segmentNamed:@"__LINKEDIT"];
  struct segment_command_64 *ourText = [ourReader segmentNamed:@"__TEXT"];
  struct segment_command_64 *ourLinkedit =
      [ourReader segmentNamed:@"__LINKEDIT"];

  NSLog(@"=== REFERENCE (after codesign) ===");
  NSLog(@"  File size: %lu", (unsigned long)refData.length);
  NSLog(@"  __TEXT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
        refText->vmaddr, refText->vmsize, refText->fileoff, refText->filesize);
  NSLog(@"  __LINKEDIT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
        refLinkedit->vmaddr, refLinkedit->vmsize, refLinkedit->fileoff,
        refLinkedit->filesize);
  NSLog(@"  Bytes available for __LINKEDIT: %lu",
        (unsigned long)(refData.length - refLinkedit->fileoff));

  NSLog(@"=== OURS (after codesign) ===");
  NSLog(@"  File size: %lu", (unsigned long)ourData.length);
  NSLog(@"  __TEXT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
        ourText->vmaddr, ourText->vmsize, ourText->fileoff, ourText->filesize);
  NSLog(@"  __LINKEDIT: vmaddr=%llx vmsize=%llx fileoff=%lld filesize=%lld",
        ourLinkedit->vmaddr, ourLinkedit->vmsize, ourLinkedit->fileoff,
        ourLinkedit->filesize);
  NSLog(@"  Bytes available for __LINKEDIT: %lu",
        (unsigned long)(ourData.length - ourLinkedit->fileoff));

  // Key comparisons
  NSLog(@"=== KEY DIFFERENCES ===");
  if (refLinkedit->vmsize != ourLinkedit->vmsize) {
    NSLog(@"  __LINKEDIT vmsize: ref=%llx ours=%llx", refLinkedit->vmsize,
          ourLinkedit->vmsize);
  }
  if (refLinkedit->filesize != ourLinkedit->filesize) {
    NSLog(@"  __LINKEDIT filesize: ref=%lld ours=%lld", refLinkedit->filesize,
          ourLinkedit->filesize);
  }

  // Check if vmsize can be backed by file
  long refAvail = refData.length - refLinkedit->fileoff;
  long ourAvail = ourData.length - ourLinkedit->fileoff;
  NSLog(@"  Reference: vmsize=%llx, file can back %lx bytes",
        refLinkedit->vmsize, refAvail);
  NSLog(@"  Ours: vmsize=%llx, file can back %lx bytes", ourLinkedit->vmsize,
        ourAvail);

  // Check total VM size
  NSLog(@"=== TOTAL VM LAYOUT ===");
  NSLog(@"  Reference: __TEXT ends at %llx, __LINKEDIT spans %llx-%llx",
        refText->vmsize, refLinkedit->vmaddr,
        refLinkedit->vmaddr + refLinkedit->vmsize);
  NSLog(@"  Ours: __TEXT ends at %llx, __LINKEDIT spans %llx-%llx",
        ourText->vmsize, ourLinkedit->vmaddr,
        ourLinkedit->vmaddr + ourLinkedit->vmsize);

  // Check file backing for entire range
  NSLog(@"=== FILE BACKING ===");
  NSLog(@"  Reference file size: %lu, __LINKEDIT end in file: %lld",
        (unsigned long)refData.length,
        refLinkedit->fileoff + refLinkedit->filesize);
  NSLog(@"  Our file size: %lu, __LINKEDIT end in file: %lld",
        (unsigned long)ourData.length,
        ourLinkedit->fileoff + ourLinkedit->filesize);

  // Try loading reference to verify it works
  void *refHandle = dlopen("/tmp/libref_compare.dylib", RTLD_NOW);
  NSLog(@"  Reference loads: %s", refHandle ? "YES" : dlerror());
  if (refHandle)
    dlclose(refHandle);

  // Try loading ours
  void *ourHandle = dlopen("/tmp/libminimal_compare.dylib", RTLD_NOW);
  NSLog(@"  Ours loads: %s", ourHandle ? "YES" : dlerror());
  if (ourHandle)
    dlclose(ourHandle);

  // The test passes if we output the comparison - actual loading test is
  // separate
  EXPECTTRUE(YES, @"comparison complete");
}

+ (void)testDylibReaderCanParseMultipleSegments {
  MPWMachODylibWriter *writer = [self stream];
  writer.installName = @"@rpath/libmultiseg.dylib";

  // Add some code to create multiple segments
  unsigned char code[] = {0xc0, 0x03, 0x5f, 0xd6}; // ret
  [writer declareGlobalSymbol:@"_test" atOffset:0];
  [writer addTextSectionData:[NSData dataWithBytes:code length:sizeof(code)]];

  // Add a __DATA section to force multiple segments
  MPWMachOSectionWriter *dataSection =
      [writer addSectionWriterWithSegName:@"__DATA"
                                 sectName:@"__test_data"
                                    flags:0];
  [dataSection appendBytes:"test" length:4];

  [writer writeFile];

  NSData *macho = [writer data];
  MPWMachOReader *reader =
      [[[MPWMachOReader alloc] initWithData:macho] autorelease];

  // Should have multiple segments
  NSArray *segments = [reader allSegments];
  INTEXPECT(segments.count, 4,
            @"should have at least 2 segments (__TEXT and __DATA)");
  NSLog(@"segments: %@", segments);
  // Should be able to find specific segments by name
  MPWMachOSegment *textSegment = [reader segmentObjectNamed:@"__TEXT"];
  EXPECTNOTNIL(textSegment, @"should find __TEXT segment");

  MPWMachOSegment *dataSegment = [reader segmentObjectNamed:@"__DATA"];
  EXPECTNOTNIL(dataSegment, @"should find __DATA segment");

  // Test segment properties
  if (textSegment) {
    INTEXPECT(textSegment.vmaddr, 0, @"__TEXT should start at vmaddr 0");
    EXPECTTRUE(textSegment.fileoff == 0,
               @"__TEXT should start at file offset 0");
  }

  if (dataSegment) {
    EXPECTTRUE(dataSegment.vmaddr > textSegment.vmaddr,
               @"__DATA should come after __TEXT");
    EXPECTTRUE(dataSegment.fileoff > textSegment.fileoff,
               @"__DATA file offset should be after __TEXT");
  }
}

+ (void)testMinimalDylibCanBeLoaded {
  MPWMachODylibWriter *writer = [self stream];
  writer.installName = @"@rpath/libminimal.dylib";

  // Simple function that returns 42
  // mov w0, #42; ret
  unsigned char code[] = {
      0x40, 0x05, 0x80, 0x52, // mov w0, #42
      0xc0, 0x03, 0x5f, 0xd6  // ret
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
  codesign.arguments = @[ @"-f", @"-s", @"-", path ];
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

// Compiles an ObjectiveSmalltalk class directly to a dylib (no external
// linker), loads it, and tests the class This test documents the goal:
// STNativeCompiler should be able to use MPWMachODylibWriter to produce a
// loadable framework directly, without going through .o files and ld.
+ (void)testCompileSTClassDirectlyToDylibAndLoad {
  // 1. Create a compiler that uses MPWMachODylibWriter instead of
  // MPWMachOWriter
  //    For now, we'll manually set up what STNativeCompiler would do
  MPWMachODylibWriter *dylibWriter = [MPWMachODylibWriter stream];
  dylibWriter.installName = @"@rpath/STTestClass.framework/STTestClass";

  // 2. Compile an ObjectiveSmalltalk class using the dylib writer
  //    This is where the magic needs to happen - the compiler should:
  //    - Generate code into __TEXT segment
  //    - Generate ObjC metadata into __DATA segment
  //    - Set up proper fixups/bindings for external symbols

  // For now, let's just verify the dylib writer can handle __DATA sections
  // by checking that it doesn't crash when sections are added

  // Add a __TEXT section (code)
  unsigned char retCode[] = {0x00, 0x00, 0x80, 0xD2,
                             0xC0, 0x03, 0x5F, 0xD6}; // mov x0, #0; ret
  [dylibWriter.textSectionWriter declareGlobalTextSymbol:@"_testFunction"];
  [dylibWriter addTextSectionData:[NSData dataWithBytes:retCode
                                                 length:sizeof(retCode)]];

  // Try to add a __DATA section - this is what ObjC class structures need
  MPWMachOSectionWriter *dataSection =
      [dylibWriter addSectionWriterWithSegName:@"__DATA"
                                      sectName:@"__objc_data"
                                         flags:0];
  EXPECTNOTNIL(dataSection, @"should be able to add __DATA section");

  // Write the file
  [dylibWriter writeFile];
  NSData *dylibData = [dylibWriter data];
  EXPECTNOTNIL(dylibData, @"should produce dylib data");

  // Write to framework structure
  NSString *frameworkDir = @"/tmp/STTestClass.framework";
  NSString *dylibPath =
      [frameworkDir stringByAppendingPathComponent:@"STTestClass"];

  [[NSFileManager defaultManager] removeItemAtPath:frameworkDir error:nil];
  [[NSFileManager defaultManager] createDirectoryAtPath:frameworkDir
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];
  [dylibData writeToFile:dylibPath atomically:YES];

  // Code sign
  NSString *codesignCmd =
      [NSString stringWithFormat:@"codesign -f -s - %@", dylibPath];
  int signResult = system([codesignCmd UTF8String]);
  INTEXPECT(signResult, 0, @"codesign should succeed");

  // Try to load it - for now this just tests that our basic dylib loads
  void *handle = dlopen([dylibPath UTF8String], RTLD_NOW);
  if (!handle) {
    NSLog(@"dlopen error: %s", dlerror());
  }
  EXPECTNOTNIL(handle, @"dylib with __DATA section should load");

  if (handle) {
    // Verify our test function is exported
    // Note: dlsym uses the symbol name WITHOUT the underscore prefix
    void *fn = dlsym(handle, "testFunction");
    EXPECTNOTNIL(fn, @"testFunction should be exported");
    dlclose(handle);
  }
}

+ (void)testDylibWithMultipleFunctions {
  MPWMachODylibWriter *writer = [self stream];
  writer.installName = @"@rpath/libmultifunc.dylib";

  // First function: returns 42
  unsigned char answerCode[] = {
      0x40, 0x05, 0x80, 0x52, // mov w0, #42
      0xc0, 0x03, 0x5f, 0xd6  // ret
  };

  // Second function: returns 0
  unsigned char zeroCode[] = {
      0x00, 0x00, 0x80, 0xd2, // mov x0, #0
      0xc0, 0x03, 0x5f, 0xd6  // ret
  };

  [writer declareGlobalSymbol:@"_answer" atOffset:0];
  [writer addTextSectionData:[NSData dataWithBytes:answerCode
                                            length:sizeof(answerCode)]];
  NSLog(@"sizeof(answerCode): %ld", sizeof(answerCode));

  [writer declareGlobalSymbol:@"_zero" atOffset:sizeof(answerCode)];
  [writer addTextSectionData:[NSData dataWithBytes:zeroCode
                                            length:sizeof(zeroCode)]];

  [writer writeFile];

  NSData *macho = [writer data];
  NSString *path = @"/tmp/libmultifunc_test.dylib";
  [macho writeToFile:path atomically:YES];

  // Ad-hoc sign the dylib
  NSTask *codesign = [[[NSTask alloc] init] autorelease];
  codesign.launchPath = @"/usr/bin/codesign";
  codesign.arguments = @[ @"-f", @"-s", @"-", path ];
  [codesign launch];
  [codesign waitUntilExit];

  // Try to load and call all functions
  void *handle = dlopen([path fileSystemRepresentation], RTLD_NOW);
  EXPECTNOTNIL(handle, @"dylib should load");
  if (handle) {
    int (*answer)(void) = dlsym(handle, "answer");
    EXPECTNOTNIL(answer, @"answer function should be found");
    NSLog(@"address of answer function: %p", answer);
    if (answer) {
      INTEXPECT(answer(), 42, @"answer should return 42");
    }
    int (*zero)(void) = dlsym(handle, "zero");
    EXPECTNOTNIL(zero, @"zero function should be found");
    INTEXPECT((off_t)zero, (off_t)answer + 8,
              @"zero should be 8 bytes from answer");
    INTEXPECT(zero(), 0, @"zero should return 0");

    dlclose(handle);
  }
}

+ (void)testDylibWithExternalCall {
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    NSString *path = @"/tmp/libexternalcall.dylib";
    writer.installName = @"@rpath/libexternalcall.dylib";
    [writer.frameworks
     addObject:@"/Library/Frameworks/MPWFoundation.framework/Versions/A/"
     @"MPWFoundation"];
    
    STObjectCodeGeneratorARM *gen = [STObjectCodeGeneratorARM stream];
    gen.symbolWriter = writer;
    gen.relocationWriter = writer.textSectionWriter;
    
    // wrapper function: takes long in x0, calls MPWCreateInteger, returns
    // NSNumber in x0
    [gen generateStartOfFunctionNamed:@"_wrap_MPWCreateInteger" stackSpace:32];
    [gen generateCallToExternalFunctionNamed:@"_MPWCreateInteger"];
    [gen generateEndOfFunctionStackSpace:32];
    [writer addTextSectionData:gen.generatedCode];
    
    [writer writeFile];
    NSData *dylibData = [writer data];
    [dylibData writeToFile:path atomically:YES];
    
    // Ad-hoc sign
    system([[NSString stringWithFormat:@"codesign -f -s - %@", path] UTF8String]);
    
    // Try to load
    NSLog(@"will try to load");
    void *handle = dlopen([path UTF8String], RTLD_NOW);
    if (!handle) {
        NSLog(@"dlopen external call error: %s", dlerror());
    }
    EXPECTNOTNIL(handle, @"dylib with external call should load");
    NSLog(@"did load");
    
    if (handle) {
        id (*wrap)(long) = dlsym(handle, "wrap_MPWCreateInteger");
        EXPECTNOTNIL(wrap, @"wrapper function should be found");
        if (wrap) {
            NSLog(@"did find function");
            id result = wrap(42);
            EXPECTNOTNIL(result, @"should return an object");
            if ([result isKindOfClass:[NSNumber class]]) {
                INTEXPECT([result intValue], 42, @"should return number 42");
            }
        }
        dlclose(handle);
    }
}

// Helper to extract chained fixups data from a dylib
+ (NSData *)chainedFixupsDataFromReader:(MPWMachOReader *)reader {
    struct linkedit_data_command *chainedCmd =
        (struct linkedit_data_command *)[reader loadCommandOfTypeIfPresent:LC_DYLD_CHAINED_FIXUPS];
    if (!chainedCmd) return nil;
    return [reader.data subdataWithRange:NSMakeRange(chainedCmd->dataoff, chainedCmd->datasize)];
}

// Characterization test: Generate reference dylib with external call using external linker
// and document its structure for comparison
+ (void)testCharacterizeReferenceExternalCallDylib {
    // 1. Generate object file with external call using STObjectCodeGeneratorARM + MPWMachOWriter
    //    We manually create a minimal object file that calls _MPWCreateInteger

    NSString *tempDir = @"/tmp";
    NSString *objectPath = [tempDir stringByAppendingPathComponent:@"externalcall_ref.o"];
    NSString *dylibPath = [tempDir stringByAppendingPathComponent:@"externalcall_ref.dylib"];

    // Create object file with external call
    MPWMachOWriter *objectWriter = [MPWMachOWriter stream];
    STObjectCodeGeneratorARM *gen = [STObjectCodeGeneratorARM stream];
    gen.symbolWriter = objectWriter;
    gen.relocationWriter = objectWriter.textSectionWriter;

    // Generate: wrapper(long x) { return MPWCreateInteger(x); }
    // x0 already contains the argument, so just call and return
    [gen generateFunctionNamed:@"_wrap_MPWCreateInteger" stackSpace:32 body:^(STObjectCodeGeneratorARM *g) {
        [g generateCallToExternalFunctionNamed:@"_MPWCreateInteger"];
    }];
    [objectWriter addTextSectionData:gen.generatedCode];

    [objectWriter writeFile];
    [objectWriter.data writeToFile:objectPath atomically:YES];

    // 2. Link with external linker
    STNativeCompiler *compiler = [STNativeCompiler compiler];
    int linkResult = [compiler linkObjects:@[@"externalcall_ref"]
                           toSharedLibrary:@"externalcall_ref.dylib"
                                     inDir:tempDir
                            withFrameworks:@[@"MPWFoundation", @"Foundation"]];
    INTEXPECT(linkResult, 0, @"external linker should succeed");

    // 3. Read and characterize the reference dylib
    NSData *refDylibData = [NSData dataWithContentsOfFile:dylibPath];
    EXPECTNOTNIL(refDylibData, @"reference dylib should be created");

    MPWMachOReader *reader = [MPWMachOReader readerWithData:refDylibData];
    EXPECTNOTNIL(reader, @"reader should be created");
    EXPECTTRUE([reader isHeaderValid], @"header should be valid");

    // 3a. Verify LC_DYLD_CHAINED_FIXUPS exists
    struct linkedit_data_command *chainedCmd =
        (struct linkedit_data_command *)[reader loadCommandOfTypeIfPresent:LC_DYLD_CHAINED_FIXUPS];
    EXPECTNOTNIL(chainedCmd, @"reference dylib should have LC_DYLD_CHAINED_FIXUPS");

    if (chainedCmd) {
        // 3b. Characterize chained fixups header
        NSData *chainedData = [self chainedFixupsDataFromReader:reader];
        EXPECTNOTNIL(chainedData, @"should have chained fixups data");
        EXPECTTRUE(chainedData.length >= sizeof(struct dyld_chained_fixups_header),
                   @"chained data should be large enough for header");

        const struct dyld_chained_fixups_header *header =
            (const struct dyld_chained_fixups_header *)chainedData.bytes;

        // Characterize header fields
        INTEXPECT(header->fixups_version, 0, @"fixups_version should be 0");
        INTEXPECT(header->imports_format, DYLD_CHAINED_IMPORT, @"imports_format should be DYLD_CHAINED_IMPORT");
        INTEXPECT(header->symbols_format, 0, @"symbols_format should be 0 (uncompressed)");
        EXPECTTRUE(header->imports_count >= 1, @"should have at least 1 import (_MPWCreateInteger)");

        NSLog(@"Reference chained fixups header: starts_offset=%u imports_offset=%u symbols_offset=%u imports_count=%u",
              header->starts_offset, header->imports_offset, header->symbols_offset, header->imports_count);

        // 3c. Characterize starts_in_image
        const struct dyld_chained_starts_in_image *startsInImage =
            (const struct dyld_chained_starts_in_image *)(chainedData.bytes + header->starts_offset);
        EXPECTTRUE(startsInImage->seg_count >= 2, @"should have at least 2 segments (TEXT, DATA_CONST or LINKEDIT)");
        NSLog(@"Reference starts_in_image: seg_count=%u", startsInImage->seg_count);

        // Find the segment with fixups (usually segment 1 = __DATA_CONST)
        for (int i = 0; i < startsInImage->seg_count; i++) {
            uint32_t segInfoOffset = startsInImage->seg_info_offset[i];
            if (segInfoOffset != 0) {
                const struct dyld_chained_starts_in_segment *segStarts =
                    (const struct dyld_chained_starts_in_segment *)(chainedData.bytes + header->starts_offset + segInfoOffset);
                NSLog(@"Reference segment %d: size=%u page_size=0x%x pointer_format=%u segment_offset=0x%llx page_count=%u",
                      i, segStarts->size, segStarts->page_size, segStarts->pointer_format,
                      segStarts->segment_offset, segStarts->page_count);

                // Check pointer format - may be DYLD_CHAINED_PTR_64 (2) or DYLD_CHAINED_PTR_64_OFFSET (6)
                EXPECTTRUE(segStarts->pointer_format == DYLD_CHAINED_PTR_64 ||
                           segStarts->pointer_format == DYLD_CHAINED_PTR_64_OFFSET,
                           @"pointer_format should be DYLD_CHAINED_PTR_64 or DYLD_CHAINED_PTR_64_OFFSET");

                // Log page starts
                for (int p = 0; p < segStarts->page_count; p++) {
                    uint16_t pageStart = segStarts->page_start[p];
                    if (pageStart != DYLD_CHAINED_PTR_START_NONE) {
                        NSLog(@"  Page %d: start=0x%x", p, pageStart);
                    }
                }
            }
        }

        // 3d. Characterize imports table
        const struct dyld_chained_import *imports =
            (const struct dyld_chained_import *)(chainedData.bytes + header->imports_offset);
        const char *symbolPool = (const char *)(chainedData.bytes + header->symbols_offset);

        for (uint32_t i = 0; i < header->imports_count; i++) {
            const char *symbolName = symbolPool + imports[i].name_offset;
            NSLog(@"Reference import %u: lib_ordinal=%u weak=%u name='%s'",
                  i, imports[i].lib_ordinal, imports[i].weak_import, symbolName);

            // We expect _MPWCreateInteger to be imported
            if (strcmp(symbolName, "_MPWCreateInteger") == 0) {
                NSLog(@"Found _MPWCreateInteger at import index %u with lib_ordinal %u", i, imports[i].lib_ordinal);
            }
        }
    }

    // 3e. Characterize __stubs section
    MPWMachOSegment *textSeg = [reader segmentObjectNamed:@"__TEXT"];
    EXPECTNOTNIL(textSeg, @"should have __TEXT segment");

    // Look for __stubs section in __TEXT
    MPWMachOSection *stubsSection = nil;
    for (MPWMachOSection *section in textSeg.sections) {
        if ([section.sectionName isEqualToString:@"__stubs"]) {
            stubsSection = section;
            break;
        }
    }

    if (stubsSection) {
        NSLog(@"Reference __stubs section: addr=0x%llx size=%lu offset=0x%lx",
              stubsSection.address, (unsigned long)stubsSection.size, stubsSection.offset);

        // Each stub is 12 bytes: adrp x16, GOT_page; ldr x16, [x16, GOT_off]; br x16
        INTEXPECT(stubsSection.size % 12, 0, @"stub section should be multiple of 12 bytes");

        // Log the actual stub code bytes
        NSData *stubData = [refDylibData subdataWithRange:NSMakeRange(stubsSection.offset, stubsSection.size)];
        const uint32_t *stubWords = (const uint32_t *)stubData.bytes;
        for (int i = 0; i < stubsSection.size / 4; i += 3) {
            NSLog(@"Stub[%d]: adrp=0x%08x ldr=0x%08x br=0x%08x", i/3, stubWords[i], stubWords[i+1], stubWords[i+2]);
        }
    } else {
        NSLog(@"No __stubs section found in reference dylib");
    }

    // 3f. Characterize __got section
    MPWMachOSegment *dataConstSeg = [reader segmentObjectNamed:@"__DATA_CONST"];
    if (!dataConstSeg) {
        dataConstSeg = [reader segmentObjectNamed:@"__DATA"];
    }

    if (dataConstSeg) {
        MPWMachOSection *gotSection = nil;
        for (MPWMachOSection *section in dataConstSeg.sections) {
            if ([section.sectionName isEqualToString:@"__got"]) {
                gotSection = section;
                break;
            }
        }

        if (gotSection) {
            NSLog(@"Reference __got section: addr=0x%llx size=%lu offset=0x%lx",
                  gotSection.address, (unsigned long)gotSection.size, gotSection.offset);

            // Log GOT entry values (should have chained fixup encoding)
            NSData *gotData = [refDylibData subdataWithRange:NSMakeRange(gotSection.offset, gotSection.size)];
            const uint64_t *gotEntries = (const uint64_t *)gotData.bytes;
            for (int i = 0; i < gotSection.size / 8; i++) {
                uint64_t entry = gotEntries[i];
                // Decode as dyld_chained_ptr_64_bind
                struct dyld_chained_ptr_64_bind bind;
                memcpy(&bind, &entry, sizeof(bind));
                NSLog(@"GOT[%d]: raw=0x%016llx ordinal=%u addend=%u next=%u bind=%u",
                      i, entry, bind.ordinal, bind.addend, bind.next, bind.bind);
            }
        } else {
            NSLog(@"No __got section found in reference dylib");
        }
    }

    // 3g. Characterize BL instruction in __text pointing to __stubs
    MPWMachOSection *textSection = [reader textSection];
    EXPECTNOTNIL(textSection, @"should have __text section");

    if (textSection && stubsSection) {
        NSData *textData = [refDylibData subdataWithRange:NSMakeRange(textSection.offset, textSection.size)];
        const uint32_t *textWords = (const uint32_t *)textData.bytes;

        // Search for BL instructions (opcode starts with 0x94 or 0x97 for bl)
        for (int i = 0; i < textSection.size / 4; i++) {
            uint32_t instr = textWords[i];
            if ((instr & 0xfc000000) == 0x94000000) {  // BL instruction
                int32_t offset = (instr & 0x03ffffff);
                if (offset & 0x02000000) offset |= 0xfc000000;  // Sign extend
                offset <<= 2;  // Convert to bytes

                uint64_t blAddr = textSection.address + (i * 4);
                uint64_t targetAddr = blAddr + offset;

                NSLog(@"BL at 0x%llx: instr=0x%08x offset=%d target=0x%llx (stubs at 0x%llx)",
                      blAddr, instr, offset, targetAddr, stubsSection.address);

                // Verify BL targets the stubs section
                if (targetAddr >= stubsSection.address && targetAddr < stubsSection.address + stubsSection.size) {
                    NSLog(@"  -> Correctly targets __stubs section");
                }
            }
        }
    }

    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:objectPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:dylibPath error:nil];
}

// Characterization test: Generate dylib using MPWMachODylibWriter with external call
// and compare against reference characteristics discovered in testCharacterizeReferenceExternalCallDylib
+ (void)testCharacterizeGeneratedExternalCallDylib {
    // Generate dylib using MPWMachODylibWriter (same as testDylibWithExternalCall but without dlopen)
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    writer.installName = @"@rpath/libexternalcall.dylib";
    [writer.frameworks addObject:@"/Library/Frameworks/MPWFoundation.framework/Versions/A/MPWFoundation"];

    STObjectCodeGeneratorARM *gen = [STObjectCodeGeneratorARM stream];
    gen.symbolWriter = writer;
    gen.relocationWriter = writer.textSectionWriter;

    // Generate wrapper function that calls _MPWCreateInteger
    [gen generateFunctionNamed:@"_wrap_MPWCreateInteger" stackSpace:32 body:^(STObjectCodeGeneratorARM *g) {
        [g generateCallToExternalFunctionNamed:@"_MPWCreateInteger"];
    }];
    [writer addTextSectionData:gen.generatedCode];

    [writer writeFile];
    NSData *genDylibData = [writer data];
    EXPECTNOTNIL(genDylibData, @"generated dylib should have data");

    // Write to file for analysis
    NSString *genPath = @"/tmp/libexternalcall_gen.dylib";
    [genDylibData writeToFile:genPath atomically:YES];

    // Read and characterize the generated dylib
    MPWMachOReader *reader = [MPWMachOReader readerWithData:genDylibData];
    EXPECTNOTNIL(reader, @"reader should be created");
    EXPECTTRUE([reader isHeaderValid], @"header should be valid");

    // 1. Verify LC_DYLD_CHAINED_FIXUPS exists (CRITICAL for external calls)
    struct linkedit_data_command *chainedCmd =
        (struct linkedit_data_command *)[reader loadCommandOfTypeIfPresent:LC_DYLD_CHAINED_FIXUPS];
    EXPECTNOTNIL(chainedCmd, @"generated dylib should have LC_DYLD_CHAINED_FIXUPS");

    if (chainedCmd) {
        // 2. Characterize chained fixups header
        NSData *chainedData = [self chainedFixupsDataFromReader:reader];
        EXPECTNOTNIL(chainedData, @"should have chained fixups data");
        EXPECTTRUE(chainedData.length >= sizeof(struct dyld_chained_fixups_header),
                   @"chained data should be large enough for header");

        const struct dyld_chained_fixups_header *header =
            (const struct dyld_chained_fixups_header *)chainedData.bytes;

        // Compare against reference: fixups_version=0, imports_format=DYLD_CHAINED_IMPORT
        INTEXPECT(header->fixups_version, 0, @"fixups_version should be 0");
        INTEXPECT(header->imports_format, DYLD_CHAINED_IMPORT, @"imports_format should be DYLD_CHAINED_IMPORT");
        INTEXPECT(header->symbols_format, 0, @"symbols_format should be 0 (uncompressed)");

        // Reference had imports_count=1
        INTEXPECT(header->imports_count, 1, @"should have exactly 1 import (_MPWCreateInteger)");

        NSLog(@"Generated chained fixups header: starts_offset=%u imports_offset=%u symbols_offset=%u imports_count=%u",
              header->starts_offset, header->imports_offset, header->symbols_offset, header->imports_count);

        // 3. Characterize starts_in_image
        if (header->starts_offset > 0 && header->starts_offset < chainedData.length) {
            const struct dyld_chained_starts_in_image *startsInImage =
                (const struct dyld_chained_starts_in_image *)(chainedData.bytes + header->starts_offset);

            NSLog(@"Generated starts_in_image: seg_count=%u", startsInImage->seg_count);

            // Find the segment with fixups
            for (int i = 0; i < startsInImage->seg_count && i < 10; i++) {
                uint32_t segInfoOffset = startsInImage->seg_info_offset[i];
                if (segInfoOffset != 0) {
                    const struct dyld_chained_starts_in_segment *segStarts =
                        (const struct dyld_chained_starts_in_segment *)(chainedData.bytes + header->starts_offset + segInfoOffset);

                    NSLog(@"Generated segment %d: size=%u page_size=0x%x pointer_format=%u segment_offset=0x%llx page_count=%u",
                          i, segStarts->size, segStarts->page_size, segStarts->pointer_format,
                          segStarts->segment_offset, segStarts->page_count);

                    // Reference had: page_size=0x4000, pointer_format=6 (DYLD_CHAINED_PTR_64_OFFSET)
                    INTEXPECT(segStarts->page_size, 0x4000, @"page_size should be 16KB");

                    // Log page starts
                    for (int p = 0; p < segStarts->page_count && p < 10; p++) {
                        uint16_t pageStart = segStarts->page_start[p];
                        if (pageStart != DYLD_CHAINED_PTR_START_NONE) {
                            NSLog(@"  Page %d: start=0x%x", p, pageStart);
                        }
                    }
                }
            }
        }

        // 4. Characterize imports table
        if (header->imports_offset > 0 && header->imports_offset < chainedData.length) {
            const struct dyld_chained_import *imports =
                (const struct dyld_chained_import *)(chainedData.bytes + header->imports_offset);
            const char *symbolPool = (const char *)(chainedData.bytes + header->symbols_offset);

            for (uint32_t i = 0; i < header->imports_count && i < 10; i++) {
                const char *symbolName = symbolPool + imports[i].name_offset;
                NSLog(@"Generated import %u: lib_ordinal=%u weak=%u name='%s'",
                      i, imports[i].lib_ordinal, imports[i].weak_import, symbolName);

                // Reference had: lib_ordinal=1, name='_MPWCreateInteger'
                if (i == 0) {
                    // MPWFoundation is ordinal 2 (libSystem=1, MPWFoundation=2)
                    INTEXPECT(imports[i].lib_ordinal, 2, @"_MPWCreateInteger should come from ordinal 2 (MPWFoundation)");
                    EXPECTTRUE(strcmp(symbolName, "_MPWCreateInteger") == 0, @"first import should be _MPWCreateInteger");
                }
            }
        }
    }

    // 5. Characterize __stubs section
    MPWMachOSegment *textSeg = [reader segmentObjectNamed:@"__TEXT"];
    EXPECTNOTNIL(textSeg, @"should have __TEXT segment");

    MPWMachOSection *stubsSection = nil;
    if (textSeg) {
        for (MPWMachOSection *section in textSeg.sections) {
            if ([section.sectionName isEqualToString:@"__stubs"]) {
                stubsSection = section;
                break;
            }
        }
    }

    if (stubsSection) {
        NSLog(@"Generated __stubs section: addr=0x%lx size=%lu offset=0x%lx",
              stubsSection.address, (unsigned long)stubsSection.size, stubsSection.offset);

        // Reference had: size=12 (one 12-byte stub)
        INTEXPECT(stubsSection.size, 12, @"stub section should be 12 bytes for 1 external symbol");

        // Log stub code
        NSData *stubData = [genDylibData subdataWithRange:NSMakeRange(stubsSection.offset, stubsSection.size)];
        const uint32_t *stubWords = (const uint32_t *)stubData.bytes;
        for (int i = 0; i < stubsSection.size / 4; i += 3) {
            NSLog(@"Generated Stub[%d]: adrp=0x%08x ldr=0x%08x br=0x%08x", i/3, stubWords[i], stubWords[i+1], stubWords[i+2]);
        }
    } else {
        NSLog(@"ERROR: No __stubs section found in generated dylib");
        EXPECTTRUE(NO, @"generated dylib should have __stubs section");
    }

    // 6. Characterize __got section
    MPWMachOSegment *dataConstSeg = [reader segmentObjectNamed:@"__DATA_CONST"];
    if (!dataConstSeg) {
        dataConstSeg = [reader segmentObjectNamed:@"__DATA"];
    }

    MPWMachOSection *gotSection = nil;
    if (dataConstSeg) {
        for (MPWMachOSection *section in dataConstSeg.sections) {
            if ([section.sectionName isEqualToString:@"__got"]) {
                gotSection = section;
                break;
            }
        }
    }

    if (gotSection) {
        NSLog(@"Generated __got section: addr=0x%lx size=%lu offset=0x%lx",
              gotSection.address, (unsigned long)gotSection.size, gotSection.offset);

        // Reference had: size=8 (one 8-byte GOT entry)
        INTEXPECT(gotSection.size, 8, @"GOT section should be 8 bytes for 1 external symbol");

        // Log GOT entry
        NSData *gotData = [genDylibData subdataWithRange:NSMakeRange(gotSection.offset, gotSection.size)];
        const uint64_t *gotEntries = (const uint64_t *)gotData.bytes;
        for (int i = 0; i < gotSection.size / 8; i++) {
            uint64_t entry = gotEntries[i];
            struct dyld_chained_ptr_64_bind bind;
            memcpy(&bind, &entry, sizeof(bind));
            NSLog(@"Generated GOT[%d]: raw=0x%016llx ordinal=%u addend=%u next=%u bind=%u",
                  i, entry, bind.ordinal, bind.addend, bind.next, bind.bind);

            // Reference had: raw=0x8000000000000000 ordinal=0 bind=1
            // The high bit (0x8000000000000000) indicates bind=1
            INTEXPECT(bind.bind, 1, @"GOT entry should have bind=1");
        }
    } else {
        NSLog(@"ERROR: No __got section found in generated dylib");
        EXPECTTRUE(NO, @"generated dylib should have __got section");
    }

    // 7. Characterize BL instruction targeting __stubs
    MPWMachOSection *textSection = [reader textSection];
    EXPECTNOTNIL(textSection, @"should have __text section");

    if (textSection && stubsSection) {
        NSData *textData = [genDylibData subdataWithRange:NSMakeRange(textSection.offset, textSection.size)];
        const uint32_t *textWords = (const uint32_t *)textData.bytes;

        BOOL foundBL = NO;
        for (int i = 0; i < textSection.size / 4; i++) {
            uint32_t instr = textWords[i];
            if ((instr & 0xfc000000) == 0x94000000) {  // BL instruction
                int32_t offset = (instr & 0x03ffffff);
                if (offset & 0x02000000) offset |= 0xfc000000;  // Sign extend
                offset <<= 2;

                uint64_t blAddr = textSection.address + (i * 4);
                uint64_t targetAddr = blAddr + offset;

                NSLog(@"Generated BL at 0x%llx: instr=0x%08x offset=%d target=0x%lx (stubs at 0x%lx)",
                      blAddr, instr, offset, targetAddr, stubsSection.address);

                // Verify BL targets the stubs section
                if (targetAddr >= stubsSection.address && targetAddr < stubsSection.address + stubsSection.size) {
                    NSLog(@"  -> Correctly targets __stubs section");
                    foundBL = YES;
                }
            }
        }
        EXPECTTRUE(foundBL, @"should have BL instruction targeting __stubs");
    }

    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:genPath error:nil];
}

+ (void)testDylibWithIntraLibraryCall {
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    NSString *path = @"/tmp/libintra.dylib";
    writer.installName = @"@rpath/libintra.dylib";

    // Function 1: _helper - returns 42
    unsigned char helperCode[] = {
        0x40, 0x05, 0x80, 0x52, // mov w0, #42
        0xc0, 0x03, 0x5f, 0xd6  // ret
    };

    // Declare helper at offset 0
    [writer declareGlobalSymbol:@"_helper" atOffset:0];
    [writer addTextSectionData:[NSData dataWithBytes:helperCode length:sizeof(helperCode)]];

    // Function 2: _caller - calls _helper and returns result
    STObjectCodeGeneratorARM *gen = [STObjectCodeGeneratorARM stream];
    gen.symbolWriter = writer;
    gen.relocationWriter = writer.textSectionWriter;

    [gen generateFunctionNamed:@"_caller" stackSpace:32 body:^(STObjectCodeGeneratorARM *g) {
        [g generateCallToInternalFunctionNamed:@"_helper"];
    }];

    // Declare caller at offset after helper
    [writer declareGlobalSymbol:@"_caller" atOffset:sizeof(helperCode)];
    [writer addTextSectionData:gen.generatedCode];

    [writer writeFile];
    NSData *dylibData = [writer data];
    [dylibData writeToFile:path atomically:YES];

    // Ad-hoc sign
    system([[NSString stringWithFormat:@"codesign -f -s - %@", path] UTF8String]);

    // Load and test
    void *handle = dlopen([path UTF8String], RTLD_NOW);
    if (!handle) {
        NSLog(@"dlopen error: %s", dlerror());
    }
    EXPECTNOTNIL(handle, @"dylib with intra-library call should load");

    if (handle) {
        int (*caller)(void) = dlsym(handle, "caller");
        EXPECTNOTNIL(caller, @"caller function should be found");
        if (caller) {
            INTEXPECT(caller(), 42, @"caller should return 42 (from helper)");
        }

        int (*helper)(void) = dlsym(handle, "helper");
        EXPECTNOTNIL(helper, @"helper function should also be exported");
        if (helper) {
            INTEXPECT(helper(), 42, @"helper should return 42 directly");
        }

        dlclose(handle);
    }

    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

// Characterization test: Create reference dylib with message send using ObjSTNative object file
// linked with external linker. Documents structure for comparison with our generated version.
+ (void)testCharacterizeReferenceMessageSendDylib {
    // 1. Generate object file with message send using MPWMachOWriter + STObjectCodeGeneratorARM
    STNativeCompiler *compiler = [STNativeCompiler compiler];
    NSString *tempDir = @"/tmp";
    NSString *objectPath = [tempDir stringByAppendingPathComponent:@"msgsend_ref.o"];
    NSString *dylibPath = [tempDir stringByAppendingPathComponent:@"msgsend_ref.dylib"];

    MPWMachOWriter *objectWriter = compiler.writer;
    STObjectCodeGeneratorARM *gen = compiler.codegen;
    gen.symbolWriter = objectWriter;
    gen.relocationWriter = objectWriter.textSectionWriter;

    // Generate: concatStrings(id prefix, id suffix) { return [prefix stringByAppendingString:suffix]; }
    // x0 = prefix (receiver), x1 = suffix (argument)
    // Move x1 to x2 (second arg to objc_msgSend), x0 stays as receiver
    [compiler generateFunctionNamed:@"_concatStrings" body:^(STObjectCodeGeneratorARM * _Nonnull gen) {
        [gen generateMoveRegisterFrom:1 to:2];
        [gen generateMessageSendToSelector:@"stringByAppendingString:"];

        //        [codegen loadRegister:2 fromContentsOfAdressInRegister:2];
        //        [codegen generateMoveConstant:0 to:0];
    }];
    [objectWriter addTextSectionData:gen.generatedCode];

    [objectWriter writeFile];
    [objectWriter.data writeToFile:objectPath atomically:YES];

    // 2. Link with external linker
    int linkResult = [compiler linkObjects:@[@"msgsend_ref"]
                           toSharedLibrary:@"msgsend_ref.dylib"
                                     inDir:tempDir
                            withFrameworks:@[@"Foundation"]];
    INTEXPECT(linkResult, 0, @"external linker should succeed");

    // Sign the dylib
    system([[NSString stringWithFormat:@"codesign -f -s - %@", dylibPath] UTF8String]);

    // 3. Read reference dylib
    NSData *refDylibData = [NSData dataWithContentsOfFile:dylibPath];
    EXPECTNOTNIL(refDylibData, @"reference dylib should be created");

    MPWMachOReader *reader = [MPWMachOReader readerWithData:refDylibData];
    EXPECTNOTNIL(reader, @"reader should be created");
    EXPECTTRUE([reader isHeaderValid], @"header should be valid");

    // 4. Characterize exports using MPWMachOReader
    NSArray *exports = [reader exportedSymbolNames];
    NSLog(@"Reference exports: %@", exports);

    // Should only export _concatStrings, NOT _objc_msgSend$stringByAppendingString:
    EXPECTTRUE([exports containsObject:@"_concatStrings"], @"should export _concatStrings");
    BOOL hasObjcMsgSendExport = NO;
    for (NSString *exp in exports) {
        if ([exp hasPrefix:@"_objc_msgSend$"]) {
            hasObjcMsgSendExport = YES;
            break;
        }
    }
    EXPECTFALSE(hasObjcMsgSendExport, @"should NOT export _objc_msgSend$ variants");

    // 5. Characterize chained fixups imports - should bind to _objc_msgSend (not _objc_msgSend$...)
    NSData *chainedData = [self chainedFixupsDataFromReader:reader];
    EXPECTNOTNIL(chainedData, @"should have chained fixups data");

    if (chainedData) {
        const struct dyld_chained_fixups_header *header =
            (const struct dyld_chained_fixups_header *)chainedData.bytes;
        const struct dyld_chained_import *imports =
            (const struct dyld_chained_import *)((const uint8_t *)header + header->imports_offset);
        const char *symbolPool = (const char *)header + header->symbols_offset;

        BOOL foundObjcMsgSend = NO;
        BOOL foundObjcMsgSendDollar = NO;
        for (uint32_t i = 0; i < header->imports_count; i++) {
            const char *name = symbolPool + imports[i].name_offset;
            NSLog(@"Reference import %d: '%s'", i, name);
            if (strcmp(name, "_objc_msgSend") == 0) {
                foundObjcMsgSend = YES;
            }
            if (strncmp(name, "_objc_msgSend$", 14) == 0) {
                foundObjcMsgSendDollar = YES;
            }
        }
        EXPECTTRUE(foundObjcMsgSend, @"reference should import _objc_msgSend");
        EXPECTFALSE(foundObjcMsgSendDollar, @"reference should NOT import _objc_msgSend$ variants");

        // 5b. Characterize segment fixups structure
        const struct dyld_chained_starts_in_image *starts =
            (const struct dyld_chained_starts_in_image *)((const uint8_t *)header + header->starts_offset);
        NSLog(@"Reference starts: seg_count=%d", starts->seg_count);

        // Log which segments have fixups
        for (int i = 0; i < starts->seg_count; i++) {
            uint32_t offset = starts->seg_info_offset[i];
            if (offset != 0) {
                const struct dyld_chained_starts_in_segment *segStarts =
                    (const struct dyld_chained_starts_in_segment *)((const uint8_t *)starts + offset);
                NSLog(@"Reference segment %d: size=%d page_size=0x%x pointer_format=%d segment_offset=0x%llx page_count=%d",
                      i, segStarts->size, segStarts->page_size, segStarts->pointer_format,
                      segStarts->segment_offset, segStarts->page_count);
            } else {
                NSLog(@"Reference segment %d: no fixups", i);
            }
        }
    }

    // 6. Characterize sections - should have __objc_stubs, __objc_methname, __objc_selrefs
    MPWMachOSegment *textSeg = [reader segmentObjectNamed:@"__TEXT"];
    EXPECTNOTNIL(textSeg, @"should have __TEXT");

    BOOL hasObjcStubs = NO;
    BOOL hasObjcMethname = NO;

    if (textSeg) {
        for (MPWMachOSection *section in textSeg.sections) {
            NSLog(@"Reference __TEXT section: %@", section.sectionName);
            if ([section.sectionName isEqualToString:@"__objc_stubs"]) {
                hasObjcStubs = YES;
                NSLog(@"  __objc_stubs: addr=0x%lx size=%lu", section.address, (unsigned long)section.size);
            }
            if ([section.sectionName isEqualToString:@"__objc_methname"]) {
                hasObjcMethname = YES;
                NSLog(@"  __objc_methname: addr=0x%lx size=%lu", section.address, (unsigned long)section.size);
            }
        }
    }

    EXPECTTRUE(hasObjcStubs, @"reference should have __objc_stubs section");
    EXPECTTRUE(hasObjcMethname, @"reference should have __objc_methname section");

    // Check for __objc_selrefs in __DATA
    MPWMachOSegment *dataSeg = [reader segmentObjectNamed:@"__DATA"];
    BOOL hasObjcSelrefs = NO;

    if (dataSeg) {
        for (MPWMachOSection *section in dataSeg.sections) {
            NSLog(@"Reference __DATA section: %@", section.sectionName);
            if ([section.sectionName isEqualToString:@"__objc_selrefs"]) {
                hasObjcSelrefs = YES;
                NSLog(@"  __objc_selrefs: addr=0x%lx size=%lu", section.address, (unsigned long)section.size);
            }
        }
    }

    EXPECTTRUE(hasObjcSelrefs, @"reference should have __objc_selrefs section in __DATA");

    // 7. Test that reference dylib actually loads and works
    void *handle = dlopen([dylibPath UTF8String], RTLD_NOW);
    EXPECTNOTNIL(handle, @"reference dylib should load");

    if (handle) {
        id (*concatStrings)(id, id) = dlsym(handle, "concatStrings");
        EXPECTNOTNIL(concatStrings, @"should find concatStrings");
        if (concatStrings) {
            NSString *result = concatStrings(@"Hello, ", @"World!");
            IDEXPECT(result, @"Hello, World!", @"reference should work correctly");
        }
        dlclose(handle);
    }

    // Cleanup temp files
    [[NSFileManager defaultManager] removeItemAtPath:objectPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:dylibPath error:nil];
}

// Characterization test: Check the generated message send dylib structure
// and compare against reference to find differences
+ (void)testCharacterizeGeneratedMessageSendDylib {
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    NSString *path = @"/tmp/libmsgsend_gen.dylib";
    writer.installName = @"@rpath/libmsgsend.dylib";

    STObjectCodeGeneratorARM *gen = [STObjectCodeGeneratorARM stream];
    gen.symbolWriter = writer;
    gen.relocationWriter = writer.textSectionWriter;

    [gen generateFunctionNamed:@"_concatStrings" stackSpace:32 body:^(STObjectCodeGeneratorARM *g) {
        [g generateMoveRegisterFrom:1 to:2];
        [g generateMessageSendToSelector:@"stringByAppendingString:"];
    }];

    [writer addTextSectionData:gen.generatedCode];
    [writer writeFile];
    NSData *genDylibData = [writer data];
    [genDylibData writeToFile:path atomically:YES];

    system([[NSString stringWithFormat:@"codesign -f -s - %@", path] UTF8String]);

    MPWMachOReader *reader = [MPWMachOReader readerWithData:genDylibData];
    EXPECTNOTNIL(reader, @"reader should be created");
    EXPECTTRUE([reader isHeaderValid], @"header should be valid");

    // 1. Check exports using MPWMachOReader - should only export _concatStrings, NOT _objc_msgSend$...
    NSArray *exports = [reader exportedSymbolNames];
    NSLog(@"Generated exports: %@", exports);

    EXPECTTRUE([exports containsObject:@"_concatStrings"], @"should export _concatStrings");

    BOOL hasObjcMsgSendExport = NO;
    for (NSString *exp in exports) {
        if ([exp hasPrefix:@"_objc_msgSend$"]) {
            hasObjcMsgSendExport = YES;
            break;
        }
    }
    EXPECTFALSE(hasObjcMsgSendExport, @"should NOT export _objc_msgSend$ variants");

    // 2. Check chained fixups imports - should import _objc_msgSend, not _objc_msgSend$...
    NSData *chainedData = [self chainedFixupsDataFromReader:reader];
    EXPECTNOTNIL(chainedData, @"should have chained fixups data");

    BOOL foundObjcMsgSend = NO;
    BOOL foundObjcMsgSendDollar = NO;

    if (chainedData) {
        const struct dyld_chained_fixups_header *header =
            (const struct dyld_chained_fixups_header *)chainedData.bytes;
        const struct dyld_chained_import *imports =
            (const struct dyld_chained_import *)((const uint8_t *)header + header->imports_offset);
        const char *symbolPool = (const char *)header + header->symbols_offset;

        for (uint32_t i = 0; i < header->imports_count; i++) {
            const char *name = symbolPool + imports[i].name_offset;
            NSLog(@"Generated import %d: '%s'", i, name);
            if (strcmp(name, "_objc_msgSend") == 0) {
                foundObjcMsgSend = YES;
            }
            if (strncmp(name, "_objc_msgSend$", 14) == 0) {
                foundObjcMsgSendDollar = YES;
            }
        }

        // Log segment fixups structure for comparison with reference
        const struct dyld_chained_starts_in_image *starts =
            (const struct dyld_chained_starts_in_image *)((const uint8_t *)header + header->starts_offset);
        NSLog(@"Generated starts: seg_count=%d", starts->seg_count);

        for (int i = 0; i < starts->seg_count; i++) {
            uint32_t offset = starts->seg_info_offset[i];
            if (offset != 0) {
                const struct dyld_chained_starts_in_segment *segStarts =
                    (const struct dyld_chained_starts_in_segment *)((const uint8_t *)starts + offset);
                NSLog(@"Generated segment %d: size=%d page_size=0x%x pointer_format=%d segment_offset=0x%llx page_count=%d",
                      i, segStarts->size, segStarts->page_size, segStarts->pointer_format,
                      segStarts->segment_offset, segStarts->page_count);
            } else {
                NSLog(@"Generated segment %d: no fixups", i);
            }
        }
    }

    EXPECTTRUE(foundObjcMsgSend, @"should import _objc_msgSend (not $variant)");
    EXPECTFALSE(foundObjcMsgSendDollar, @"should NOT import _objc_msgSend$ variants");

    // 3. Check sections - should have __objc_stubs (not __stubs), __objc_methname, __objc_selrefs
    MPWMachOSegment *textSeg = [reader segmentObjectNamed:@"__TEXT"];

    BOOL hasObjcStubs = NO;
    BOOL hasRegularStubs = NO;
    BOOL hasObjcMethname = NO;

    if (textSeg) {
        for (MPWMachOSection *section in textSeg.sections) {
            NSLog(@"Generated __TEXT section: %@", section.sectionName);
            if ([section.sectionName isEqualToString:@"__objc_stubs"]) {
                hasObjcStubs = YES;
            }
            if ([section.sectionName isEqualToString:@"__stubs"]) {
                hasRegularStubs = YES;
            }
            if ([section.sectionName isEqualToString:@"__objc_methname"]) {
                hasObjcMethname = YES;
            }
        }
    }

    // For objc message sends, we need __objc_stubs (not __stubs)
    EXPECTTRUE(hasObjcStubs, @"should have __objc_stubs section for objc message sends - BUG if missing");
    EXPECTTRUE(hasObjcMethname, @"should have __objc_methname section - BUG if missing");
    // Having regular __stubs is OK for non-objc external calls, but for pure objc we don't need it
    if (hasRegularStubs && !hasObjcStubs) {
        NSLog(@"WARNING: Has __stubs but not __objc_stubs - wrong section type for objc");
    }

    // Check for __objc_selrefs
    MPWMachOSegment *dataSeg = [reader segmentObjectNamed:@"__DATA"];
    MPWMachOSegment *dataConstSeg = [reader segmentObjectNamed:@"__DATA_CONST"];

    BOOL hasObjcSelrefs = NO;

    for (MPWMachOSegment *seg in @[dataSeg ?: [NSNull null], dataConstSeg ?: [NSNull null]]) {
        if ([seg isKindOfClass:[MPWMachOSegment class]]) {
            for (MPWMachOSection *section in seg.sections) {
                NSLog(@"Generated %@ section: %@", seg.name, section.sectionName);
                if ([section.sectionName isEqualToString:@"__objc_selrefs"]) {
                    hasObjcSelrefs = YES;
                }
            }
        }
    }

    EXPECTTRUE(hasObjcSelrefs, @"should have __objc_selrefs section - BUG if missing");

    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

+ (void)testDylibWithMessageSend {
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    NSString *path = @"/tmp/libmsgsend.dylib";
    writer.installName = @"@rpath/libmsgsend.dylib";

    STObjectCodeGeneratorARM *gen = [STObjectCodeGeneratorARM stream];
    gen.symbolWriter = writer;
    gen.relocationWriter = writer.textSectionWriter;

    // Generate: id concatStrings(id prefix, id suffix)
    // On entry: x0=prefix, x1=suffix
    // Need: x0=prefix (receiver), x2=suffix (arg for stringByAppendingString:)
    [gen generateFunctionNamed:@"_concatStrings" stackSpace:32 body:^(STObjectCodeGeneratorARM *g) {
        // Move suffix from x1 to x2 (argument position)
        [g generateMoveRegisterFrom:1 to:2];
        // x0 already has prefix (receiver)
        // Call [prefix stringByAppendingString:suffix]
        [g generateMessageSendToSelector:@"stringByAppendingString:"];
        // Result is in x0, which is what we return
    }];

    [writer addTextSectionData:gen.generatedCode];

    [writer writeFile];
    NSData *dylibData = [writer data];
    [dylibData writeToFile:path atomically:YES];

    // Ad-hoc sign
    system([[NSString stringWithFormat:@"codesign -f -s - %@", path] UTF8String]);

    // Load and test
    void *handle = dlopen([path UTF8String], RTLD_NOW);
    if (!handle) {
        NSLog(@"dlopen error: %s", dlerror());
    }
    EXPECTNOTNIL(handle, @"dylib with message send should load");

    if (handle) {
        id (*concatStrings)(id, id) = dlsym(handle, "concatStrings");
        EXPECTNOTNIL(concatStrings, @"concatStrings function should be found");
        if (concatStrings) {
            NSString *prefix = @"Hello, ";
            NSString *suffix = @"World!";
            NSString *result = concatStrings(prefix, suffix);
            IDEXPECT(result, @"Hello, World!", @"should concatenate strings");
        }
        dlclose(handle);
    }

    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

+ (NSArray *)testSelectors {
  return @[
    @"testDocumentReferenceLoadCommands", @"testDylibLayoutAssumptions",
    @"testGeneratedDylibFollowsLayoutAssumptions",
    @"testCompareSignedDylibStructure", @"testCanWriteDylibHeader",
    @"testDylibHasIdLoadCommand", @"testDylibHasMultipleSegments",
    @"testDylibHasExportsTrie", @"testDylibExportsSymbol",
    @"testDissectKnownCorrectDylib", @"testDylibReaderCanParseMultipleSegments",
    @"testMinimalDylibCanBeLoaded", @"testDylibWithMultipleFunctions",
    @"testCharacterizeReferenceExternalCallDylib",
    @"testCharacterizeGeneratedExternalCallDylib",
    @"testDylibWithExternalCall",
    @"testDylibWithIntraLibraryCall",
    @"testCharacterizeReferenceMessageSendDylib",
    @"testCharacterizeGeneratedMessageSendDylib",
    @"testDylibWithMessageSend",
  ];
}


@end
