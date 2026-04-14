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
#import "STMultiSymbolCounter.h"

@interface STMachOObjectSerializer ()

@property (nonatomic, assign, readwrite) STMachOWriter *writer;
@property (nonatomic, assign, readwrite) STMachOSectionWriter *literalSectionWriter;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *cstringSymbols;
@property (nonatomic, strong) NSMapTable<id, NSString *> *objectSymbols;
@property (nonatomic, copy) NSString *lastSymbol;
@property (nonatomic, assign) int stringCounter;
@property (nonatomic, assign) int cstringCounter;
@property (nonatomic, assign) int numberCounter;
@property (nonatomic, assign) int arrayCounter;
@property (nonatomic, assign) int dictCounter;
@property (nonatomic, assign) int arrayDataCounter;
@property (nonatomic, strong) STMultiSymbolCounter *symbolCounter;

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
        self.cstringSymbols = [NSMutableDictionary dictionary];
        self.objectSymbols = [NSMapTable mapTableWithKeyOptions:NSMapTableObjectPointerPersonality
                                                   valueOptions:NSMapTableStrongMemory];
        self.symbolCounter = [[STMultiSymbolCounter new] autorelease];
    }
    return self;
}

-(NSString*)nextSymbolForTemplate:(NSString*)string
{
    return [self.symbolCounter nextSymbolForTemplate:string];
}
- (SEL)streamWriterMessage {
    return @selector(writeOnMachOObject:);
}



- (void)writeObject:(id)object {
    self.lastSymbol = nil;
    NSString *existing = [self.objectSymbols objectForKey:object];
    if (existing) {
        self.lastSymbol = existing;
        return;
    }
    
    [super writeObject:object];
    if (!self.lastSymbol) {
        [NSException raise:@"unsupported" format:@"No Mach-O symbol for object: %@ (%@)", object, [object class]];
    } else {
        [self.objectSymbols setObject:self.lastSymbol forKey:object];
    }
}

- (NSString *)symbolForObject:(id)object {
    [self writeObject:object];
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
//    NSString *existing = [self.objectSymbols objectForKey:string];
//    if (existing) {
//        self.lastSymbol = existing;
//        return existing;
//    }
    self.stringCounter++;
    NSString *label = [NSString stringWithFormat:@"_OBJC_LITERAL_CFSTR_%d", self.stringCounter];
    [self.writer writeNSStringLiteral:string label:label];
    [self.objectSymbols setObject:label forKey:string];
    self.lastSymbol = label;
    return label;
}

- (void)alignLiteralSectionToPointerBoundary {
    [self.literalSectionWriter alignToPointerBoundary];
}

- (NSString *)symbolForNumber:(NSNumber *)number {
    const char *type = [number objCType];
    if (!type || !(type[0] == 'c' || type[0] == 'i' || type[0] == 's' || type[0] == 'l' || type[0] == 'q' ||
                   type[0] == 'C' || type[0] == 'I' || type[0] == 'S' || type[0] == 'L' || type[0] == 'Q' ||
                   type[0] == 'B')) {
        [NSException raise:@"unsupported" format:@"Unsupported NSNumber objCType '%s'", type ? type : "(null)"];
    }
    NSString *key = [NSString stringWithFormat:@"i:%lld", [number longLongValue]];
//    NSString *existing = [self.objectSymbols objectForKey:key];
//    if (existing) {
//        self.lastSymbol = existing;
//        return existing;
//    }
    
    self.numberCounter++;
    NSString *label = [NSString stringWithFormat:@"_OBJC_LITERAL_INT_%d", self.numberCounter];
    
    NSString *typeSymbol = [self symbolForCString:@"i"];
    [self alignLiteralSectionToPointerBoundary];
    STMachOSectionWriter *intWriter = self.literalSectionWriter;
    [intWriter declareLocalSymbol:label];
    
    
    [intWriter writeClassReference:@"NSConstantIntegerNumber"];
    [intWriter writePointerForSymbol:typeSymbol];
    [intWriter writeInt64:[number longLongValue]];

    [self.objectSymbols setObject:label forKey:key];
    self.lastSymbol = label;
    return label;
}

-(NSArray*)symbolsForObjects:(NSArray*)objects
{
    NSMutableArray<NSString *> *elementSymbols = [NSMutableArray arrayWithCapacity:objects.count];
    for (id element in objects) {
        NSString *elementSymbol = [self symbolForObject:element];
        [elementSymbols addObject:elementSymbol];
    }
    return elementSymbols;
}

- (NSString *)symbolForArray:(NSArray *)array {
    STMachOSectionWriter *arrayObjWriter = self.literalSectionWriter;
//    NSString *existing = [self.objectSymbols objectForKey:array];
//    if (existing) {
//        self.lastSymbol = existing;
//        return existing;
//    }

    NSArray *elementSymbols = [self symbolsForObjects:array];
    
    
    // @"_OBJC_LITERAL_ARRAYDATA_%d"
    // @"_OBJC_LITERAL_ARRAY_%d"

    
    NSString *dataLabel = [self nextSymbolForTemplate:@"_OBJC_LITERAL_ARRAYDATA"];
    [arrayObjWriter writeArrayOfPointers:elementSymbols atLabel:dataLabel];


    NSString *arrayLabel = [self nextSymbolForTemplate:@"_OBJC_LITERAL_ARRAY"];
    [self alignLiteralSectionToPointerBoundary];
    [arrayObjWriter declareLocalSymbol:arrayLabel];
    

    [arrayObjWriter writeClassReference:@"NSConstantArray"];
    [arrayObjWriter writeInt64:array.count];
    [arrayObjWriter writePointerForSymbol:dataLabel];


    [self.objectSymbols setObject:arrayLabel forKey:array];
    self.lastSymbol = arrayLabel;
    return arrayLabel;
}

- (NSString *)symbolForDictionary:(NSDictionary *)dict {
//    NSString *existing = [self.objectSymbols objectForKey:dict];
//    if (existing) {
//        self.lastSymbol = existing;
//        return existing;
//    }
    
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
    [arrayDataWriter writeArrayOfPointers:keySymbols atLabel:keysLabel];
    
    self.arrayDataCounter++;
    NSString *valuesLabel = [NSString stringWithFormat:@"_OBJC_LITERAL_DICTVALS_%d", self.arrayDataCounter];
    [arrayDataWriter writeArrayOfPointers:valueSymbols atLabel:valuesLabel];
    
    self.dictCounter++;
    NSString *dictLabel = [NSString stringWithFormat:@"_OBJC_LITERAL_DICT_%d", self.dictCounter];
    [self alignLiteralSectionToPointerBoundary];
    STMachOSectionWriter *dictObjWriter = self.literalSectionWriter;
    [dictObjWriter declareLocalSymbol:dictLabel];
    
    [self.writer declareExternalSymbol:@"_OBJC_CLASS_$_NSConstantDictionary"];
        
    [dictObjWriter writeClassReference:@"NSConstantDictionary"];
    [dictObjWriter writeInt64:1];
    [dictObjWriter writeInt64:dict.count];
    [dictObjWriter writePointerForSymbol:keysLabel];
    [dictObjWriter writePointerForSymbol:valuesLabel];
    
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
