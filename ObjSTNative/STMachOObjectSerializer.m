//
//  MPWMachOObjectSerializer.m
//  ObjSTNative
//
//  Created by Codex on 2026-02-06.
//

#import "STMachOObjectSerializer.h"
#import "STMachOWriter.h"
#import "STMachOSectionWriter.h"
#import "STMachODylibWriter.h"
#import "STMachOReader.h"
#import "STMachOSegment.h"
#import "STMachOSection.h"
#import <mach-o/loader.h>

@interface STMachOObjectSerializer ()

@property (nonatomic, assign, readwrite) STMachOWriter *writer;
@property (nonatomic, assign, readwrite) STMachOSectionWriter *literalSectionWriter;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *stringSymbols;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *cstringSymbols;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *numberSymbols;
@property (nonatomic, strong) NSMapTable<id, NSString *> *objectSymbols;
@property (nonatomic, copy) NSString *lastSymbol;
@property (nonatomic, assign) int stringCounter;
@property (nonatomic, assign) int cstringCounter;
@property (nonatomic, assign) int numberCounter;
@property (nonatomic, assign) int arrayCounter;
@property (nonatomic, assign) int dictCounter;
@property (nonatomic, assign) int arrayDataCounter;

@end

@implementation STMachOObjectSerializer

- (instancetype)initWithWriter:(STMachOWriter *)writer {
    STMachOSectionWriter *defaultLiteralWriter =
    [writer addSectionWriterWithSegName:@"__DATA_CONST"
                               sectName:@"__objcliterals"
                                  flags:0];
    defaultLiteralWriter.alignment = 3;
    return [self initWithWriter:writer literalSectionWriter:defaultLiteralWriter];
}

- (instancetype)initWithWriter:(STMachOWriter *)writer
            literalSectionWriter:(STMachOSectionWriter *)literalSectionWriter {
    self = [super initWithTarget:[NSMutableData data]];
    if (self) {
        self.writer = writer;
        self.literalSectionWriter = literalSectionWriter;
        self.stringSymbols = [NSMutableDictionary dictionary];
        self.cstringSymbols = [NSMutableDictionary dictionary];
        self.numberSymbols = [NSMutableDictionary dictionary];
        self.objectSymbols = [NSMapTable mapTableWithKeyOptions:NSMapTableObjectPointerPersonality
                                               valueOptions:NSMapTableStrongMemory];
    }
    return self;
}

- (SEL)streamWriterMessage {
    return @selector(writeOnMachOObject:);
}

- (NSString *)symbolForObject:(id)object {
    self.lastSymbol = nil;
    [self writeObject:object];
    if (!self.lastSymbol) {
        [NSException raise:@"unsupported" format:@"No Mach-O symbol for object: %@ (%@)", object, [object class]];
    }
    return self.lastSymbol;
}

- (NSString *)symbolForCString:(NSString *)string {
    NSString *existing = self.cstringSymbols[string];
    if (existing) {
        return existing;
    }
    self.cstringCounter++;
    NSString *label = [NSString stringWithFormat:@"_OBJC_LITERAL_CSTR_%d", self.cstringCounter];
    [self.literalSectionWriter declareLocalSymbol:label];
    const char *bytes = [string UTF8String];
    [self.literalSectionWriter appendBytes:bytes length:strlen(bytes)];
    [self.literalSectionWriter appendBytes:"" length:1];
    self.cstringSymbols[string] = label;
    self.lastSymbol = label;
    return label;
}

- (NSString *)symbolForString:(NSString *)string {
    NSString *existing = self.stringSymbols[string];
    if (existing) {
        self.lastSymbol = existing;
        return existing;
    }
    self.stringCounter++;
    NSString *label = [NSString stringWithFormat:@"_OBJC_LITERAL_CFSTR_%d", self.stringCounter];
    [self.writer writeNSStringLiteral:string label:label];
    self.stringSymbols[string] = label;
    self.lastSymbol = label;
    return label;
}

- (void)alignLiteralSectionToPointerBoundary {
    while (([self.literalSectionWriter length] & 7) != 0) {
        uint8_t zero = 0;
        [self.literalSectionWriter appendBytes:&zero length:1];
    }
}

- (NSString *)symbolForNumber:(NSNumber *)number {
    const char *type = [number objCType];
    if (!type || !(type[0] == 'c' || type[0] == 'i' || type[0] == 's' || type[0] == 'l' || type[0] == 'q' ||
                   type[0] == 'C' || type[0] == 'I' || type[0] == 'S' || type[0] == 'L' || type[0] == 'Q' ||
                   type[0] == 'B')) {
        [NSException raise:@"unsupported" format:@"Unsupported NSNumber objCType '%s'", type ? type : "(null)"];
    }
    NSString *key = [NSString stringWithFormat:@"i:%lld", [number longLongValue]];
    NSString *existing = self.numberSymbols[key];
    if (existing) {
        self.lastSymbol = existing;
        return existing;
    }
    
    self.numberCounter++;
    NSString *label = [NSString stringWithFormat:@"_OBJC_LITERAL_INT_%d", self.numberCounter];
    
    NSString *typeSymbol = [self symbolForCString:@"i"];
    [self alignLiteralSectionToPointerBoundary];
    STMachOSectionWriter *intWriter = self.literalSectionWriter;
    [intWriter declareLocalSymbol:label];
    
    [self.writer declareExternalSymbol:@"_OBJC_CLASS_$_NSConstantIntegerNumber"];
    
    uint64_t value = (uint64_t)[number longLongValue];
    struct {
        uint64_t isa;
        uint64_t type;
        uint64_t value;
    } obj = {0, 0, value};
    
    [intWriter addRelocationEntryForSymbol:@"_OBJC_CLASS_$_NSConstantIntegerNumber"
                                  atOffset:(int)[intWriter length]];
    [intWriter addRelocationEntryForSymbol:typeSymbol
                                  atOffset:(int)([intWriter length] + sizeof(uint64_t))];
    [intWriter appendBytes:&obj length:sizeof(obj)];
    
    self.numberSymbols[key] = label;
    self.lastSymbol = label;
    return label;
}

- (NSString *)symbolForArray:(NSArray *)array {
    NSString *existing = [self.objectSymbols objectForKey:array];
    if (existing) {
        self.lastSymbol = existing;
        return existing;
    }

    NSMutableArray<NSString *> *elementSymbols = [NSMutableArray arrayWithCapacity:array.count];
    for (id element in array) {
        NSString *elementSymbol = [self symbolForObject:element];
        [elementSymbols addObject:elementSymbol];
    }

    self.arrayDataCounter++;
    NSString *dataLabel = [NSString stringWithFormat:@"_OBJC_LITERAL_ARRAYDATA_%d", self.arrayDataCounter];
    [self alignLiteralSectionToPointerBoundary];
    STMachOSectionWriter *arrayDataWriter = self.literalSectionWriter;
    [arrayDataWriter declareLocalSymbol:dataLabel];
    for (NSString *elementSymbol in elementSymbols) {
        [arrayDataWriter addRelocationEntryForSymbol:elementSymbol atOffset:(int)[arrayDataWriter length]];
        uint64_t zero = 0;
        [arrayDataWriter appendBytes:&zero length:sizeof(zero)];
    }

    self.arrayCounter++;
    NSString *arrayLabel = [NSString stringWithFormat:@"_OBJC_LITERAL_ARRAY_%d", self.arrayCounter];
    [self alignLiteralSectionToPointerBoundary];
    STMachOSectionWriter *arrayObjWriter = self.literalSectionWriter;
    [arrayObjWriter declareLocalSymbol:arrayLabel];
    
    [self.writer declareExternalSymbol:@"_OBJC_CLASS_$_NSConstantArray"];
    
    struct {
        uint64_t isa;
        uint64_t count;
        uint64_t objects;
    } arrayObj = {0, (uint64_t)array.count, 0};
    
    [arrayObjWriter addRelocationEntryForSymbol:@"_OBJC_CLASS_$_NSConstantArray"
                                       atOffset:(int)[arrayObjWriter length]];
    [arrayObjWriter addRelocationEntryForSymbol:dataLabel
                                       atOffset:(int)([arrayObjWriter length] + sizeof(uint64_t) * 2)];
    [arrayObjWriter appendBytes:&arrayObj length:sizeof(arrayObj)];
    
    [self.objectSymbols setObject:arrayLabel forKey:array];
    self.lastSymbol = arrayLabel;
    return arrayLabel;
}

- (NSString *)symbolForDictionary:(NSDictionary *)dict {
    NSString *existing = [self.objectSymbols objectForKey:dict];
    if (existing) {
        self.lastSymbol = existing;
        return existing;
    }
    
    STMachOSectionWriter *arrayDataWriter = self.literalSectionWriter;
    NSArray *orderedKeys = [[dict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [[obj1 description] compare:[obj2 description]];
    }];

    NSMutableArray<NSString *> *keySymbols = [NSMutableArray arrayWithCapacity:orderedKeys.count];
    NSMutableArray<NSString *> *valueSymbols = [NSMutableArray arrayWithCapacity:orderedKeys.count];
    for (id key in orderedKeys) {
        [keySymbols addObject:[self symbolForObject:key]];
        [valueSymbols addObject:[self symbolForObject:dict[key]]];
    }

    self.arrayDataCounter++;
    NSString *keysLabel = [NSString stringWithFormat:@"_OBJC_LITERAL_DICTKEYS_%d", self.arrayDataCounter];
    [self alignLiteralSectionToPointerBoundary];
    [arrayDataWriter declareLocalSymbol:keysLabel];
    for (NSString *keySymbol in keySymbols) {
        [arrayDataWriter addRelocationEntryForSymbol:keySymbol atOffset:(int)[arrayDataWriter length]];
        uint64_t zero = 0;
        [arrayDataWriter appendBytes:&zero length:sizeof(zero)];
    }
    
    self.arrayDataCounter++;
    NSString *valuesLabel = [NSString stringWithFormat:@"_OBJC_LITERAL_DICTVALS_%d", self.arrayDataCounter];
    [self alignLiteralSectionToPointerBoundary];
    [arrayDataWriter declareLocalSymbol:valuesLabel];
    for (NSString *valueSymbol in valueSymbols) {
        [arrayDataWriter addRelocationEntryForSymbol:valueSymbol atOffset:(int)[arrayDataWriter length]];
        uint64_t zero = 0;
        [arrayDataWriter appendBytes:&zero length:sizeof(zero)];
    }
    
    self.dictCounter++;
    NSString *dictLabel = [NSString stringWithFormat:@"_OBJC_LITERAL_DICT_%d", self.dictCounter];
    [self alignLiteralSectionToPointerBoundary];
    STMachOSectionWriter *dictObjWriter = self.literalSectionWriter;
    [dictObjWriter declareLocalSymbol:dictLabel];
    
    [self.writer declareExternalSymbol:@"_OBJC_CLASS_$_NSConstantDictionary"];
    
    struct {
        uint64_t isa;
        uint64_t flags;
        uint64_t count;
        uint64_t keys;
        uint64_t values;
    } dictObj = {0, 1, (uint64_t)dict.count, 0, 0};
    
    [dictObjWriter addRelocationEntryForSymbol:@"_OBJC_CLASS_$_NSConstantDictionary"
                                      atOffset:(int)[dictObjWriter length]];
    [dictObjWriter addRelocationEntryForSymbol:keysLabel
                                      atOffset:(int)([dictObjWriter length] + sizeof(uint64_t) * 3)];
    [dictObjWriter addRelocationEntryForSymbol:valuesLabel
                                      atOffset:(int)([dictObjWriter length] + sizeof(uint64_t) * 4)];
    [dictObjWriter appendBytes:&dictObj length:sizeof(dictObj)];
    
    [self.objectSymbols setObject:dictLabel forKey:dict];
    self.lastSymbol = dictLabel;
    return dictLabel;
}

@end

#pragma mark - Streaming Categories

@implementation NSString (MPWMachOObjectStreaming)

- (void)writeOnMachOObject:(STMachOObjectSerializer *)writer {
    writer.lastSymbol = [writer symbolForString:self];
}

@end

@implementation NSNumber (MPWMachOObjectStreaming)

- (void)writeOnMachOObject:(STMachOObjectSerializer *)writer {
    writer.lastSymbol = [writer symbolForNumber:self];
}

@end

@implementation NSArray (MPWMachOObjectStreaming)

- (void)writeOnMachOObject:(STMachOObjectSerializer *)writer {
    writer.lastSymbol = [writer symbolForArray:self];
}

@end

@implementation NSDictionary (MPWMachOObjectStreaming)

- (void)writeOnMachOObject:(STMachOObjectSerializer *)writer {
    writer.lastSymbol = [writer symbolForDictionary:self];
}

@end

#import <MPWFoundation/DebugMacros.h>

@implementation STMachOObjectSerializer(testing)

+ (NSArray<NSString *> *)allSymbolNamesInReader:(STMachOReader *)reader {
    NSMutableArray *names = [NSMutableArray array];
    for (int i = 0; i < [reader numSymbols]; i++) {
        NSString *name = [reader symbolNameAt:i];
        if (name.length > 0) {
            [names addObject:name];
        }
    }
    return names;
}

+ (BOOL)symbols:(NSArray<NSString *> *)symbols containName:(NSString *)name {
    return [symbols containsObject:name];
}

+ (NSInteger)countSymbols:(NSArray<NSString *> *)symbols withPrefix:(NSString *)prefix {
    NSInteger count = 0;
    for (NSString *symbol in symbols) {
        if ([symbol hasPrefix:prefix]) {
            count++;
        }
    }
    return count;
}

+ (STMachOSection *)sectionNamed:(NSString *)sectionName inReader:(STMachOReader *)reader {
    for (STMachOSegment *segment in reader.segments) {
        STMachOSection *section = [segment sectionNamed:sectionName];
        if (section) {
            return section;
        }
    }
    return nil;
}

+ (void)testUsesSingleConfiguredLiteralSectionForNestedStructures {
    STMachODylibWriter *writer = [STMachODylibWriter stream];
    writer.installName = @"@rpath/libserializer-test.dylib";
    [writer useFoundationRuntimeLibraries];

    STMachOSectionWriter *literalWriter =
    [writer addSectionWriterWithSegName:@"__DATA_CONST"
                               sectName:@"__objclitcust"
                                  flags:0];
    literalWriter.alignment = 3;

    STMachOObjectSerializer *serializer =
    [[[STMachOObjectSerializer alloc] initWithWriter:writer
                                  literalSectionWriter:literalWriter] autorelease];

    NSDictionary *plistLikeLiteral = @{
        @"number": @42,
        @"array": @[ @2, @12, @"some string", @[ @"nested", @"array", @55 ], @99 ]
    };
    NSString *rootSymbol = [serializer symbolForObject:plistLikeLiteral];

    STMachOSectionWriter *dataWriter = [writer addSectionWriterWithSegName:@"__DATA"
                                                                   sectName:@"__data"
                                                                      flags:0];
    [dataWriter declareGlobalSymbol:@"_serializer_root_literal"];
    [dataWriter addRelocationEntryForSymbol:rootSymbol atOffset:(int)[dataWriter length]];
    uint64_t zero = 0;
    [dataWriter appendBytes:&zero length:sizeof(zero)];

    [writer generateMachO];
    STMachOReader *reader = [STMachOReader readerWithData:writer.data];
    EXPECTTRUE([reader isHeaderValid], @"generated Mach-O should be valid");

    EXPECTNOTNIL([self sectionNamed:@"__objclitcust" inReader:reader],
                 @"custom literal section should exist");
    EXPECTNIL([self sectionNamed:@"__objc_arrayobj" inReader:reader],
              @"legacy __objc_arrayobj section should not be needed");
    EXPECTNIL([self sectionNamed:@"__objc_arraydata" inReader:reader],
              @"legacy __objc_arraydata section should not be needed");
    EXPECTNIL([self sectionNamed:@"__objc_dictobj" inReader:reader],
              @"legacy __objc_dictobj section should not be needed");
    EXPECTNIL([self sectionNamed:@"__objc_intobj" inReader:reader],
              @"legacy __objc_intobj section should not be needed");

    NSArray<NSString *> *symbols = [self allSymbolNamesInReader:reader];
    EXPECTTRUE([self symbols:symbols containName:rootSymbol],
               @"root dictionary symbol should be present");
    EXPECTTRUE([self symbols:symbols containName:@"_serializer_root_literal"],
               @"exported root pointer symbol should be present");
    EXPECTTRUE([self countSymbols:symbols withPrefix:@"_OBJC_LITERAL_ARRAY_"] >= 2,
               @"nested array serialization should create nested array symbols");
    EXPECTTRUE([self countSymbols:symbols withPrefix:@"_OBJC_LITERAL_DICT_"] >= 1,
               @"dictionary serialization should create dictionary symbol");
}

+ (void)testIncrementalSymbolWritingKeepsStableTopLevelSymbols {
    STMachODylibWriter *writer = [STMachODylibWriter stream];
    writer.installName = @"@rpath/libserializer-incremental.dylib";
    [writer useFoundationRuntimeLibraries];

    STMachOObjectSerializer *serializer =
    [[[STMachOObjectSerializer alloc] initWithWriter:writer] autorelease];

    NSString *numberSymbol = [serializer symbolForObject:@42];
    NSString *numberSymbolAgain = [serializer symbolForObject:@42];
    IDEXPECT(numberSymbol, numberSymbolAgain,
             @"re-serializing identical number should reuse symbol");

    NSArray *nestedArray = @[ @2, @12, @"some string", @[ @"nested", @"array", @55 ], @99 ];
    NSString *arraySymbol = [serializer symbolForObject:nestedArray];
    NSString *arraySymbolAgain = [serializer symbolForObject:nestedArray];
    IDEXPECT(arraySymbol, arraySymbolAgain,
             @"re-serializing same array object should reuse symbol");

    NSDictionary *dict = @{ @"number": @42, @"array": nestedArray };
    NSString *dictSymbol = [serializer symbolForObject:dict];
    EXPECTTRUE([dictSymbol hasPrefix:@"_OBJC_LITERAL_DICT_"],
               @"top-level dictionary symbol should be dictionary symbol");

    STMachOSectionWriter *dataWriter = [writer addSectionWriterWithSegName:@"__DATA"
                                                                   sectName:@"__data"
                                                                      flags:0];
    uint64_t zero = 0;
    [dataWriter declareGlobalSymbol:@"_serializer_number_root"];
    [dataWriter addRelocationEntryForSymbol:numberSymbol atOffset:(int)[dataWriter length]];
    [dataWriter appendBytes:&zero length:sizeof(zero)];

    [dataWriter declareGlobalSymbol:@"_serializer_array_root"];
    [dataWriter addRelocationEntryForSymbol:arraySymbol atOffset:(int)[dataWriter length]];
    [dataWriter appendBytes:&zero length:sizeof(zero)];

    [dataWriter declareGlobalSymbol:@"_serializer_dict_root"];
    [dataWriter addRelocationEntryForSymbol:dictSymbol atOffset:(int)[dataWriter length]];
    [dataWriter appendBytes:&zero length:sizeof(zero)];

    [writer generateMachO];
    STMachOReader *reader = [STMachOReader readerWithData:writer.data];
    EXPECTTRUE([reader isHeaderValid], @"generated Mach-O should be valid");

    EXPECTNOTNIL([self sectionNamed:@"__objcliterals" inReader:reader],
                 @"default serializer should use one literal section");

    NSArray<NSString *> *symbols = [self allSymbolNamesInReader:reader];
    EXPECTTRUE([self symbols:symbols containName:numberSymbol], @"number symbol should exist");
    EXPECTTRUE([self symbols:symbols containName:arraySymbol], @"array symbol should exist");
    EXPECTTRUE([self symbols:symbols containName:dictSymbol], @"dict symbol should exist");
    EXPECTTRUE([self countSymbols:symbols withPrefix:@"_OBJC_LITERAL_ARRAY_"] >= 2,
               @"nested structures should create multiple array symbols");
}

+ (NSArray *)testSelectors {
    return @[
        @"testUsesSingleConfiguredLiteralSectionForNestedStructures",
        @"testIncrementalSymbolWritingKeepsStableTopLevelSymbols",
    ];
}

@end
