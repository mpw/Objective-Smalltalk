//
//  MPWExportsTrieWriter.m
//  ObjSTNative
//
//  Builds Mach-O exports trie data structure for dyld
//

#import "MPWExportsTrieWriter.h"

@interface MPWExportsTrieWriter ()
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, NSNumber *> *symbols;
@end

@implementation MPWExportsTrieWriter

- (instancetype)init {
  self = [super init];
  if (self) {
    self.symbols = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)addSymbol:(NSString *)symbol {
  if (self.symbols[symbol] == nil) {
    self.symbols[symbol] = @(0); // Placeholder address
  }
}

- (void)addSymbol:(NSString *)symbol atAddress:(uint64_t)address {
  self.symbols[symbol] = @(address);
}

- (void)setAddress:(uint64_t)address forSymbol:(NSString *)symbol {
  self.symbols[symbol] = @(address);
}

#pragma mark - ULEB128 Encoding

- (void)writeULEB128:(uint64_t)value toData:(NSMutableData *)data {
  do {
    uint8_t byte = value & 0x7F;
    value >>= 7;
    if (value != 0) {
      byte |= 0x80;
    }
    [data appendBytes:&byte length:1];
  } while (value != 0);
}

- (NSData *)uleb128ForValue:(uint64_t)value {
  NSMutableData *data = [NSMutableData data];
  [self writeULEB128:value toData:data];
  return data;
}

#pragma mark - Trie Building

- (NSData *)trieData {
  NSMutableData *trie = [NSMutableData data];
  NSArray *symbolNames = [self.symbols allKeys];

  if (symbolNames.count == 0) {
    // Empty trie: just a root node with no exports and no children
    uint8_t emptyNode[] = {0x00, 0x00}; // no terminal info, no children
    [trie appendBytes:emptyNode length:2];
    return trie;
  }

  // For a single symbol, we use a simple structure
  if (symbolNames.count == 1) {
    [self buildSingleSymbolTrie:trie symbol:symbolNames[0]];
  } else {
    [self buildMultipleSymbolTrie:trie symbols:symbolNames];
  }

  return trie;
}

- (void)buildSingleSymbolTrie:(NSMutableData *)trie symbol:(NSString *)symbol {
  const char *name = [symbol UTF8String];
  // Keep the full symbol name including underscore prefix

  uint64_t address = [self.symbols[symbol] unsignedLongLongValue];

  // Root node: no terminal, one child
  uint8_t rootTerminalSize = 0;
  [trie appendBytes:&rootTerminalSize length:1];

  uint8_t numChildren = 1;
  [trie appendBytes:&numChildren length:1];

  // Edge: label + offset to child
  [trie appendBytes:name length:strlen(name) + 1];

  // Offset to child node (right after this byte)
  long childOffset = trie.length + 1; // +1 for this ULEB offset byte
  uint8_t offsetByte = (uint8_t)childOffset;
  [trie appendBytes:&offsetByte length:1];

  // Child node: terminal with address, no children
  [self appendTerminalNode:trie address:address];
}

- (void)buildMultipleSymbolTrie:(NSMutableData *)trie
                        symbols:(NSArray<NSString *> *)symbolNames {
  // 1. Build all terminal nodes first so we know their sizes
  NSMutableArray *terminalNodes = [NSMutableArray array];
  for (NSString *symbol in symbolNames) {
    NSMutableData *terminalNode = [NSMutableData data];
    uint64_t address = [self.symbols[symbol] unsignedLongLongValue];
    [self appendTerminalNode:terminalNode address:address];
    [terminalNodes addObject:terminalNode];
  }

  // 2. Root node header
  uint8_t rootTerminalSize = 0;
  [trie appendBytes:&rootTerminalSize length:1];

  uint8_t numChildren = (uint8_t)symbolNames.count;
  [trie appendBytes:&numChildren length:1];

  // 3. Calculate start of terminal nodes
  // The terminal nodes will start after root header and all edges
  long currentOffset = trie.length;
  for (NSString *symbol in symbolNames) {
    const char *name = [symbol UTF8String];
    currentOffset += strlen(name) + 1; // name + null

    // We need to know how many bytes the offset ULEB128 will take.
    // For a flat trie, these offsets are small, but let's be safe.
    // We'll assume 1 byte for now and verify, or use a fixed size if possible.
    // Mach-O typically uses ULEB128.
    currentOffset += 1; // Placeholder for offset byte(s)
  }

  // 4. Write edges
  long terminalNodeStart = currentOffset;
  long runningTerminalOffset = terminalNodeStart;

  for (int i = 0; i < symbolNames.count; i++) {
    NSString *symbol = symbolNames[i];
    const char *name = [symbol UTF8String];
    [trie appendBytes:name length:strlen(name) + 1];

    // Write offset to the terminal node as ULEB128
    [self writeULEB128:runningTerminalOffset toData:trie];

    NSData *terminalNode = terminalNodes[i];
    runningTerminalOffset += terminalNode.length;
  }

  // 5. Write terminal nodes
  for (NSData *terminalNode in terminalNodes) {
    [trie appendData:terminalNode];
  }
}

- (void)appendTerminalNode:(NSMutableData *)trie address:(uint64_t)address {
  // Build terminal info: flags + address ULEB128
  NSMutableData *terminalInfo = [NSMutableData data];
  uint8_t flags = 0x00; // EXPORT_SYMBOL_FLAGS_KIND_REGULAR
  [terminalInfo appendBytes:&flags length:1];
  [self writeULEB128:address toData:terminalInfo];

  // Write terminal size + terminal info
  uint8_t termSize = (uint8_t)terminalInfo.length;
  [trie appendBytes:&termSize length:1];
  [trie appendData:terminalInfo];

  // No children
  uint8_t noChildren = 0;
  [trie appendBytes:&noChildren length:1];
}

- (int)trieSize {
  return [[self class] trieSizeForSymbols:self.symbols.allKeys];
}

+ (int)trieSizeForSymbols:(NSArray<NSString *> *)symbols {
  // Compute size based on symbols
  int size = 0;
  for (NSString *symbol in symbols) {
    size += 1 + (int)[symbol length] + 1 +
            10; // node info + symbol + terminator + uleb128 data
  }
  size += 16; // Root node overhead
  size = MAX(size, 8);
  // Pad to 8-byte alignment for proper symbol table alignment
  size = (size + 7) & ~7;
  return size;
}

- (void)dealloc {
  [_symbols release];
  [super dealloc];
}

@end

#import <MPWFoundation/DebugMacros.h>

@implementation MPWExportsTrieWriter (testing)

+ (void)testEmptyTrieHasMinimalStructure {
  MPWExportsTrieWriter *writer = [[[self alloc] init] autorelease];
  NSData *trie = [writer trieData];

  INTEXPECT(trie.length, 2, @"empty trie should be 2 bytes");
  const uint8_t *bytes = trie.bytes;
  INTEXPECT(bytes[0], 0, @"first byte should be 0 (no terminal info)");
  INTEXPECT(bytes[1], 0, @"second byte should be 0 (no children)");
}

+ (void)testSingleSymbolTrie {
  MPWExportsTrieWriter *writer = [[[self alloc] init] autorelease];
  [writer addSymbol:@"_answer" atAddress:0x1000];

  NSData *trie = [writer trieData];
  EXPECTTRUE(trie.length > 2, @"trie with symbol should be larger than empty");

  // Verify structure: root has no terminal, one child
  const uint8_t *bytes = trie.bytes;
  INTEXPECT(bytes[0], 0, @"root has no terminal info");
  INTEXPECT(bytes[1], 1, @"root has one child");

  // Edge label should be "_answer" (full symbol name including underscore)
  EXPECTTRUE(memcmp(bytes + 2, "_answer", 7) == 0,
             @"edge label should be '_answer'");
}

+ (void)testTrieContainsAddress {
  MPWExportsTrieWriter *writer = [[[self alloc] init] autorelease];
  [writer addSymbol:@"_test" atAddress:0x1234];

  NSData *trie = [writer trieData];

  // The address 0x1234 encoded in ULEB128 is: 0xB4 0x24
  // (0x1234 = 0x24 << 7 | 0x34, so bytes are 0x34|0x80=0xB4, then 0x24)
  const uint8_t *bytes = trie.bytes;
  long len = trie.length;

  // Find the ULEB128 sequence for 0x1234 somewhere in the trie
  BOOL foundAddress = NO;
  for (int i = 0; i < len - 1; i++) {
    if (bytes[i] == 0xB4 && bytes[i + 1] == 0x24) {
      foundAddress = YES;
      break;
    }
  }
  EXPECTTRUE(foundAddress, @"trie should contain address 0x1234 as ULEB128");
}

+ (void)testMultipleSymbolsTrie {
  MPWExportsTrieWriter *writer = [[[self alloc] init] autorelease];
  [writer addSymbol:@"_foo" atAddress:0x1000];
  [writer addSymbol:@"_bar" atAddress:0x2000];

  NSData *trie = [writer trieData];

  // Verify root has two children
  const uint8_t *bytes = trie.bytes;
  INTEXPECT(bytes[0], 0, @"root has no terminal info");
  INTEXPECT(bytes[1], 2, @"root has two children");
}

+ (void)testTrieSizeIsAligned {
  MPWExportsTrieWriter *writer = [[[self alloc] init] autorelease];
  [writer addSymbol:@"_test" atAddress:0x1000];

  int size = [writer trieSize];
  INTEXPECT(size % 8, 0, @"trie size should be 8-byte aligned");
}

+ (void)testULEB128EncodingSmallValue {
  MPWExportsTrieWriter *writer = [[[self alloc] init] autorelease];
  NSData *encoded = [writer uleb128ForValue:0x7F];

  INTEXPECT(encoded.length, 1, @"0x7F fits in one byte");
  const uint8_t *bytes = encoded.bytes;
  INTEXPECT(bytes[0], 0x7F, @"single byte value");
}

+ (void)testULEB128EncodingTwoBytes {
  MPWExportsTrieWriter *writer = [[[self alloc] init] autorelease];
  NSData *encoded = [writer uleb128ForValue:0x80];

  INTEXPECT(encoded.length, 2, @"0x80 needs two bytes");
  const uint8_t *bytes = encoded.bytes;
  INTEXPECT(bytes[0], 0x80, @"first byte with continuation");
  INTEXPECT(bytes[1], 0x01, @"second byte");
}

+ (void)testULEB128EncodingTypicalAddress {
  MPWExportsTrieWriter *writer = [[[self alloc] init] autorelease];
  // 0x1000 = 4096
  // ULEB128: 0x80 0x20
  NSData *encoded = [writer uleb128ForValue:0x1000];

  INTEXPECT(encoded.length, 2, @"0x1000 needs two bytes");
  const uint8_t *bytes = encoded.bytes;
  INTEXPECT(bytes[0], 0x80, @"first byte");
  INTEXPECT(bytes[1], 0x20, @"second byte");
}

+ (NSArray *)testSelectors {
  return @[
    @"testEmptyTrieHasMinimalStructure",
    @"testSingleSymbolTrie",
    @"testTrieContainsAddress",
    @"testMultipleSymbolsTrie",
    @"testTrieSizeIsAligned",
    @"testULEB128EncodingSmallValue",
    @"testULEB128EncodingTwoBytes",
    @"testULEB128EncodingTypicalAddress",
  ];
}

@end
