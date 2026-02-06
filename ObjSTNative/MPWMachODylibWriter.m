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
    // Fix text section number to match Mach-O 1-based convention
    // (base class addSectionWriter: assigns 0-based, but textSectionNumber returns 1)
    self.textSectionWriter.sectionNumber = 1;
    self.currentVersion = 0x10000;       // 1.0.0
    self.compatibilityVersion = 0x10000; // 1.0.0
    self.chainedFixupWriter =
        [[[MPWChainedFixupWriter alloc] init] autorelease];
    self.stubOffsets = [NSMutableDictionary dictionary];
    self.gotOffsets = [NSMutableDictionary dictionary];
    self.frameworks =
        [NSMutableArray arrayWithObjects:@"/usr/lib/libSystem.B.dylib",
                                         @"/usr/lib/libobjc.A.dylib", nil];
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

      if ([sectionWriter.segname isEqualToString:@"__DATA_CONST"] &&
          ([sectionWriter.sectname isEqualToString:@"__objc_arrayobj"] ||
           [sectionWriter.sectname isEqualToString:@"__objc_arraydata"])) {
        uint64_t after = 0;
        if (sectionData.length >= (NSUInteger)offset + 8) {
          [sectionData getBytes:&after range:NSMakeRange((NSUInteger)offset, 8)];
        }
        NSLog(@"applyRelocations AFTER  %@.%@ offset=0x%x relocType=%d symbol=%@ value=0x%llx",
              sectionWriter.segname, sectionWriter.sectname, offset, relocType, symbolName, after);
      }
    }
  }
}

- (int)ordinalForSymbol:(NSString *)symbol {
  int ordinal = 1; // Default to libSystem

  // NSConstant classes must be checked BEFORE generic _OBJC_CLASS_$_ check
  // These classes are NOT in libobjc, they're in CoreFoundation or Foundation
  if ([symbol containsString:@"NSConstantArray"] ||
      [symbol containsString:@"NSConstantDictionary"] ||
      [symbol containsString:@"NSConstantData"] ||
      [symbol containsString:@"NSConstantDate"]) {
      // These NSConstant classes are in CoreFoundation
      NSLog(@"ordinalForSymbol: %@ -> CoreFoundation, frameworks=%@", symbol, self.frameworks);
      for (int i = 0; i < self.frameworks.count; i++) {
          if ([self.frameworks[i] containsString:@"CoreFoundation"]) {
              ordinal = i + 1;
              NSLog(@"ordinalForSymbol: %@ -> CoreFoundation ordinal=%d", symbol, ordinal);
              break;
          }
      }
  } else if ([symbol containsString:@"NSConstantIntegerNumber"] ||
             [symbol containsString:@"NSConstantDoubleNumber"] ||
             [symbol containsString:@"NSConstantFloatNumber"]) {
      // These NSConstant number classes are in Foundation
      for (int i = 0; i < self.frameworks.count; i++) {
          if ([self.frameworks[i] containsString:@"Foundation"]) {
              ordinal = i + 1;
              break;
          }
      }
  } else if ([symbol isEqualToString:@"_objc_msgSend"] ||
             [symbol isEqualToString:@"__objc_empty_cache"] ||
             [symbol hasPrefix:@"_OBJC_CLASS_$_"] ||
             [symbol hasPrefix:@"_OBJC_METACLASS_$_"]) {
      // ObjC runtime symbols come from libobjc
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
  } else if ([symbol isEqualToString:@"___CFConstantStringClassReference"]) {
      // ___CFConstantStringClassReference is in CoreFoundation (part of Foundation)
      for (int i = 0; i < self.frameworks.count; i++) {
          if ([self.frameworks[i] containsString:@"Foundation"]) {
              ordinal = i + 1;
              break;
          }
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

#import "MPWMachOReader.h"
#import "STNativeCompiler.h"
#import "STNativeCompilerTestsMachO.h"
#import "STObjectCodeGeneratorARM.h"
#import "macho-headers/mach-o/fixup-chains.h"
#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachODylibWriter (testing)

static int literalTestCounter = 0;

static NSString *uniqueLiteralPath(NSString *baseName, NSString **outInstallName) {
    literalTestCounter++;
    NSString *suffix = [NSString stringWithFormat:@"%d", literalTestCounter];
    if (outInstallName) {
        *outInstallName = [NSString stringWithFormat:@"@rpath/%@_%@.dylib", baseName, suffix];
    }
    return [NSString stringWithFormat:@"/tmp/%@_%@.dylib", baseName, suffix];
}

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

// Helper to check if exports contain any symbol with given prefix
+ (BOOL)exports:(NSArray *)exports containSymbolWithPrefix:(NSString *)prefix {
    for (NSString *exp in exports) {
        if ([exp hasPrefix:prefix]) {
            return YES;
        }
    }
    return NO;
}

// Helper to find a section by name in a segment
+ (MPWMachOSection *)findSectionNamed:(NSString *)sectionName inSegment:(MPWMachOSegment *)segment {
    for (MPWMachOSection *section in segment.sections) {
        if ([section.sectionName isEqualToString:sectionName]) {
            return section;
        }
    }
    return nil;
}

// Helper to check if segment has a section with given name
+ (BOOL)segment:(MPWMachOSegment *)segment hasSectionNamed:(NSString *)sectionName {
    return [self findSectionNamed:sectionName inSegment:segment] != nil;
}

// Helper to log and check chained fixups imports for a specific symbol
// Returns a dictionary with keys: @"found", @"foundDollarVariant" as NSNumbers (BOOLs)
+ (NSDictionary *)checkChainedFixupsImportsIn:(NSData *)chainedData
                                    forSymbol:(NSString *)symbolName
                                    logPrefix:(NSString *)prefix {
    BOOL foundSymbol = NO;
    BOOL foundDollarVariant = NO;
    NSString *dollarPrefix = [symbolName stringByAppendingString:@"$"];

    if (!chainedData) {
        return @{@"found": @NO, @"foundDollarVariant": @NO};
    }

    const struct dyld_chained_fixups_header *header =
        (const struct dyld_chained_fixups_header *)chainedData.bytes;
    const struct dyld_chained_import *imports =
        (const struct dyld_chained_import *)((const uint8_t *)header + header->imports_offset);
    const char *symbolPool = (const char *)header + header->symbols_offset;

    for (uint32_t i = 0; i < header->imports_count; i++) {
        const char *name = symbolPool + imports[i].name_offset;
        NSLog(@"%@ import %d: '%s'", prefix, i, name);
        if (strcmp(name, [symbolName UTF8String]) == 0) {
            foundSymbol = YES;
        }
        if (strncmp(name, [dollarPrefix UTF8String], dollarPrefix.length) == 0) {
            foundDollarVariant = YES;
        }
    }

    return @{@"found": @(foundSymbol), @"foundDollarVariant": @(foundDollarVariant)};
}

// Helper to log segment fixups structure from chained fixups data
+ (void)logSegmentFixupsFromChainedData:(NSData *)chainedData withPrefix:(NSString *)prefix {
    if (!chainedData) return;

    const struct dyld_chained_fixups_header *header =
        (const struct dyld_chained_fixups_header *)chainedData.bytes;
    const struct dyld_chained_starts_in_image *starts =
        (const struct dyld_chained_starts_in_image *)((const uint8_t *)header + header->starts_offset);

    NSLog(@"%@ starts: seg_count=%d", prefix, starts->seg_count);

    for (int i = 0; i < starts->seg_count; i++) {
        uint32_t offset = starts->seg_info_offset[i];
        if (offset != 0) {
            const struct dyld_chained_starts_in_segment *segStarts =
                (const struct dyld_chained_starts_in_segment *)((const uint8_t *)starts + offset);
            NSLog(@"%@ segment %d: size=%d page_size=0x%x pointer_format=%d segment_offset=0x%llx page_count=%d",
                  prefix, i, segStarts->size, segStarts->page_size, segStarts->pointer_format,
                  segStarts->segment_offset, segStarts->page_count);
        } else {
            NSLog(@"%@ segment %d: no fixups", prefix, i);
        }
    }
}

// Helper to log sections in a segment
+ (void)logSectionsInSegment:(MPWMachOSegment *)segment withPrefix:(NSString *)prefix {
    if (!segment) return;
    for (MPWMachOSection *section in segment.sections) {
        NSLog(@"%@ %@ section: %@", prefix, segment.name, section.sectionName);
    }
}

// Helper to find a section by name across all segments (dylibs have multiple segments)
+ (MPWMachOSection *)sectionNamed:(NSString *)sectionName inReader:(MPWMachOReader *)reader {
    for (MPWMachOSegment *segment in reader.segments) {
        MPWMachOSection *section = [segment sectionNamed:sectionName];
        if (section) {
            return section;
        }
    }
    return nil;
}

// Helper to validate __objc_classlist for N classes
+ (void)expectClassListInReader:(MPWMachOReader *)reader
                     classNames:(NSArray<NSString *> *)classNames
                          label:(NSString *)label {
    MPWMachOSection *classListSection = [self sectionNamed:@"__objc_classlist" inReader:reader];
    EXPECTNOTNIL(classListSection, ([NSString stringWithFormat:@"%@: should have __objc_classlist", label]));
    if (!classListSection) return;

    long expectedSize = (long)classNames.count * 8;
    INTEXPECT(classListSection.size, expectedSize,
              ([NSString stringWithFormat:@"%@: __objc_classlist size should be %ld", label, expectedSize]));

    // Dylibs use chained fixups; relocation entries are stripped.
    if (classListSection.size >= expectedSize) {
        const uint8_t *bytes = (const uint8_t *)reader.data.bytes + classListSection.offset;
        const uint64_t *entries = (const uint64_t *)bytes;
        for (int i = 0; i < classNames.count; i++) {
            uint64_t entry = entries[i];
            EXPECTTRUE(entry != 0,
                       ([NSString stringWithFormat:@"%@: classlist entry %d should be non-zero (fixup-encoded)", label, i]));
        }
        if (classNames.count > 1) {
            EXPECTTRUE(entries[0] != entries[1],
                       ([NSString stringWithFormat:@"%@: classlist entries should differ for distinct classes", label]));
        }
    }
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
    MPWMachOSection *stubsSection = [self findSectionNamed:@"__stubs" inSegment:textSeg];

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
        MPWMachOSection *gotSection = [self findSectionNamed:@"__got" inSegment:dataConstSeg];

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
                    // MPWFoundation is ordinal 3 (libSystem=1, libobjc=2, MPWFoundation=3)
                    INTEXPECT(imports[i].lib_ordinal, 3, @"_MPWCreateInteger should come from ordinal 3 (MPWFoundation)");
                    EXPECTTRUE(strcmp(symbolName, "_MPWCreateInteger") == 0, @"first import should be _MPWCreateInteger");
                }
            }
        }
    }

    // 5. Characterize __stubs section
    MPWMachOSegment *textSeg = [reader segmentObjectNamed:@"__TEXT"];
    EXPECTNOTNIL(textSeg, @"should have __TEXT segment");

    MPWMachOSection *stubsSection = [self findSectionNamed:@"__stubs" inSegment:textSeg];

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

    MPWMachOSection *gotSection = [self findSectionNamed:@"__got" inSegment:dataConstSeg];

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

    EXPECTTRUE([exports containsObject:@"_concatStrings"], @"should export _concatStrings");
    EXPECTFALSE([self exports:exports containSymbolWithPrefix:@"_objc_msgSend$"],
                @"should NOT export _objc_msgSend$ variants");

    // 5. Characterize chained fixups imports - should bind to _objc_msgSend (not _objc_msgSend$...)
    NSData *chainedData = [self chainedFixupsDataFromReader:reader];
    EXPECTNOTNIL(chainedData, @"should have chained fixups data");

    NSDictionary *importCheck = [self checkChainedFixupsImportsIn:chainedData
                                                        forSymbol:@"_objc_msgSend"
                                                        logPrefix:@"Reference"];
    EXPECTTRUE([importCheck[@"found"] boolValue], @"reference should import _objc_msgSend");
    EXPECTFALSE([importCheck[@"foundDollarVariant"] boolValue], @"reference should NOT import _objc_msgSend$ variants");

    // 5b. Log segment fixups structure
    [self logSegmentFixupsFromChainedData:chainedData withPrefix:@"Reference"];

    // 6. Characterize sections - should have __objc_stubs, __objc_methname, __objc_selrefs
    MPWMachOSegment *textSeg = [reader segmentObjectNamed:@"__TEXT"];
    EXPECTNOTNIL(textSeg, @"should have __TEXT");

    [self logSectionsInSegment:textSeg withPrefix:@"Reference"];
    EXPECTTRUE([self segment:textSeg hasSectionNamed:@"__objc_stubs"], @"reference should have __objc_stubs section");
    EXPECTTRUE([self segment:textSeg hasSectionNamed:@"__objc_methname"], @"reference should have __objc_methname section");

    // Check for __objc_selrefs in __DATA
    MPWMachOSegment *dataSeg = [reader segmentObjectNamed:@"__DATA"];
    [self logSectionsInSegment:dataSeg withPrefix:@"Reference"];
    EXPECTTRUE([self segment:dataSeg hasSectionNamed:@"__objc_selrefs"],
               @"reference should have __objc_selrefs section in __DATA");

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

+ (void)testCharacterizeGeneratedMessageSendDylib {
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    STNativeCompiler *compiler = [[[STNativeCompiler alloc] initWithWriter:writer] autorelease];
    NSString *path = @"/tmp/libmsgsend_gen.dylib";
    writer.installName = @"@rpath/libmsgsend.dylib";

    STObjectCodeGeneratorARM *gen = compiler.codegen;

    [compiler generateFunctionNamed:@"_concatStrings" body:^(STObjectCodeGeneratorARM * _Nonnull gen) {
        [gen generateMoveRegisterFrom:1 to:2];
        [gen generateMessageSendToSelector:@"stringByAppendingString:"];
        
        //        [codegen loadRegister:2 fromContentsOfAdressInRegister:2];
        //        [codegen generateMoveConstant:0 to:0];
    }];

//    [writer addTextSectionData:gen.generatedCode];
    [writer writeFile];
    NSData *genDylibData = [writer data];
    [genDylibData writeToFile:path atomically:YES];

    system([[NSString stringWithFormat:@"codesign -f -s - %@", path] UTF8String]);

    MPWMachOReader *reader = [MPWMachOReader readerWithData:genDylibData];
    EXPECTNOTNIL(reader, @"reader should be created");
    EXPECTTRUE([reader isHeaderValid], @"header should be valid");

    // 1. Check exports using helper - should only export _concatStrings, NOT _objc_msgSend$...
    NSArray *exports = [reader exportedSymbolNames];
    NSLog(@"Generated exports: %@", exports);

    EXPECTTRUE([exports containsObject:@"_concatStrings"], @"should export _concatStrings");
    EXPECTFALSE([self exports:exports containSymbolWithPrefix:@"_objc_msgSend$"],
                @"should NOT export _objc_msgSend$ variants");

    // 2. Check chained fixups imports using helper
    NSData *chainedData = [self chainedFixupsDataFromReader:reader];
    EXPECTNOTNIL(chainedData, @"should have chained fixups data");

    NSDictionary *importCheck = [self checkChainedFixupsImportsIn:chainedData
                                                        forSymbol:@"_objc_msgSend"
                                                        logPrefix:@"Generated"];
    EXPECTTRUE([importCheck[@"found"] boolValue], @"should import _objc_msgSend (not $variant)");
    EXPECTFALSE([importCheck[@"foundDollarVariant"] boolValue], @"should NOT import _objc_msgSend$ variants");

    // 2b. Log segment fixups structure for comparison with reference
    [self logSegmentFixupsFromChainedData:chainedData withPrefix:@"Generated"];

    // 3. Check sections using helpers - should have __objc_stubs, __objc_methname, __objc_selrefs
    MPWMachOSegment *textSeg = [reader segmentObjectNamed:@"__TEXT"];
    EXPECTNOTNIL(textSeg, @"should have __TEXT");

    [self logSectionsInSegment:textSeg withPrefix:@"Generated"];
    EXPECTTRUE([self segment:textSeg hasSectionNamed:@"__objc_stubs"],
               @"should have __objc_stubs section for objc message sends - BUG if missing");
    EXPECTTRUE([self segment:textSeg hasSectionNamed:@"__objc_methname"],
               @"should have __objc_methname section - BUG if missing");

    // Having regular __stubs is OK for non-objc external calls, but for pure objc we don't need it
    if ([self segment:textSeg hasSectionNamed:@"__stubs"] && ![self segment:textSeg hasSectionNamed:@"__objc_stubs"]) {
        NSLog(@"WARNING: Has __stubs but not __objc_stubs - wrong section type for objc");
    }

    // Check for __objc_selrefs in __DATA or __DATA_CONST
    MPWMachOSegment *dataSeg = [reader segmentObjectNamed:@"__DATA"];
    MPWMachOSegment *dataConstSeg = [reader segmentObjectNamed:@"__DATA_CONST"];

    [self logSectionsInSegment:dataSeg withPrefix:@"Generated"];
    [self logSectionsInSegment:dataConstSeg withPrefix:@"Generated"];

    BOOL hasObjcSelrefs = [self segment:dataSeg hasSectionNamed:@"__objc_selrefs"] ||
                          [self segment:dataConstSeg hasSectionNamed:@"__objc_selrefs"];
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

// Characterization test: Create reference dylib with constant NSString using ObjSTNative object file
// linked with external linker. Documents structure for comparison with our generated version.
+ (void)testCharacterizeReferenceConstantStringDylib {
    // 1. Generate object file with constant string using MPWMachOWriter
    STNativeCompiler *compiler = [STNativeCompiler compiler];
    MPWMachOWriter *objectWriter = compiler.writer;
    NSString *tempDir = @"/tmp";
    NSString *objectPath = [tempDir stringByAppendingPathComponent:@"conststring_ref.o"];
    NSString *dylibPath = [tempDir stringByAppendingPathComponent:@"conststring_ref.dylib"];

    STObjectCodeGeneratorARM *gen = compiler.codegen;

    [compiler generateFunctionNamed:@"_returnString" body:^(STObjectCodeGeneratorARM * _Nonnull gen) {
        [compiler generateStringLiteral:@"Test String"];
    }];

    [objectWriter addTextSectionData:(NSData*)gen.generatedCode];
    [objectWriter writeFile];
    [objectWriter.data writeToFile:objectPath atomically:YES];

    // 2. Link with external linker
    int linkResult = [compiler linkObjects:@[@"conststring_ref"]
                           toSharedLibrary:@"conststring_ref.dylib"
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

    // 4. Characterize segments
    NSArray *segments = [reader segments];
    NSLog(@"Reference constant string dylib has %lu segments", (unsigned long)segments.count);
    for (MPWMachOSegment *seg in segments) {
        NSLog(@"Reference segment: %@ vmaddr=0x%lx vmsize=0x%lx fileoff=0x%lx filesize=0x%lx",
              seg.name, seg.vmaddr, seg.vmsize, seg.fileoff, seg.filesize);
        for (MPWMachOSection *section in seg.sections) {
            NSLog(@"  Reference section: %@ addr=0x%llx size=0x%llx offset=0x%lx",
                  section.sectionName, section.address, (unsigned long long)section.size, section.offset);
        }
    }

    // 5. Check for __string section (constant NSString data - struct with isa, flags, cstring ptr, length)
    MPWMachOSegment *dataSeg = [reader segmentObjectNamed:@"__DATA"];
    MPWMachOSegment *dataConstSeg = [reader segmentObjectNamed:@"__DATA_CONST"];

    BOOL hasStringSection = [self segment:dataSeg hasSectionNamed:@"__string"];
    EXPECTTRUE(hasStringSection, @"reference should have __string section in __DATA");

    // 6. Check for cstring section (string content)
    MPWMachOSegment *textSeg = [reader segmentObjectNamed:@"__TEXT"];
    BOOL hasCstring = [self segment:textSeg hasSectionNamed:@"__cstring"];
    EXPECTTRUE(hasCstring, @"reference should have __cstring section in __TEXT");

    // 7. CRITICAL: Check section relocation fields - dylibs should NOT have section-level relocations
    // (they use chained fixups instead). This was the nm error about "relocation entries at offset 0"
    MPWMachOSection *stringSection = [self findSectionNamed:@"__string" inSegment:dataSeg];
    if (stringSection) {
        NSLog(@"Reference __string section: relocEntryOffset=%d numRelocEntries=%d",
              stringSection.relocEntryOffset, stringSection.numRelocEntries);
        INTEXPECT(stringSection.relocEntryOffset, 0, @"reference __string section should have reloff=0");
        INTEXPECT(stringSection.numRelocEntries, 0, @"reference __string section should have nreloc=0");
    }

    // 8. Check chained fixups for ___CFConstantStringClassReference import
    NSData *chainedData = [self chainedFixupsDataFromReader:reader];
    EXPECTNOTNIL(chainedData, @"should have chained fixups data");

    NSDictionary *importCheck = [self checkChainedFixupsImportsIn:chainedData
                                                        forSymbol:@"___CFConstantStringClassReference"
                                                        logPrefix:@"Reference"];
    EXPECTTRUE([importCheck[@"found"] boolValue], @"reference should import ___CFConstantStringClassReference");

    // 9. Log segment fixups structure
    [self logSegmentFixupsFromChainedData:chainedData withPrefix:@"Reference"];

    // 9. Test that reference dylib actually loads
    void *handle = dlopen([dylibPath UTF8String], RTLD_NOW);
    EXPECTNOTNIL(handle, @"reference dylib should load");
    if (handle) {
        id (*returnString)(void) = dlsym(handle, "returnString");
        EXPECTNOTNIL(returnString, @"should find returnString");
        if (returnString) {
            NSString *result = returnString();
            IDEXPECT(result, @"Test String", @"reference should return correct string");
        }
        dlclose(handle);
    }

    // Cleanup temp files
    [[NSFileManager defaultManager] removeItemAtPath:objectPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:dylibPath error:nil];
}

// Characterization test: Check the generated constant string dylib structure
// and compare against reference to find differences
+ (void)testCharacterizeGeneratedConstantStringDylib {
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    STNativeCompiler *compiler = [[[STNativeCompiler alloc] initWithWriter:writer] autorelease];
    NSString *path = @"/tmp/libconststring_gen.dylib";
    writer.installName = @"@rpath/libconststring.dylib";

    STObjectCodeGeneratorARM *gen = compiler.codegen;

    [compiler generateFunctionNamed:@"_returnString" body:^(STObjectCodeGeneratorARM * _Nonnull gen) {
        [compiler generateStringLiteral:@"Test String"];
    }];

    [writer addTextSectionData:gen.generatedCode];
    [writer writeFile];
    NSData *genDylibData = [writer data];
    [genDylibData writeToFile:path atomically:YES];

    system([[NSString stringWithFormat:@"codesign -f -s - %@", path] UTF8String]);

    MPWMachOReader *reader = [MPWMachOReader readerWithData:genDylibData];
    EXPECTNOTNIL(reader, @"reader should be created");
    EXPECTTRUE([reader isHeaderValid], @"header should be valid");

    // 1. Characterize segments
    NSArray *segments = [reader segments];
    NSLog(@"Generated constant string dylib has %lu segments", (unsigned long)segments.count);
    for (MPWMachOSegment *seg in segments) {
        NSLog(@"Generated segment: %@ vmaddr=0x%lx vmsize=0x%lx fileoff=0x%lx filesize=0x%lx",
              seg.name, seg.vmaddr, seg.vmsize, seg.fileoff, seg.filesize);
        for (MPWMachOSection *section in seg.sections) {
            NSLog(@"  Generated section: %@ addr=0x%llx size=0x%llx offset=0x%lx",
                  section.sectionName, section.address, (unsigned long long)section.size, section.offset);
        }
    }

    // 2. Check for __string section (constant NSString data)
    MPWMachOSegment *dataSeg = [reader segmentObjectNamed:@"__DATA"];
    MPWMachOSegment *dataConstSeg = [reader segmentObjectNamed:@"__DATA_CONST"];

    BOOL hasStringSection = [self segment:dataSeg hasSectionNamed:@"__string"];
    [self logSectionsInSegment:dataSeg withPrefix:@"Generated"];
    [self logSectionsInSegment:dataConstSeg withPrefix:@"Generated"];

    EXPECTTRUE(hasStringSection, @"generated should have __string section in __DATA - BUG if missing");

    // 3. CRITICAL: Check section relocation fields - dylibs should NOT have section-level relocations
    // This is the nm error: "section relocation entries at offset 0 with a size of 16"
    MPWMachOSection *stringSection = [self findSectionNamed:@"__string" inSegment:dataSeg];
    if (stringSection) {
        NSLog(@"Generated __string section: relocEntryOffset=%d numRelocEntries=%d",
              stringSection.relocEntryOffset, stringSection.numRelocEntries);
        INTEXPECT(stringSection.relocEntryOffset, 0, @"generated __string section should have reloff=0 - BUG if nonzero");
        INTEXPECT(stringSection.numRelocEntries, 0, @"generated __string section should have nreloc=0 - BUG if nonzero");
    }

    // 4. Check for cstring section
    MPWMachOSegment *textSeg = [reader segmentObjectNamed:@"__TEXT"];
    [self logSectionsInSegment:textSeg withPrefix:@"Generated"];
    BOOL hasCstring = [self segment:textSeg hasSectionNamed:@"__cstring"];
    EXPECTTRUE(hasCstring, @"generated should have __cstring section - BUG if missing");

    // 5. Check chained fixups for ___CFConstantStringClassReference import
    NSData *chainedData = [self chainedFixupsDataFromReader:reader];
    EXPECTNOTNIL(chainedData, @"should have chained fixups data");

    NSDictionary *importCheck = [self checkChainedFixupsImportsIn:chainedData
                                                        forSymbol:@"___CFConstantStringClassReference"
                                                        logPrefix:@"Generated"];
    EXPECTTRUE([importCheck[@"found"] boolValue], @"generated should import ___CFConstantStringClassReference - BUG if missing");

    // 6. Log segment fixups structure
    [self logSegmentFixupsFromChainedData:chainedData withPrefix:@"Generated"];

    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

// Characterization test: Examine a known-good framework containing a constant NSArray
// and document the relevant sections/imports.
+ (void)testCharacterizeReferenceConstArrayFramework {
    NSURL *frameworkURL = [[NSBundle bundleForClass:self] URLForResource:@"ConstArray" withExtension:@"framework"];
    EXPECTNOTNIL(frameworkURL, @"ConstArray framework URL");
    if (!frameworkURL) return;

    NSBundle *frameworkBundle = [NSBundle bundleWithURL:frameworkURL];
    EXPECTNOTNIL(frameworkBundle, @"ConstArray framework bundle");
    NSURL *executableURL = [frameworkBundle executableURL];
    EXPECTNOTNIL(executableURL, @"ConstArray framework executable URL");
    if (!executableURL) return;

    NSData *refData = [NSData dataWithContentsOfURL:executableURL];
    EXPECTNOTNIL(refData, @"ConstArray framework data");
    if (!refData) return;

    MPWMachOReader *reader = [MPWMachOReader readerWithData:refData];
    EXPECTNOTNIL(reader, @"reader should be created");
    EXPECTTRUE([reader isHeaderValid], @"header should be valid");

    MPWMachOSegment *textSeg = [reader segmentObjectNamed:@"__TEXT"];
    MPWMachOSegment *dataSeg = [reader segmentObjectNamed:@"__DATA"];
    MPWMachOSegment *dataConstSeg = [reader segmentObjectNamed:@"__DATA_CONST"];

    [self logSectionsInSegment:textSeg withPrefix:@"Reference"];
    [self logSectionsInSegment:dataSeg withPrefix:@"Reference"];
    [self logSectionsInSegment:dataConstSeg withPrefix:@"Reference"];

    BOOL hasArrayData = [self segment:dataConstSeg hasSectionNamed:@"__objc_arraydata"];
    BOOL hasArrayObj = [self segment:dataConstSeg hasSectionNamed:@"__objc_arrayobj"];
    EXPECTTRUE(hasArrayData, @"reference should have __objc_arraydata in __DATA_CONST");
    EXPECTTRUE(hasArrayObj, @"reference should have __objc_arrayobj in __DATA_CONST");

    NSData *chainedData = [self chainedFixupsDataFromReader:reader];
    EXPECTNOTNIL(chainedData, @"reference should have chained fixups data");

    NSDictionary *arrayImport = [self checkChainedFixupsImportsIn:chainedData
                                                        forSymbol:@"_OBJC_CLASS_$_NSConstantArray"
                                                        logPrefix:@"Reference"];
    EXPECTTRUE([arrayImport[@"found"] boolValue], @"reference should import _OBJC_CLASS_$_NSConstantArray");
}

// Characterization test: Examine the generated literal-object dylib structure
// without dlopen, to compare against the reference framework.
+ (void)testCharacterizeGeneratedLiteralObjectsDylib {
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    writer.installName = @"@rpath/libliteralobjects.dylib";
    [writer.frameworks addObject:@"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation"];
    [writer.frameworks addObject:@"/System/Library/Frameworks/CoreFoundation.framework/Versions/Current/CoreFoundation"];

    MPWMachOObjectSerializer *serializer = [[[MPWMachOObjectSerializer alloc] initWithWriter:writer] autorelease];

    NSArray *arrayLiteral = @[ @"string1", @"string2" ];

    [serializer symbolForObject:arrayLiteral];

    MPWMachOSectionWriter *dataWriter = [writer addSectionWriterWithSegName:@"__DATA"
                                                                   sectName:@"__data"
                                                                      flags:0];
    uint64_t zero = 0;
    [dataWriter declareGlobalSymbol:@"_literal_nsarray_test"];
    [dataWriter addRelocationEntryForSymbol:[serializer symbolForObject:arrayLiteral]
                                   atOffset:(int)dataWriter.length];
    [dataWriter appendBytes:&zero length:sizeof(zero)];

    [writer writeFile];
    NSData *genData = [writer data];
    EXPECTNOTNIL(genData, @"generated dylib data");
    if (!genData) return;

    MPWMachOReader *reader = [MPWMachOReader readerWithData:genData];
    EXPECTNOTNIL(reader, @"reader should be created");
    EXPECTTRUE([reader isHeaderValid], @"header should be valid");

    MPWMachOSegment *textSeg = [reader segmentObjectNamed:@"__TEXT"];
    MPWMachOSegment *dataSeg = [reader segmentObjectNamed:@"__DATA"];
    MPWMachOSegment *dataConstSeg = [reader segmentObjectNamed:@"__DATA_CONST"];

    [self logSectionsInSegment:textSeg withPrefix:@"Generated"];
    [self logSectionsInSegment:dataSeg withPrefix:@"Generated"];
    [self logSectionsInSegment:dataConstSeg withPrefix:@"Generated"];

    BOOL hasArrayData = [self segment:dataConstSeg hasSectionNamed:@"__objc_arraydata"];
    BOOL hasArrayObj = [self segment:dataConstSeg hasSectionNamed:@"__objc_arrayobj"];
    EXPECTTRUE(hasArrayData, @"generated should have __objc_arraydata in __DATA_CONST");
    EXPECTTRUE(hasArrayObj, @"generated should have __objc_arrayobj in __DATA_CONST");

    NSData *chainedData = [self chainedFixupsDataFromReader:reader];
    EXPECTNOTNIL(chainedData, @"generated should have chained fixups data");

    NSDictionary *arrayImport = [self checkChainedFixupsImportsIn:chainedData
                                                        forSymbol:@"_OBJC_CLASS_$_NSConstantArray"
                                                        logPrefix:@"Generated"];
    EXPECTTRUE([arrayImport[@"found"] boolValue], @"generated should import _OBJC_CLASS_$_NSConstantArray");
}

// Detailed binary comparison test: Compare __string section content byte-by-byte
// to find exact differences causing "out of range bind ordinal" error
+ (void)testCompareConstantStringBinaryContent {
    // 1. Generate REFERENCE dylib using external linker
    STNativeCompiler *refCompiler = [STNativeCompiler compiler];
    MPWMachOWriter *objectWriter = refCompiler.writer;
    NSString *tempDir = @"/tmp";
    NSString *objectPath = [tempDir stringByAppendingPathComponent:@"conststring_bincompare.o"];
    NSString *refDylibPath = [tempDir stringByAppendingPathComponent:@"conststring_bincompare_ref.dylib"];

    STObjectCodeGeneratorARM *refGen = refCompiler.codegen;
    [refCompiler generateFunctionNamed:@"_returnString" body:^(STObjectCodeGeneratorARM * _Nonnull gen) {
        [refCompiler generateStringLiteral:@"Test String"];
    }];

    [objectWriter addTextSectionData:(NSData*)refGen.generatedCode];
    [objectWriter writeFile];
    [objectWriter.data writeToFile:objectPath atomically:YES];

    int linkResult = [refCompiler linkObjects:@[@"conststring_bincompare"]
                           toSharedLibrary:@"conststring_bincompare_ref.dylib"
                                     inDir:tempDir
                            withFrameworks:@[@"Foundation"]];
    INTEXPECT(linkResult, 0, @"external linker should succeed");
    system([[NSString stringWithFormat:@"codesign -f -s - %@", refDylibPath] UTF8String]);

    NSData *refDylibData = [NSData dataWithContentsOfFile:refDylibPath];
    EXPECTNOTNIL(refDylibData, @"reference dylib should exist");
    MPWMachOReader *refReader = [MPWMachOReader readerWithData:refDylibData];

    // 2. Generate CANDIDATE dylib using MPWMachODylibWriter
    MPWMachODylibWriter *genWriter = [MPWMachODylibWriter stream];
    STNativeCompiler *genCompiler = [[[STNativeCompiler alloc] initWithWriter:genWriter] autorelease];
    genWriter.installName = @"@rpath/libconststring.dylib";
    [genWriter.frameworks addObject:@"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation"];

    STObjectCodeGeneratorARM *genGen = genCompiler.codegen;
    [genCompiler generateFunctionNamed:@"_returnString" body:^(STObjectCodeGeneratorARM * _Nonnull gen) {
        [genCompiler generateStringLiteral:@"Test String"];
    }];

    [genWriter addTextSectionData:genGen.generatedCode];
    [genWriter writeFile];
    NSData *genDylibData = [genWriter data];

    NSString *genDylibPath = [tempDir stringByAppendingPathComponent:@"conststring_bincompare_gen.dylib"];
    [genDylibData writeToFile:genDylibPath atomically:YES];
    system([[NSString stringWithFormat:@"codesign -f -s - %@", genDylibPath] UTF8String]);

    MPWMachOReader *genReader = [MPWMachOReader readerWithData:genDylibData];

    // 3. Find __string section in both
    MPWMachOSegment *refDataSeg = [refReader segmentObjectNamed:@"__DATA"];
    MPWMachOSegment *genDataSeg = [genReader segmentObjectNamed:@"__DATA"];

    EXPECTNOTNIL(refDataSeg, @"reference should have __DATA segment");
    EXPECTNOTNIL(genDataSeg, @"generated should have __DATA segment");

    MPWMachOSection *refStringSection = [self findSectionNamed:@"__string" inSegment:refDataSeg];
    MPWMachOSection *genStringSection = [self findSectionNamed:@"__string" inSegment:genDataSeg];

    EXPECTNOTNIL(refStringSection, @"reference should have __string section");
    EXPECTNOTNIL(genStringSection, @"generated should have __string section");

    // 4. Dump __string section binary content
    NSLog(@"=== __STRING SECTION BINARY COMPARISON ===");
    NSLog(@"Reference __string: addr=0x%llx size=%lld offset=0x%lx",
          refStringSection.address, (unsigned long long)refStringSection.size, refStringSection.offset);
    NSLog(@"Generated __string: addr=0x%llx size=%lld offset=0x%lx",
          genStringSection.address, (unsigned long long)genStringSection.size, genStringSection.offset);

    // NSString constant structure: isa (8 bytes), flags (8 bytes), cstring ptr (8 bytes), length (8 bytes) = 32 bytes
    INTEXPECT(refStringSection.size, 32, @"reference __string should be 32 bytes");
    INTEXPECT(genStringSection.size, 32, @"generated __string should be 32 bytes");

    const uint64_t *refPtrs = (const uint64_t *)(refDylibData.bytes + refStringSection.offset);
    const uint64_t *genPtrs = (const uint64_t *)(genDylibData.bytes + genStringSection.offset);

    NSLog(@"Reference __string content (4 qwords):");
    for (int i = 0; i < 4; i++) {
        NSLog(@"  [%d] 0x%016llx", i, refPtrs[i]);
    }

    NSLog(@"Generated __string content (4 qwords):");
    for (int i = 0; i < 4; i++) {
        NSLog(@"  [%d] 0x%016llx", i, genPtrs[i]);
    }

    // 5. CRITICAL: Compare the bind pointer (first qword = isa pointer to ___CFConstantStringClassReference)
    // This should be encoded as a chained fixup bind entry
    // Format for DYLD_CHAINED_PTR_64_OFFSET bind: ordinal:24, addend:8, reserved:19, next:12, bind:1
    uint64_t refIsa = refPtrs[0];
    uint64_t genIsa = genPtrs[0];

    // Decode bind entry
    NSLog(@"=== BIND ENTRY ANALYSIS (isa pointer) ===");
    NSLog(@"Reference isa raw: 0x%016llx", refIsa);
    NSLog(@"Generated isa raw: 0x%016llx", genIsa);

    // Extract bind fields: bind bit is bit 63
    BOOL refIsBind = (refIsa >> 63) & 1;
    BOOL genIsBind = (genIsa >> 63) & 1;
    NSLog(@"Reference is_bind: %d", refIsBind);
    NSLog(@"Generated is_bind: %d", genIsBind);

    if (refIsBind) {
        // For DYLD_CHAINED_PTR_64_OFFSET bind format:
        // bits 0-23: ordinal (24 bits)
        // bits 24-31: addend (8 bits)
        // bits 32-50: reserved (19 bits)
        // bits 51-62: next/4 (12 bits)
        // bit 63: bind (1 bit)
        uint32_t refOrdinal = refIsa & 0xFFFFFF;
        uint8_t refAddend = (refIsa >> 24) & 0xFF;
        uint32_t refNext = (refIsa >> 51) & 0xFFF;
        NSLog(@"Reference bind: ordinal=%u addend=%u next=%u", refOrdinal, refAddend, refNext);
    }

    if (genIsBind) {
        uint32_t genOrdinal = genIsa & 0xFFFFFF;
        uint8_t genAddend = (genIsa >> 24) & 0xFF;
        uint32_t genNext = (genIsa >> 51) & 0xFFF;
        NSLog(@"Generated bind: ordinal=%u addend=%u next=%u", genOrdinal, genAddend, genNext);
    }

    // 6. Compare the cstring pointer (third qword) - this should be a rebase
    uint64_t refCstring = refPtrs[2];
    uint64_t genCstring = genPtrs[2];

    NSLog(@"=== REBASE ENTRY ANALYSIS (cstring pointer) ===");
    NSLog(@"Reference cstring raw: 0x%016llx", refCstring);
    NSLog(@"Generated cstring raw: 0x%016llx", genCstring);

    BOOL refCstringIsBind = (refCstring >> 63) & 1;
    BOOL genCstringIsBind = (genCstring >> 63) & 1;
    NSLog(@"Reference cstring is_bind: %d (should be 0 for rebase)", refCstringIsBind);
    NSLog(@"Generated cstring is_bind: %d (should be 0 for rebase)", genCstringIsBind);

    if (!refCstringIsBind) {
        // For DYLD_CHAINED_PTR_64_OFFSET rebase format:
        // bits 0-35: target (36 bits)
        // bits 36-43: high8 (8 bits)
        // bits 44-50: reserved (7 bits)
        // bits 51-62: next/4 (12 bits)
        // bit 63: bind (1 bit, 0 for rebase)
        uint64_t refTarget = refCstring & 0xFFFFFFFFFULL;
        uint8_t refHigh8 = (refCstring >> 36) & 0xFF;
        uint32_t refNext = (refCstring >> 51) & 0xFFF;
        NSLog(@"Reference rebase: target=0x%llx high8=0x%02x next=%u", refTarget, refHigh8, refNext);
    }

    if (!genCstringIsBind) {
        uint64_t genTarget = genCstring & 0xFFFFFFFFFULL;
        uint8_t genHigh8 = (genCstring >> 36) & 0xFF;
        uint32_t genNext = (genCstring >> 51) & 0xFFF;
        NSLog(@"Generated rebase: target=0x%llx high8=0x%02x next=%u", genTarget, genHigh8, genNext);
    }

    // 7. Compare chained fixups header
    NSData *refChainedData = [self chainedFixupsDataFromReader:refReader];
    NSData *genChainedData = [self chainedFixupsDataFromReader:genReader];

    EXPECTNOTNIL(refChainedData, @"reference should have chained fixups");
    EXPECTNOTNIL(genChainedData, @"generated should have chained fixups");

    const struct dyld_chained_fixups_header *refHeader =
        (const struct dyld_chained_fixups_header *)refChainedData.bytes;
    const struct dyld_chained_fixups_header *genHeader =
        (const struct dyld_chained_fixups_header *)genChainedData.bytes;

    NSLog(@"=== CHAINED FIXUPS HEADER COMPARISON ===");
    NSLog(@"Reference: version=%d starts=%u imports=%u symbols=%u imports_count=%u imports_format=%d",
          refHeader->fixups_version, refHeader->starts_offset, refHeader->imports_offset,
          refHeader->symbols_offset, refHeader->imports_count, refHeader->imports_format);
    NSLog(@"Generated: version=%d starts=%u imports=%u symbols=%u imports_count=%u imports_format=%d",
          genHeader->fixups_version, genHeader->starts_offset, genHeader->imports_offset,
          genHeader->symbols_offset, genHeader->imports_count, genHeader->imports_format);

    // 8. Compare imports
    NSLog(@"=== IMPORTS COMPARISON ===");
    const struct dyld_chained_import *refImports =
        (const struct dyld_chained_import *)(refChainedData.bytes + refHeader->imports_offset);
    const struct dyld_chained_import *genImports =
        (const struct dyld_chained_import *)(genChainedData.bytes + genHeader->imports_offset);
    const char *refSymbols = (const char *)(refChainedData.bytes + refHeader->symbols_offset);
    const char *genSymbols = (const char *)(genChainedData.bytes + genHeader->symbols_offset);

    for (uint32_t i = 0; i < refHeader->imports_count; i++) {
        NSLog(@"Reference import[%u]: lib_ordinal=%u weak=%u name='%s'",
              i, refImports[i].lib_ordinal, refImports[i].weak_import,
              refSymbols + refImports[i].name_offset);
    }

    for (uint32_t i = 0; i < genHeader->imports_count; i++) {
        NSLog(@"Generated import[%u]: lib_ordinal=%u weak=%u name='%s'",
              i, genImports[i].lib_ordinal, genImports[i].weak_import,
              genSymbols + genImports[i].name_offset);
    }

    // 9. Compare starts_in_segment for __DATA segment
    NSLog(@"=== SEGMENT FIXUPS COMPARISON ===");
    const struct dyld_chained_starts_in_image *refStarts =
        (const struct dyld_chained_starts_in_image *)(refChainedData.bytes + refHeader->starts_offset);
    const struct dyld_chained_starts_in_image *genStarts =
        (const struct dyld_chained_starts_in_image *)(genChainedData.bytes + genHeader->starts_offset);

    NSLog(@"Reference seg_count=%d, Generated seg_count=%d", refStarts->seg_count, genStarts->seg_count);

    for (int i = 0; i < refStarts->seg_count; i++) {
        uint32_t refOffset = refStarts->seg_info_offset[i];
        uint32_t genOffset = (i < genStarts->seg_count) ? genStarts->seg_info_offset[i] : 0;

        NSLog(@"Segment %d: ref_offset=%u gen_offset=%u", i, refOffset, genOffset);

        if (refOffset != 0) {
            const struct dyld_chained_starts_in_segment *refSegStarts =
                (const struct dyld_chained_starts_in_segment *)(refChainedData.bytes + refHeader->starts_offset + refOffset);
            NSLog(@"  Reference: size=%u page_size=0x%x pointer_format=%u segment_offset=0x%llx page_count=%u",
                  refSegStarts->size, refSegStarts->page_size, refSegStarts->pointer_format,
                  refSegStarts->segment_offset, refSegStarts->page_count);

            for (int p = 0; p < refSegStarts->page_count; p++) {
                uint16_t pageStart = refSegStarts->page_start[p];
                if (pageStart != DYLD_CHAINED_PTR_START_NONE) {
                    NSLog(@"    Page %d: start=0x%x", p, pageStart);
                }
            }
        }

        if (genOffset != 0 && i < genStarts->seg_count) {
            const struct dyld_chained_starts_in_segment *genSegStarts =
                (const struct dyld_chained_starts_in_segment *)(genChainedData.bytes + genHeader->starts_offset + genOffset);
            NSLog(@"  Generated: size=%u page_size=0x%x pointer_format=%u segment_offset=0x%llx page_count=%u",
                  genSegStarts->size, genSegStarts->page_size, genSegStarts->pointer_format,
                  genSegStarts->segment_offset, genSegStarts->page_count);

            for (int p = 0; p < genSegStarts->page_count; p++) {
                uint16_t pageStart = genSegStarts->page_start[p];
                if (pageStart != DYLD_CHAINED_PTR_START_NONE) {
                    NSLog(@"    Page %d: start=0x%x", p, pageStart);
                }
            }
        }
    }

    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:objectPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:refDylibPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:genDylibPath error:nil];
}

// Compare __objc_arrayobj and __objc_arraydata sections between the known-good framework
// and our generated literal-object dylib to pinpoint fixup encoding differences.
+ (void)testCompareConstArrayBinaryContent {
    // 1. Load reference framework executable
    NSURL *frameworkURL = [[NSBundle bundleForClass:self] URLForResource:@"ConstArray" withExtension:@"framework"];
    EXPECTNOTNIL(frameworkURL, @"ConstArray framework URL");
    if (!frameworkURL) return;

    NSBundle *frameworkBundle = [NSBundle bundleWithURL:frameworkURL];
    EXPECTNOTNIL(frameworkBundle, @"ConstArray framework bundle");
    NSURL *executableURL = [frameworkBundle executableURL];
    EXPECTNOTNIL(executableURL, @"ConstArray executable URL");
    if (!executableURL) return;

    NSData *refData = [NSData dataWithContentsOfURL:executableURL];
    EXPECTNOTNIL(refData, @"reference framework data");
    if (!refData) return;

    MPWMachOReader *refReader = [MPWMachOReader readerWithData:refData];
    EXPECTNOTNIL(refReader, @"ref reader should be created");
    EXPECTTRUE([refReader isHeaderValid], @"ref header should be valid");

    // 2. Generate literal-object dylib (array only)
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    writer.installName = @"@rpath/libliteralobjects.dylib";
    [writer.frameworks addObject:@"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation"];
    [writer.frameworks addObject:@"/System/Library/Frameworks/CoreFoundation.framework/Versions/Current/CoreFoundation"];

    MPWMachOObjectSerializer *serializer = [[[MPWMachOObjectSerializer alloc] initWithWriter:writer] autorelease];
    NSArray *arrayLiteral = @[ @"string1", @"string2" ];

    [serializer symbolForObject:arrayLiteral];

    MPWMachOSectionWriter *dataWriter = [writer addSectionWriterWithSegName:@"__DATA"
                                                                   sectName:@"__data"
                                                                      flags:0];
    uint64_t zero = 0;
    [dataWriter declareGlobalSymbol:@"_literal_nsarray_test"];
    [dataWriter addRelocationEntryForSymbol:[serializer symbolForObject:arrayLiteral]
                                   atOffset:(int)dataWriter.length];
    [dataWriter appendBytes:&zero length:sizeof(zero)];

    [writer writeFile];
    NSData *genData = [writer data];
    EXPECTNOTNIL(genData, @"generated dylib data");
    if (!genData) return;

    MPWMachOReader *genReader = [MPWMachOReader readerWithData:genData];
    EXPECTNOTNIL(genReader, @"gen reader should be created");
    EXPECTTRUE([genReader isHeaderValid], @"gen header should be valid");

    // 3. Find __objc_arrayobj / __objc_arraydata sections
    MPWMachOSegment *refDataConst = [refReader segmentObjectNamed:@"__DATA_CONST"];
    MPWMachOSegment *genDataConst = [genReader segmentObjectNamed:@"__DATA_CONST"];
    EXPECTNOTNIL(refDataConst, @"reference should have __DATA_CONST");
    EXPECTNOTNIL(genDataConst, @"generated should have __DATA_CONST");
    if (!refDataConst || !genDataConst) return;

    MPWMachOSection *refArrayObj = [self findSectionNamed:@"__objc_arrayobj" inSegment:refDataConst];
    MPWMachOSection *refArrayData = [self findSectionNamed:@"__objc_arraydata" inSegment:refDataConst];
    MPWMachOSection *genArrayObj = [self findSectionNamed:@"__objc_arrayobj" inSegment:genDataConst];
    MPWMachOSection *genArrayData = [self findSectionNamed:@"__objc_arraydata" inSegment:genDataConst];

    EXPECTNOTNIL(refArrayObj, @"reference should have __objc_arrayobj");
    EXPECTNOTNIL(refArrayData, @"reference should have __objc_arraydata");
    EXPECTNOTNIL(genArrayObj, @"generated should have __objc_arrayobj");
    EXPECTNOTNIL(genArrayData, @"generated should have __objc_arraydata");
    if (!refArrayObj || !refArrayData || !genArrayObj || !genArrayData) return;

    // 4. Dump sizes and first few qwords
    NSLog(@"=== __OBJC_ARRAYOBJ SECTION COMPARISON ===");
    NSLog(@"Reference __objc_arrayobj: addr=0x%llx size=%lld offset=0x%lx",
          refArrayObj.address, (unsigned long long)refArrayObj.size, refArrayObj.offset);
    NSLog(@"Generated __objc_arrayobj: addr=0x%llx size=%lld offset=0x%lx",
          genArrayObj.address, (unsigned long long)genArrayObj.size, genArrayObj.offset);

    EXPECTTRUE(refArrayObj.size >= 24, @"reference arrayobj should be at least 24 bytes");
    EXPECTTRUE(genArrayObj.size >= 24, @"generated arrayobj should be at least 24 bytes");

    const uint64_t *refArrayObjQ = (const uint64_t *)(refData.bytes + refArrayObj.offset);
    const uint64_t *genArrayObjQ = (const uint64_t *)(genData.bytes + genArrayObj.offset);

    for (int i = 0; i < 3; i++) {
        NSLog(@"  Reference arrayobj[%d] = 0x%016llx", i, refArrayObjQ[i]);
    }
    for (int i = 0; i < 3; i++) {
        NSLog(@"  Generated arrayobj[%d] = 0x%016llx", i, genArrayObjQ[i]);
    }

    // 5. Validate array count
    INTEXPECT((int)refArrayObjQ[1], 2, @"reference array count should be 2");
    INTEXPECT((int)genArrayObjQ[1], 2, @"generated array count should be 2");

    // 6. Decode isa bind entry (first qword)
    uint64_t refIsa = refArrayObjQ[0];
    uint64_t genIsa = genArrayObjQ[0];
    BOOL refIsBind = (refIsa >> 63) & 1;
    BOOL genIsBind = (genIsa >> 63) & 1;
    EXPECTTRUE(refIsBind, @"reference isa should be a bind");
    EXPECTTRUE(genIsBind, @"generated isa should be a bind");

    if (refIsBind) {
        uint32_t refOrdinal = refIsa & 0xFFFFFF;
        NSLog(@"Reference isa bind ordinal=%u", refOrdinal);
        NSData *refChained = [self chainedFixupsDataFromReader:refReader];
        const struct dyld_chained_fixups_header *refHeader =
            (const struct dyld_chained_fixups_header *)refChained.bytes;
        EXPECTTRUE(refOrdinal < refHeader->imports_count, @"reference isa bind ordinal in range");
    }
    if (genIsBind) {
        uint32_t genOrdinal = genIsa & 0xFFFFFF;
        NSLog(@"Generated isa bind ordinal=%u", genOrdinal);
        NSData *genChained = [self chainedFixupsDataFromReader:genReader];
        const struct dyld_chained_fixups_header *genHeader =
            (const struct dyld_chained_fixups_header *)genChained.bytes;
        EXPECTTRUE(genOrdinal < genHeader->imports_count, @"generated isa bind ordinal in range");
    }

    // 7. Validate objects pointer and arraydata entries are rebases (bind bit = 0)
    uint64_t refObjectsPtr = refArrayObjQ[2];
    uint64_t genObjectsPtr = genArrayObjQ[2];
    EXPECTTRUE(((refObjectsPtr >> 63) & 1) == 0, @"reference objects pointer should be rebase");
    EXPECTTRUE(((genObjectsPtr >> 63) & 1) == 0, @"generated objects pointer should be rebase");

    NSLog(@"=== __OBJC_ARRAYDATA SECTION COMPARISON ===");
    NSLog(@"Reference __objc_arraydata: addr=0x%llx size=%lld offset=0x%lx",
          refArrayData.address, (unsigned long long)refArrayData.size, refArrayData.offset);
    NSLog(@"Generated __objc_arraydata: addr=0x%llx size=%lld offset=0x%lx",
          genArrayData.address, (unsigned long long)genArrayData.size, genArrayData.offset);

    EXPECTTRUE(refArrayData.size >= 16, @"reference arraydata should be at least 16 bytes");
    EXPECTTRUE(genArrayData.size >= 16, @"generated arraydata should be at least 16 bytes");

    const uint64_t *refArrayDataQ = (const uint64_t *)(refData.bytes + refArrayData.offset);
    const uint64_t *genArrayDataQ = (const uint64_t *)(genData.bytes + genArrayData.offset);

    for (int i = 0; i < 2; i++) {
        NSLog(@"  Reference arraydata[%d] = 0x%016llx", i, refArrayDataQ[i]);
    }
    for (int i = 0; i < 2; i++) {
        NSLog(@"  Generated arraydata[%d] = 0x%016llx", i, genArrayDataQ[i]);
    }

    EXPECTTRUE(((refArrayDataQ[0] >> 63) & 1) == 0, @"reference arraydata[0] should be rebase");
    EXPECTTRUE(((refArrayDataQ[1] >> 63) & 1) == 0, @"reference arraydata[1] should be rebase");
    EXPECTTRUE(((genArrayDataQ[0] >> 63) & 1) == 0, @"generated arraydata[0] should be rebase");
    EXPECTTRUE(((genArrayDataQ[1] >> 63) & 1) == 0, @"generated arraydata[1] should be rebase");
}

// NEW: Compare nm output between reference and generated to find symbol table differences
+ (void)testCompareSymbolTablesBetweenRefAndGenerated {
    // 1. Generate REFERENCE dylib using external linker
    STNativeCompiler *refCompiler = [STNativeCompiler compiler];
    MPWMachOWriter *objectWriter = refCompiler.writer;
    NSString *tempDir = @"/tmp";
    NSString *objectPath = [tempDir stringByAppendingPathComponent:@"conststring_symcompare.o"];
    NSString *refDylibPath = [tempDir stringByAppendingPathComponent:@"conststring_symcompare_ref.dylib"];

    STObjectCodeGeneratorARM *refGen = refCompiler.codegen;
    [refCompiler generateFunctionNamed:@"_returnString" body:^(STObjectCodeGeneratorARM * _Nonnull gen) {
        [refCompiler generateStringLiteral:@"Test String"];
    }];

    [objectWriter addTextSectionData:(NSData*)refGen.generatedCode];
    [objectWriter writeFile];
    [objectWriter.data writeToFile:objectPath atomically:YES];

    int linkResult = [refCompiler linkObjects:@[@"conststring_symcompare"]
                           toSharedLibrary:@"conststring_symcompare_ref.dylib"
                                     inDir:tempDir
                            withFrameworks:@[@"Foundation"]];
    INTEXPECT(linkResult, 0, @"external linker should succeed");
    system([[NSString stringWithFormat:@"codesign -f -s - %@", refDylibPath] UTF8String]);

    // 2. Generate CANDIDATE dylib using MPWMachODylibWriter
    MPWMachODylibWriter *genWriter = [MPWMachODylibWriter stream];
    STNativeCompiler *genCompiler = [[[STNativeCompiler alloc] initWithWriter:genWriter] autorelease];
    genWriter.installName = @"@rpath/libconststring.dylib";
    [genWriter.frameworks addObject:@"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation"];

    STObjectCodeGeneratorARM *genGen = genCompiler.codegen;
    [genCompiler generateFunctionNamed:@"_returnString" body:^(STObjectCodeGeneratorARM * _Nonnull gen) {
        [genCompiler generateStringLiteral:@"Test String"];
    }];

    [genWriter addTextSectionData:genGen.generatedCode];
    [genWriter writeFile];
    NSData *genDylibData = [genWriter data];

    NSString *genDylibPath = [tempDir stringByAppendingPathComponent:@"conststring_symcompare_gen.dylib"];
    [genDylibData writeToFile:genDylibPath atomically:YES];
    system([[NSString stringWithFormat:@"codesign -f -s - %@", genDylibPath] UTF8String]);

    // 3. Run nm on both and log output
    NSLog(@"=== REFERENCE DYLIB nm OUTPUT ===");
    system([[NSString stringWithFormat:@"nm %@ 2>&1", refDylibPath] UTF8String]);

    NSLog(@"=== GENERATED DYLIB nm OUTPUT ===");
    system([[NSString stringWithFormat:@"nm %@ 2>&1", genDylibPath] UTF8String]);

    // 4. Use MPWMachOReader to examine symbol tables programmatically
    NSData *refDylibData = [NSData dataWithContentsOfFile:refDylibPath];
    MPWMachOReader *refReader = [MPWMachOReader readerWithData:refDylibData];
    MPWMachOReader *genReader = [MPWMachOReader readerWithData:genDylibData];

    NSLog(@"=== REFERENCE SYMBOL TABLE (via MPWMachOReader) ===");
    NSArray *refSymbols = [refReader symbols];
    for (int i = 0; i < refSymbols.count; i++) {
        NSDictionary *sym = refSymbols[i];
        NSLog(@"  [%d] name='%@' type=0x%02x sect=%@ value=0x%llx",
              i, sym[@"name"], [sym[@"type"] intValue], sym[@"sect"], [sym[@"value"] unsignedLongLongValue]);
    }

    NSLog(@"=== GENERATED SYMBOL TABLE (via MPWMachOReader) ===");
    NSArray *genSymbols = [genReader symbols];
    for (int i = 0; i < genSymbols.count; i++) {
        NSDictionary *sym = genSymbols[i];
        NSLog(@"  [%d] name='%@' type=0x%02x sect=%@ value=0x%llx",
              i, sym[@"name"], [sym[@"type"] intValue], sym[@"sect"], [sym[@"value"] unsignedLongLongValue]);
    }

    // 5. Check for ___CFConstantStringClassReference specifically
    NSLog(@"=== ___CFConstantStringClassReference CHECK ===");
    long refCFStrIndex = [refReader indexOfSymbolNamed:@"___CFConstantStringClassReference"];
    long genCFStrIndex = [genReader indexOfSymbolNamed:@"___CFConstantStringClassReference"];

    NSLog(@"Reference index: %ld", refCFStrIndex);
    NSLog(@"Generated index: %ld", genCFStrIndex);

    if (refCFStrIndex >= 0 && refCFStrIndex < refSymbols.count) {
        NSDictionary *refSym = refSymbols[refCFStrIndex];
        NSLog(@"Reference ___CFConstantStringClassReference: type=0x%02x sect=%@ (should be undefined external)",
              [refSym[@"type"] intValue], refSym[@"sect"]);
        // type 0x01 = N_EXT (external), sect 0 = undefined
        INTEXPECT([refSym[@"type"] intValue] & 0x0e, 0, @"reference should have type=0 (undefined)");
    }

    if (genCFStrIndex >= 0 && genCFStrIndex < genSymbols.count) {
        NSDictionary *genSym = genSymbols[genCFStrIndex];
        NSLog(@"Generated ___CFConstantStringClassReference: type=0x%02x sect=%@ (SHOULD be undefined external)",
              [genSym[@"type"] intValue], genSym[@"sect"]);
        // This is the BUG if type != 0 or sect != NO_SECT
        int genType = [genSym[@"type"] intValue] & 0x0e;
        if (genType != 0) {
            NSLog(@"BUG: Generated ___CFConstantStringClassReference has type 0x%02x instead of 0 (undefined)", genType);
        }
    }
}

+ (void)testKnownGoodExternalLinkerDylibWithConstantNSString {
    STNativeCompiler *compiler = [STNativeCompiler compiler];
    MPWMachOWriter *writer = compiler.writer;
    NSString *objectPath = @"/tmp/justconstantstring-ref.o";
    NSString *path = @"/tmp/libconstantstring-ref.dylib";
    
    NSString *stringToGeneratorAndCheck = @"Hello World Constant Strign in dylib";
    
    STObjectCodeGeneratorARM *gen = compiler.codegen;
    
    [compiler generateFunctionNamed:@"_returnString" body:^(STObjectCodeGeneratorARM * _Nonnull gen) {
        [compiler generateStringLiteral:stringToGeneratorAndCheck];
    }];

    [writer addTextSectionData:(NSData*)gen.generatedCode];
    [writer writeFile];
    [writer.data writeToFile:objectPath atomically:YES];
    
    // 2. Link with external linker
    int linkResult = [compiler linkObjects:@[@"justconstantstring-ref"]
                           toSharedLibrary:@"libconstantstring-ref.dylib"
                                     inDir:@"/tmp"
                            withFrameworks:@[@"MPWFoundation", @"Foundation"]];
    INTEXPECT(linkResult, 0, @"external linker should succeed");

    
    
    system([[NSString stringWithFormat:@"codesign -f -s - %@", path] UTF8String]);
    
    void *handle = dlopen([path UTF8String], RTLD_NOW);
    NSString *errorString=nil;
    if (!handle) {
        errorString = @(dlerror());
    }
    EXPECTNOTNIL(handle, errorString);
    id (*returnString)(void) = dlsym(handle, "returnString");
    EXPECTNOTNIL(returnString, @" returnString function address");
    IDEXPECT( returnString(), stringToGeneratorAndCheck,@"returned constants string" );
    
    
    // Cleanup
//    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}



+ (void)testDylibWithConstantNSString {
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    STNativeCompiler *compiler = [[[STNativeCompiler alloc] initWithWriter:writer] autorelease];
    NSString *path = @"/tmp/libconstantstring.dylib";
    writer.installName = @"@rpath/libconstantstring.dylib";
    // ___CFConstantStringClassReference is in CoreFoundation, need to link Foundation
    [writer.frameworks addObject:@"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation"];

    NSString *stringToGeneratorAndCheck = @"Hello World Constant String in dylib";
    
    STObjectCodeGeneratorARM *gen = compiler.codegen;
    
    [compiler generateFunctionNamed:@"_returnString" body:^(STObjectCodeGeneratorARM * _Nonnull gen) {
        [compiler generateStringLiteral:stringToGeneratorAndCheck];
    }];
    
    [writer addTextSectionData:gen.generatedCode];
    [writer writeFile];
    NSData *genDylibData = [writer data];
    [genDylibData writeToFile:path atomically:YES];
    
    system([[NSString stringWithFormat:@"codesign -f -s - %@", path] UTF8String]);
    void *handle = dlopen([path UTF8String], RTLD_NOW);
    NSString *errorString=nil;
    if (!handle) {
        errorString = @(dlerror());
    }
    EXPECTNOTNIL(handle, errorString);
    NSLog(@"testDylibWithConstantNSString: dlopen result = %p", handle);

    if (handle) {
        id (*returnString)(void) = dlsym(handle, "returnString");
        NSLog(@"testDylibWithConstantNSString: dlsym returnString = %p", returnString);
        EXPECTNOTNIL(returnString, @"returnString function address");
        if (returnString) {
            NSLog(@"testDylibWithConstantNSString: About to call returnString()");
            id result = returnString();
            NSLog(@"testDylibWithConstantNSString: Got result = %@", result);
            IDEXPECT(result, stringToGeneratorAndCheck, @"returned constant string");
        }
        dlclose(handle);
    }

    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

+(NSString*)testClassCodeWithName:(NSString*)className methodName:(NSString*)methodName returnValue:(NSString*)returnValue
{
    return [NSString stringWithFormat:@"class %@ { -%@ { %@. } }",className,methodName,returnValue];
}

+(NSString*)testClassCodeWithName:(NSString*)className
{
    return [self testClassCodeWithName:className methodName:@"value" returnValue:@"42"];
}

+(void)testDylibWithCompiledObjectiveSmalltalkClass
{
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    STNativeCompiler *compiler = [[[STNativeCompiler alloc] initWithWriter:writer] autorelease];
    NSString *path = @"/tmp/compiled-st-class.dylib";
    writer.installName = @"@rpath/compiled-st-class.dylib";
    [writer.frameworks addObject:@"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation"];
    [writer.frameworks addObject:@"/Library/Frameworks/MPWFoundation.framework/Versions/A/MPWFoundation"];
    NSString *className = @"TestClassCode1";

    NSString *classToCompile = [self testClassCodeWithName:className];


    NSData *dylibdata = [compiler compileClassToMachoO:[compiler compile:classToCompile]];
    
    //    [writer addTextSectionData:gen.generatedCode];
    [dylibdata writeToFile:path atomically:YES];
    
    system([[NSString stringWithFormat:@"codesign -s - %@", path] UTF8String]);
    void *handle = dlopen([path UTF8String], RTLD_NOW);
    NSString *errorString=nil;
    if (!handle) {
        errorString = @(dlerror());
    }
    EXPECTNOTNIL(handle, errorString);
    NSLog(@"testDylibWithCompiledObjectiveSmalltalkClass: dlopen result = %p", handle);
    
    if (handle) {
        id testClass = NSClassFromString(className);
        EXPECTNOTNIL(testClass, @"loaded the test class");
        id instance = [testClass new];
        EXPECTNOTNIL(instance, @"testinstance");
        IDEXPECT([instance value],@(42),@"test value");
        dlclose(handle);
    }

    // Cleanup
    //    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

+(void)testDylibWithCompiledObjectiveSmalltalkClassRef
{
    STNativeCompiler *compiler = [STNativeCompiler compiler];
    NSString *path = @"/tmp/compiled-st-class-ref.o";
    NSString *lib = @"libst-test-class.dylib";\
    NSString *libpath = [@"/tmp/" stringByAppendingPathComponent:lib];
    NSString *className = @"TestClassCode2";
    
    NSString *classToCompile = [self testClassCodeWithName:className];
        
    NSData *compiled = [compiler compileClassToMachoO:[compiler compile:classToCompile]];
    
    //    [writer addTextSectionData:gen.generatedCode];
    [compiled writeToFile:path atomically:YES];
    
    // 2. Link with external linker
    int linkResult = [compiler linkObjects:@[@"compiled-st-class-ref"]
                           toSharedLibrary:lib
                                     inDir:@"/tmp"
                            withFrameworks:@[@"MPWFoundation", @"Foundation"]];
    INTEXPECT(linkResult, 0, @"external linker should succeed");
    
    

    
    system([[NSString stringWithFormat:@"codesign -s - /tmp/%@", @"libst-test-class.dylib"] UTF8String]);
    void *handle = dlopen([libpath UTF8String], RTLD_NOW);
    NSString *errorString=nil;
    if (!handle) {
        errorString = @(dlerror());
    }
    EXPECTNOTNIL(handle, errorString);
    NSLog(@"testDylibWithCompiledObjectiveSmalltalkClass: dlopen result = %p", handle);
    
    if (handle) {
        id testClass = NSClassFromString(className);
        EXPECTNOTNIL(testClass, @"loaded the test class");
        id instance = [testClass new];
        EXPECTNOTNIL(instance, @"testinstance");
        IDEXPECT([instance value],@(42),@"test value");
        dlclose(handle);
    }
    
    // Cleanup
    //    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

+(void)testDylibWithTwoClasses
{
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    STNativeCompiler *compiler = [[[STNativeCompiler alloc] initWithWriter:writer] autorelease];
    NSString *path = @"/tmp/two-compiled-st-classes.dylib";
    writer.installName = @"@rpath/two-compiled-st-classes.dylib";
    [writer.frameworks addObject:@"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation"];
    [writer.frameworks addObject:@"/Library/Frameworks/MPWFoundation.framework/Versions/A/MPWFoundation"];
    NSString *class1Name = @"TestClassCode3";
    NSString *class2Name = @"TestClassCode4";

    NSString *class1ToCompile = [self testClassCodeWithName:class1Name methodName:@"value1" returnValue:@"40"];
    NSString *class2ToCompile = [self testClassCodeWithName:class2Name methodName:@"value2" returnValue:@"50"];

    
    NSData *dylibdata = [compiler compileClassesToMachoO:@[ [compiler compile:class1ToCompile], [compiler compile:class2ToCompile]]];
    
    //    [writer addTextSectionData:gen.generatedCode];
    [dylibdata writeToFile:path atomically:YES];
    
    system([[NSString stringWithFormat:@"codesign -s - %@", path] UTF8String]);
    void *handle = dlopen([path UTF8String], RTLD_NOW);
    NSString *errorString=nil;
    if (!handle) {
        errorString = @(dlerror());
    }
    EXPECTNOTNIL(handle, errorString);
    NSLog(@"testDylibWithCompiledObjectiveSmalltalkClass: dlopen result = %p", handle);
    
    if (handle) {
        id testClass1 = NSClassFromString(class1Name);
        EXPECTNOTNIL(testClass1, @"loaded the test class");
        id instance1 = [testClass1 new];
        EXPECTNOTNIL(instance1, @"testinstance");
        IDEXPECT([instance1 value1],@(40),@"test value");

        id testClass2 = NSClassFromString(class2Name);
        EXPECTNOTNIL(testClass2, @"loaded the test class");
        id instance2 = [testClass2 new];
        EXPECTNOTNIL(instance2, @"testinstance");
        IDEXPECT([instance2 value2],@(50),@"test value");
        dlclose(handle);
    }
    
    // Cleanup
    //    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

+(void)testCharacterizeReferenceTwoClassesDylib
{
    STNativeCompiler *compiler1 = [STNativeCompiler compiler];
    STNativeCompiler *compiler2 = [STNativeCompiler compiler];
    NSString *object_path1 = @"/tmp/two-classes-ref-1.o";
    NSString *object_path2 = @"/tmp/two-classes-ref-2.o";
    NSString *lib = @"two-classes-ref.dylib";
    NSString *libpath = [@"/tmp/" stringByAppendingPathComponent:lib];

    NSString *class1Name = @"TestClassCode6";
    NSString *class2Name = @"TestClassCode7";

    NSString *class1ToCompile = [self testClassCodeWithName:class1Name];
    NSString *class2ToCompile = [self testClassCodeWithName:class2Name];

    NSData *compiled1 = [compiler1 compileClassToMachoO:[compiler1 compile:class1ToCompile]];
    NSData *compiled2 = [compiler2 compileClassToMachoO:[compiler2 compile:class2ToCompile]];

    [compiled1 writeToFile:object_path1 atomically:YES];
    [compiled2 writeToFile:object_path2 atomically:YES];

    int linkResult = [compiler1 linkObjects:@[@"two-classes-ref-1", @"two-classes-ref-2"]
                           toSharedLibrary:lib
                                     inDir:@"/tmp"
                            withFrameworks:@[@"MPWFoundation", @"Foundation"]];
    INTEXPECT(linkResult, 0, @"external linker should succeed");

    NSData *refDylibData = [NSData dataWithContentsOfFile:libpath];
    EXPECTNOTNIL(refDylibData, @"reference dylib should be created");
    MPWMachOReader *refReader = [MPWMachOReader readerWithData:refDylibData];
    EXPECTNOTNIL(refReader, @"reference reader should be created");
    EXPECTTRUE([refReader isHeaderValid], @"reference header should be valid");

    [self expectClassListInReader:refReader
                       classNames:@[ class1Name, class2Name ]
                            label:@"Reference two-class dylib"];

    [[NSFileManager defaultManager] removeItemAtPath:object_path1 error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:object_path2 error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:libpath error:nil];
}

+(void)testCharacterizeGeneratedTwoClassesDylib
{
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    STNativeCompiler *compiler = [[[STNativeCompiler alloc] initWithWriter:writer] autorelease];
    writer.installName = @"@rpath/two-classes-gen.dylib";
    [writer.frameworks addObject:@"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation"];
    [writer.frameworks addObject:@"/Library/Frameworks/MPWFoundation.framework/Versions/A/MPWFoundation"];

    NSString *class1Name = @"TestClassCode3";
    NSString *class2Name = @"TestClassCode4";

    NSString *class1ToCompile = [self testClassCodeWithName:class1Name];
    NSString *class2ToCompile = [self testClassCodeWithName:class2Name];

    NSData *dylibdata = [compiler compileClassesToMachoO:@[
        [compiler compile:class1ToCompile],
        [compiler compile:class2ToCompile]
    ]];

    EXPECTNOTNIL(dylibdata, @"generated dylib data should exist");
    MPWMachOReader *genReader = [MPWMachOReader readerWithData:dylibdata];
    EXPECTNOTNIL(genReader, @"generated reader should be created");
    EXPECTTRUE([genReader isHeaderValid], @"generated header should be valid");

    [self expectClassListInReader:genReader
                       classNames:@[ class1Name, class2Name ]
                            label:@"Generated two-class dylib"];
}

+(void)testDylibWithTwoClassesRef
{
    STNativeCompiler *compiler1 = [STNativeCompiler compiler];
    STNativeCompiler *compiler2 = [STNativeCompiler compiler];
    NSString *object_path1 = @"/tmp/compiled-st-class1-ref.o";
    NSString *object_path2 = @"/tmp/compiled-st-class2-ref.o";
    NSString *lib = @"libst-test-class.dylib";\
    NSString *libpath = [@"/tmp/" stringByAppendingPathComponent:lib];
    
    NSString *class1Name = @"TestClassCode6";
    NSString *class2Name = @"TestClassCode7";
    
    NSString *class1ToCompile = [self testClassCodeWithName:class1Name];
    NSString *class2ToCompile = [self testClassCodeWithName:class2Name];

    NSData *compiled1 = [compiler1 compileClassToMachoO:[compiler1 compile:class1ToCompile]];
    NSData *compiled2 = [compiler2 compileClassToMachoO:[compiler2 compile:class2ToCompile]];

    //    [writer addTextSectionData:gen.generatedCode];
    [compiled1 writeToFile:object_path1 atomically:YES];
    [compiled2 writeToFile:object_path2 atomically:YES];

    // 2. Link with external linker
    int linkResult = [compiler1 linkObjects:@[@"compiled-st-class1-ref", @"compiled-st-class2-ref"]
                           toSharedLibrary:lib
                                     inDir:@"/tmp"
                            withFrameworks:@[@"MPWFoundation", @"Foundation"]];
    INTEXPECT(linkResult, 0, @"external linker should succeed");
    
        
    system([[NSString stringWithFormat:@"codesign -s - %@", libpath] UTF8String]);
    void *handle = dlopen([libpath UTF8String], RTLD_NOW);
    NSString *errorString=nil;
    if (!handle) {
        errorString = @(dlerror());
    }
    EXPECTNOTNIL(handle, errorString);
    NSLog(@"testDylibWithCompiledObjectiveSmalltalkClass: dlopen result = %p", handle);
    
        if (handle) {
            id testClass1 = NSClassFromString(class1Name);
            EXPECTNOTNIL(testClass1, @"loaded the test class");
            id instance1 = [testClass1 new];
            EXPECTNOTNIL(instance1, @"testinstance");
            IDEXPECT([instance1 value],@(42),@"test value");

            id testClass2 = NSClassFromString(class2Name);
            EXPECTNOTNIL(testClass1, @"loaded the test class");
            id instance2 = [testClass2 new];
            EXPECTNOTNIL(instance2, @"testinstance");
            IDEXPECT([instance2 value],@(42),@"test value");
            dlclose(handle);
        }
    
    // Cleanup
    //    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

+(void)testCompileBundleSourcesToDylib
{
    NSString *bundleOriginPath = [[NSBundle bundleForClass:[STBundle class]] pathForResource:@"test" ofType:@"stb"];
    NSString *bundlePath = @"/tmp/test.stb";
    EXPECTNOTNIL(bundleOriginPath, @"test bundle should exist");
    system( [[NSString stringWithFormat:@"cp -r %@ /tmp/", bundleOriginPath] UTF8String]);
    STBundle *bundle = [STBundle bundleWithPath:bundlePath];
    EXPECTNOTNIL(bundle, @"bundle should be created");

    [bundle compileSourcesToNativeDylib];
//    EXPECTNOTNIL(dylibData, @"compiled dylib data should exist");


    
//    system([[NSString stringWithFormat:@"codesign --deep -s - %@", path] UTF8String]);
    
    NSBundle *nsbundle = [NSBundle bundleWithPath:bundlePath];
    EXPECTNOTNIL(nsbundle, @"got a bundle");
    EXPECTTRUE( [nsbundle load],@"loading");
//    void *handle = dlopen([path UTF8String], RTLD_NOW);
//    NSString *errorString=nil;
//    if (!handle) {
//        errorString = @(dlerror());
//    }
//    EXPECTNOTNIL(handle, errorString);

        id testClass1 = NSClassFromString(@"_STBundleLoadedTestClass1");
        id testClass2 = NSClassFromString(@"_STBundleLoadedTestClass2");
        EXPECTNOTNIL(testClass1, @"loaded class 1");
        EXPECTNOTNIL(testClass2, @"loaded class 2");
}

+ (void)testDylibWithLiteralObjects {
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    NSString *installName = nil;
    NSString *path = uniqueLiteralPath(@"libliteralobjects", &installName);
    writer.installName = installName;
    [writer.frameworks addObject:@"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation"];
    [writer.frameworks addObject:@"/System/Library/Frameworks/CoreFoundation.framework/Versions/Current/CoreFoundation"];

    MPWMachOObjectSerializer *serializer = [[[MPWMachOObjectSerializer alloc] initWithWriter:writer] autorelease];
    
    NSArray *arrayLiteral = @[ @"string1", @"string2" ];
    NSDictionary *dictLiteral = @{ @"a": @"b", @"c": @"d" };
    NSNumber *numberLiteral = @42;
    NSString *stringLiteral = @"literal string";
    
    NSString *arraySymbol = [serializer symbolForObject:arrayLiteral];
    NSString *dictSymbol = [serializer symbolForObject:dictLiteral];
    NSString *numberSymbol = [serializer symbolForObject:numberLiteral];
    NSString *stringSymbol = [serializer symbolForObject:stringLiteral];
    
    MPWMachOSectionWriter *dataWriter = [writer addSectionWriterWithSegName:@"__DATA"
                                                                   sectName:@"__data"
                                                                      flags:0];
    uint64_t zero = 0;
    
    [dataWriter declareGlobalSymbol:@"_literal_nsarray_test"];
    [dataWriter addRelocationEntryForSymbol:arraySymbol atOffset:(int)dataWriter.length];
    [dataWriter appendBytes:&zero length:sizeof(zero)];
    
    [dataWriter declareGlobalSymbol:@"_literal_nsdict_test"];
    [dataWriter addRelocationEntryForSymbol:dictSymbol atOffset:(int)dataWriter.length];
    [dataWriter appendBytes:&zero length:sizeof(zero)];
    
    [dataWriter declareGlobalSymbol:@"_literal_nsnumber_test"];
    [dataWriter addRelocationEntryForSymbol:numberSymbol atOffset:(int)dataWriter.length];
    [dataWriter appendBytes:&zero length:sizeof(zero)];
    
    [dataWriter declareGlobalSymbol:@"_literal_nsstring_test"];
    [dataWriter addRelocationEntryForSymbol:stringSymbol atOffset:(int)dataWriter.length];
    [dataWriter appendBytes:&zero length:sizeof(zero)];
    
    [writer writeFile];
    [[writer data] writeToFile:path atomically:YES];
    
    system([[NSString stringWithFormat:@"codesign -f -s - %@", path] UTF8String]);
    void *handle = dlopen([path UTF8String], RTLD_NOW);
    NSString *errorString = nil;
    if (!handle) {
        errorString = @(dlerror());
    }
    EXPECTNOTNIL(handle, errorString);
    
    if (handle) {
        id *arrayPtr = dlsym(handle, "literal_nsarray_test");
        if (!arrayPtr) {
            NSLog(@"testDylibWithLiteralNSArrayObject: dlsym error: %s", dlerror());
        }
        EXPECTNOTNIL(arrayPtr, @"literal_nsarray_test symbol");
        NSArray *loadedArray = arrayPtr ? *arrayPtr : nil;
        EXPECTNOTNIL(loadedArray, @"loaded array");
        INTEXPECT((int)loadedArray.count, 2, @"array count");
        IDEXPECT(loadedArray[0], @"string1", @"array first element");
        IDEXPECT(loadedArray[1], @"string2", @"array second element");
        
        id *dictPtr = dlsym(handle, "literal_nsdict_test");
        EXPECTNOTNIL(dictPtr, @"literal_nsdict_test symbol");
        NSDictionary *loadedDict = dictPtr ? *dictPtr : nil;
        EXPECTNOTNIL(loadedDict, @"loaded dict");
        IDEXPECT(loadedDict[@"a"], @"b", @"dict value a");
        IDEXPECT(loadedDict[@"c"], @"d", @"dict value c");
        
        id *numberPtr = dlsym(handle, "literal_nsnumber_test");
        EXPECTNOTNIL(numberPtr, @"literal_nsnumber_test symbol");
        NSNumber *loadedNumber = numberPtr ? *numberPtr : nil;
        EXPECTNOTNIL(loadedNumber, @"loaded number");
        INTEXPECT([loadedNumber intValue], 42, @"number value");
        
        id *stringPtr = dlsym(handle, "literal_nsstring_test");
        EXPECTNOTNIL(stringPtr, @"literal_nsstring_test symbol");
        NSString *loadedString = stringPtr ? *stringPtr : nil;
        EXPECTNOTNIL(loadedString, @"loaded string");
        IDEXPECT(loadedString, stringLiteral, @"string value");
        
        dlclose(handle);
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

// Smaller-step tests for literal object serialization
+ (void)testDylibWithLiteralNSStringObject {
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    NSString *installName = nil;
    NSString *path = uniqueLiteralPath(@"libliteralstring", &installName);
    writer.installName = installName;
    [writer.frameworks addObject:@"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation"];
    [writer.frameworks addObject:@"/System/Library/Frameworks/CoreFoundation.framework/Versions/Current/CoreFoundation"];

    MPWMachOObjectSerializer *serializer = [[[MPWMachOObjectSerializer alloc] initWithWriter:writer] autorelease];
    NSString *stringLiteral = @"literal string";
    NSString *stringSymbol = [serializer symbolForObject:stringLiteral];

    MPWMachOSectionWriter *dataWriter = [writer addSectionWriterWithSegName:@"__DATA"
                                                                   sectName:@"__data"
                                                                      flags:0];
    uint64_t zero = 0;
    [dataWriter declareGlobalSymbol:@"_literal_nsstring_test"];
    [dataWriter addRelocationEntryForSymbol:stringSymbol atOffset:(int)dataWriter.length];
    [dataWriter appendBytes:&zero length:sizeof(zero)];

    [writer writeFile];
    [[writer data] writeToFile:path atomically:YES];

    system([[NSString stringWithFormat:@"codesign -f -s - %@", path] UTF8String]);
    void *handle = dlopen([path UTF8String], RTLD_NOW);
    NSString *errorString = nil;
    if (!handle) {
        errorString = @(dlerror());
    }
    EXPECTNOTNIL(handle, errorString);

    if (handle) {
        id *stringPtr = dlsym(handle, "literal_nsstring_test");
        EXPECTNOTNIL(stringPtr, @"literal_nsstring_test symbol");
        NSString *loadedString = stringPtr ? *stringPtr : nil;
        EXPECTNOTNIL(loadedString, @"loaded string");
        IDEXPECT(loadedString, stringLiteral, @"string value");
        dlclose(handle);
    }

    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

+ (void)testDylibWithLiteralNSNumberObject {
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    NSString *installName = nil;
    NSString *path = uniqueLiteralPath(@"libliteralnumber", &installName);
    writer.installName = installName;
    [writer.frameworks addObject:@"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation"];
    [writer.frameworks addObject:@"/System/Library/Frameworks/CoreFoundation.framework/Versions/Current/CoreFoundation"];

    MPWMachOObjectSerializer *serializer = [[[MPWMachOObjectSerializer alloc] initWithWriter:writer] autorelease];
    NSNumber *numberLiteral = @42;
    NSString *numberSymbol = [serializer symbolForObject:numberLiteral];

    MPWMachOSectionWriter *dataWriter = [writer addSectionWriterWithSegName:@"__DATA"
                                                                   sectName:@"__data"
                                                                      flags:0];
    uint64_t zero = 0;
    [dataWriter declareGlobalSymbol:@"_literal_nsnumber_test"];
    [dataWriter addRelocationEntryForSymbol:numberSymbol atOffset:(int)dataWriter.length];
    [dataWriter appendBytes:&zero length:sizeof(zero)];

    [writer writeFile];
    [[writer data] writeToFile:path atomically:YES];

    system([[NSString stringWithFormat:@"codesign -f -s - %@", path] UTF8String]);
    void *handle = dlopen([path UTF8String], RTLD_NOW);
    NSString *errorString = nil;
    if (!handle) {
        errorString = @(dlerror());
    }
    EXPECTNOTNIL(handle, errorString);

    if (handle) {
        id *numberPtr = dlsym(handle, "literal_nsnumber_test");
        EXPECTNOTNIL(numberPtr, @"literal_nsnumber_test symbol");
        NSNumber *loadedNumber = numberPtr ? *numberPtr : nil;
        EXPECTNOTNIL(loadedNumber, @"loaded number");
        INTEXPECT([loadedNumber intValue], 42, @"number value");
        dlclose(handle);
    }

    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

+ (void)testDylibWithLiteralNSArrayObject {
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    NSString *installName = nil;
    NSString *path = uniqueLiteralPath(@"libliteralarray", &installName);
    writer.installName = installName;
    [writer.frameworks addObject:@"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation"];
    [writer.frameworks addObject:@"/System/Library/Frameworks/CoreFoundation.framework/Versions/Current/CoreFoundation"];

    MPWMachOObjectSerializer *serializer = [[[MPWMachOObjectSerializer alloc] initWithWriter:writer] autorelease];
    NSArray *arrayLiteral = @[ @"string1", @"string2" ];
    NSString *arraySymbol = [serializer symbolForObject:arrayLiteral];

    MPWMachOSectionWriter *dataWriter = [writer addSectionWriterWithSegName:@"__DATA"
                                                                   sectName:@"__data"
                                                                      flags:0];
    uint64_t zero = 0;
    [dataWriter declareGlobalSymbol:@"_literal_nsarray_test"];
    [dataWriter addRelocationEntryForSymbol:arraySymbol atOffset:(int)dataWriter.length];
    [dataWriter appendBytes:&zero length:sizeof(zero)];

    [writer writeFile];
    [[writer data] writeToFile:path atomically:YES];

    system([[NSString stringWithFormat:@"codesign -f -s - %@", path] UTF8String]);
    void *handle = dlopen([path UTF8String], RTLD_NOW);
    NSString *errorString = nil;
    if (!handle) {
        errorString = @(dlerror());
    }
    EXPECTNOTNIL(handle, errorString);

    if (handle) {
        id *arrayPtr = dlsym(handle, "literal_nsarray_test");
        EXPECTNOTNIL(arrayPtr, @"literal_nsarray_test symbol");
        NSArray *loadedArray = arrayPtr ? *arrayPtr : nil;
        EXPECTNOTNIL(loadedArray, @"loaded array");
        INTEXPECT((int)loadedArray.count, 2, @"array count");
        IDEXPECT(loadedArray[0], @"string1", @"array first element");
        IDEXPECT(loadedArray[1], @"string2", @"array second element");
        dlclose(handle);
    }

    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

// Characterize generated literal NSArray dylib without dlopen
+ (void)testCharacterizeGeneratedLiteralNSArrayDylib {
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    NSString *installName = nil;
    (void)uniqueLiteralPath(@"libliteralarray", &installName);
    writer.installName = installName;
    [writer.frameworks addObject:@"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation"];
    [writer.frameworks addObject:@"/System/Library/Frameworks/CoreFoundation.framework/Versions/Current/CoreFoundation"];

    MPWMachOObjectSerializer *serializer = [[[MPWMachOObjectSerializer alloc] initWithWriter:writer] autorelease];
    NSArray *arrayLiteral = @[ @"string1", @"string2" ];
    NSString *arraySymbol = [serializer symbolForObject:arrayLiteral];

    MPWMachOSectionWriter *dataWriter = [writer addSectionWriterWithSegName:@"__DATA"
                                                                   sectName:@"__data"
                                                                      flags:0];
    uint64_t zero = 0;
    [dataWriter declareGlobalSymbol:@"_literal_nsarray_test"];
    [dataWriter addRelocationEntryForSymbol:arraySymbol atOffset:(int)dataWriter.length];
    [dataWriter appendBytes:&zero length:sizeof(zero)];

    [writer writeFile];
    NSData *genData = [writer data];
    EXPECTNOTNIL(genData, @"generated array dylib data");
    if (!genData) return;

    MPWMachOReader *reader = [MPWMachOReader readerWithData:genData];
    EXPECTNOTNIL(reader, @"reader should be created");
    EXPECTTRUE([reader isHeaderValid], @"header should be valid");

    NSArray *exports = [reader exportedSymbolNames];
    NSLog(@"Generated array exports: %@", exports);
    EXPECTTRUE([exports containsObject:@"_literal_nsarray_test"],
               @"should export _literal_nsarray_test");

    MPWMachOSegment *dataConstSeg = [reader segmentObjectNamed:@"__DATA_CONST"];
    EXPECTNOTNIL(dataConstSeg, @"generated should have __DATA_CONST");
    MPWMachOSection *arrayObj = [self findSectionNamed:@"__objc_arrayobj" inSegment:dataConstSeg];
    MPWMachOSection *arrayData = [self findSectionNamed:@"__objc_arraydata" inSegment:dataConstSeg];
    EXPECTNOTNIL(arrayObj, @"generated should have __objc_arrayobj");
    EXPECTNOTNIL(arrayData, @"generated should have __objc_arraydata");
    if (!arrayObj || !arrayData) return;

    NSLog(@"Generated __objc_arrayobj: addr=0x%llx size=%lld offset=0x%lx",
          arrayObj.address, (unsigned long long)arrayObj.size, arrayObj.offset);
    NSLog(@"Generated __objc_arraydata: addr=0x%llx size=%lld offset=0x%lx",
          arrayData.address, (unsigned long long)arrayData.size, arrayData.offset);

    const uint64_t *arrayQ = (const uint64_t *)(genData.bytes + arrayObj.offset);
    for (int i = 0; i < 3; i++) {
        NSLog(@"  arrayobj[%d] = 0x%016llx", i, arrayQ[i]);
    }

    NSData *chainedData = [self chainedFixupsDataFromReader:reader];
    EXPECTNOTNIL(chainedData, @"generated should have chained fixups data");
    NSDictionary *arrayImport = [self checkChainedFixupsImportsIn:chainedData
                                                        forSymbol:@"_OBJC_CLASS_$_NSConstantArray"
                                                        logPrefix:@"Generated"];
    EXPECTTRUE([arrayImport[@"found"] boolValue],
               @"generated should import _OBJC_CLASS_$_NSConstantArray");
}

+ (void)testDylibWithLiteralNSDictionaryObject {
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    NSString *installName = nil;
    NSString *path = uniqueLiteralPath(@"libliteraldict", &installName);
    writer.installName = installName;
    [writer.frameworks addObject:@"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation"];
    [writer.frameworks addObject:@"/System/Library/Frameworks/CoreFoundation.framework/Versions/Current/CoreFoundation"];

    MPWMachOObjectSerializer *serializer = [[[MPWMachOObjectSerializer alloc] initWithWriter:writer] autorelease];
    NSDictionary *dictLiteral = @{ @"a": @"b", @"c": @"d" };
    NSString *dictSymbol = [serializer symbolForObject:dictLiteral];

    MPWMachOSectionWriter *dataWriter = [writer addSectionWriterWithSegName:@"__DATA"
                                                                   sectName:@"__data"
                                                                      flags:0];
    uint64_t zero = 0;
    [dataWriter declareGlobalSymbol:@"_literal_nsdict_test"];
    [dataWriter addRelocationEntryForSymbol:dictSymbol atOffset:(int)dataWriter.length];
    [dataWriter appendBytes:&zero length:sizeof(zero)];

    [writer writeFile];
    [[writer data] writeToFile:path atomically:YES];

    system([[NSString stringWithFormat:@"codesign -f -s - %@", path] UTF8String]);
    void *handle = dlopen([path UTF8String], RTLD_NOW);
    NSString *errorString = nil;
    if (!handle) {
        errorString = @(dlerror());
    }
    EXPECTNOTNIL(handle, errorString);

    if (handle) {
        id *dictPtr = dlsym(handle, "literal_nsdict_test");
        EXPECTNOTNIL(dictPtr, @"literal_nsdict_test symbol");
        NSDictionary *loadedDict = dictPtr ? *dictPtr : nil;
        EXPECTNOTNIL(loadedDict, @"loaded dict");
        IDEXPECT(loadedDict[@"a"], @"b", @"dict value a");
        IDEXPECT(loadedDict[@"c"], @"d", @"dict value c");
        dlclose(handle);
    }

    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

// Characterize generated literal NSDictionary dylib without dlopen
+ (void)testCharacterizeGeneratedLiteralNSDictionaryDylib {
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    NSString *installName = nil;
    (void)uniqueLiteralPath(@"libliteraldict", &installName);
    writer.installName = installName;
    [writer.frameworks addObject:@"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation"];
    [writer.frameworks addObject:@"/System/Library/Frameworks/CoreFoundation.framework/Versions/Current/CoreFoundation"];

    MPWMachOObjectSerializer *serializer = [[[MPWMachOObjectSerializer alloc] initWithWriter:writer] autorelease];
    NSDictionary *dictLiteral = @{ @"a": @"b", @"c": @"d" };
    NSString *dictSymbol = [serializer symbolForObject:dictLiteral];

    MPWMachOSectionWriter *dataWriter = [writer addSectionWriterWithSegName:@"__DATA"
                                                                   sectName:@"__data"
                                                                      flags:0];
    uint64_t zero = 0;
    [dataWriter declareGlobalSymbol:@"_literal_nsdict_test"];
    [dataWriter addRelocationEntryForSymbol:dictSymbol atOffset:(int)dataWriter.length];
    [dataWriter appendBytes:&zero length:sizeof(zero)];

    [writer writeFile];
    NSData *genData = [writer data];
    EXPECTNOTNIL(genData, @"generated dict dylib data");
    if (!genData) return;

    MPWMachOReader *reader = [MPWMachOReader readerWithData:genData];
    EXPECTNOTNIL(reader, @"reader should be created");
    EXPECTTRUE([reader isHeaderValid], @"header should be valid");

    NSArray *exports = [reader exportedSymbolNames];
    NSLog(@"Generated dict exports: %@", exports);
    EXPECTTRUE([exports containsObject:@"_literal_nsdict_test"],
               @"should export _literal_nsdict_test");

    MPWMachOSegment *dataConstSeg = [reader segmentObjectNamed:@"__DATA_CONST"];
    EXPECTNOTNIL(dataConstSeg, @"generated should have __DATA_CONST");

    MPWMachOSection *dictObj = [self findSectionNamed:@"__objc_dictobj" inSegment:dataConstSeg];
    MPWMachOSection *arrayData = [self findSectionNamed:@"__objc_arraydata" inSegment:dataConstSeg];
    EXPECTNOTNIL(dictObj, @"generated should have __objc_dictobj");
    EXPECTNOTNIL(arrayData, @"generated should have __objc_arraydata");
    if (!dictObj || !arrayData) return;

    NSLog(@"Generated __objc_dictobj: addr=0x%llx size=%lld offset=0x%lx",
          dictObj.address, (unsigned long long)dictObj.size, dictObj.offset);
    NSLog(@"Generated __objc_arraydata: addr=0x%llx size=%lld offset=0x%lx",
          arrayData.address, (unsigned long long)arrayData.size, arrayData.offset);

    EXPECTTRUE(dictObj.size >= 40, @"dict object should be at least 40 bytes");
    const uint64_t *dictQ = (const uint64_t *)(genData.bytes + dictObj.offset);
    for (int i = 0; i < 5; i++) {
        NSLog(@"  dictobj[%d] = 0x%016llx", i, dictQ[i]);
    }

    NSData *chainedData = [self chainedFixupsDataFromReader:reader];
    EXPECTNOTNIL(chainedData, @"generated should have chained fixups data");
    NSDictionary *dictImport = [self checkChainedFixupsImportsIn:chainedData
                                                       forSymbol:@"_OBJC_CLASS_$_NSConstantDictionary"
                                                       logPrefix:@"Generated"];
    EXPECTTRUE([dictImport[@"found"] boolValue],
               @"generated should import _OBJC_CLASS_$_NSConstantDictionary");
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
    @"testCharacterizeReferenceConstantStringDylib",
    @"testCharacterizeReferenceConstArrayFramework",
    @"testCharacterizeGeneratedConstantStringDylib",
    @"testCharacterizeGeneratedLiteralObjectsDylib",
    @"testCompareConstantStringBinaryContent",
    @"testCompareConstArrayBinaryContent",
//    @"testCompareSymbolTablesBetweenRefAndGenerated",   FIXME:  this test just logs, it should EXPECT
    @"testKnownGoodExternalLinkerDylibWithConstantNSString",
    @"testDylibWithConstantNSString",
    @"testDylibWithCompiledObjectiveSmalltalkClass",
    @"testDylibWithCompiledObjectiveSmalltalkClassRef",
    @"testCharacterizeReferenceTwoClassesDylib",
    @"testCharacterizeGeneratedTwoClassesDylib",
    @"testDylibWithTwoClassesRef",
    @"testDylibWithTwoClasses",
    @"testCompileBundleSourcesToDylib",
    @"testDylibWithLiteralNSStringObject",
    @"testDylibWithLiteralNSNumberObject",
    @"testCharacterizeGeneratedLiteralNSArrayDylib",
    @"testDylibWithLiteralNSArrayObject",
    @"testDylibWithLiteralNSDictionaryObject",
    @"testCharacterizeGeneratedLiteralNSDictionaryDylib",
    @"testDylibWithLiteralObjects",
  ];
}


@end
