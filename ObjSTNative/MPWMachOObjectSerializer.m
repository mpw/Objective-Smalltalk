//
//  MPWMachOObjectSerializer.m
//  ObjSTNative
//
//  Created by Codex on 2026-02-06.
//

#import "MPWMachOObjectSerializer.h"
#import "MPWMachOWriter.h"
#import "MPWMachOSectionWriter.h"
#import <mach-o/loader.h>

@interface MPWMachOObjectSerializer ()

@property (nonatomic, assign, readwrite) MPWMachOWriter *writer;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *stringSymbols;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *cstringSymbols;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *numberSymbols;
@property (nonatomic, strong) NSMapTable<id, NSString *> *objectSymbols;
@property (nonatomic, strong) MPWMachOSectionWriter *arrayDataWriter;
@property (nonatomic, strong) MPWMachOSectionWriter *arrayObjWriter;
@property (nonatomic, strong) MPWMachOSectionWriter *dictObjWriter;
@property (nonatomic, strong) MPWMachOSectionWriter *intObjWriter;
@property (nonatomic, copy) NSString *lastSymbol;
@property (nonatomic, assign) int stringCounter;
@property (nonatomic, assign) int cstringCounter;
@property (nonatomic, assign) int numberCounter;
@property (nonatomic, assign) int arrayCounter;
@property (nonatomic, assign) int dictCounter;
@property (nonatomic, assign) int arrayDataCounter;

@end

@implementation MPWMachOObjectSerializer

+testSelectors { return @[]; }

- (instancetype)initWithWriter:(MPWMachOWriter *)writer {
    self = [super initWithTarget:[NSMutableData data]];
    if (self) {
        _writer = writer;
        _stringSymbols = [NSMutableDictionary dictionary];
        _cstringSymbols = [NSMutableDictionary dictionary];
        _numberSymbols = [NSMutableDictionary dictionary];
        _objectSymbols = [NSMapTable mapTableWithKeyOptions:NSMapTableObjectPointerPersonality
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
    MPWMachOSectionWriter *cstringWriter = [self.writer addSectionWriterWithSegName:@"__TEXT"
                                                                           sectName:@"__cstring"
                                                                              flags:S_CSTRING_LITERALS];
    cstringWriter.alignment = 1;
    [cstringWriter declareLocalSymbol:label];
    const char *bytes = [string UTF8String];
    [cstringWriter appendBytes:bytes length:strlen(bytes)];
    [cstringWriter appendBytes:"" length:1];
    self.cstringSymbols[string] = label;
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

- (MPWMachOSectionWriter *)arrayDataSectionWriter {
    if (!self.arrayDataWriter) {
        self.arrayDataWriter = [self.writer addSectionWriterWithSegName:@"__DATA_CONST"
                                                               sectName:@"__objc_arraydata"
                                                                  flags:0];
        self.arrayDataWriter.alignment = 3;
    }
    return self.arrayDataWriter;
}

- (MPWMachOSectionWriter *)arrayObjSectionWriter {
    if (!self.arrayObjWriter) {
        self.arrayObjWriter = [self.writer addSectionWriterWithSegName:@"__DATA_CONST"
                                                              sectName:@"__objc_arrayobj"
                                                                 flags:0];
        self.arrayObjWriter.alignment = 3;
    }
    return self.arrayObjWriter;
}

- (MPWMachOSectionWriter *)dictObjSectionWriter {
    if (!self.dictObjWriter) {
        self.dictObjWriter = [self.writer addSectionWriterWithSegName:@"__DATA_CONST"
                                                             sectName:@"__objc_dictobj"
                                                                flags:0];
        self.dictObjWriter.alignment = 3;
    }
    return self.dictObjWriter;
}

- (MPWMachOSectionWriter *)intObjSectionWriter {
    if (!self.intObjWriter) {
        self.intObjWriter = [self.writer addSectionWriterWithSegName:@"__DATA_CONST"
                                                            sectName:@"__objc_intobj"
                                                               flags:0];
        self.intObjWriter.alignment = 3;
    }
    return self.intObjWriter;
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
    MPWMachOSectionWriter *intWriter = [self intObjSectionWriter];
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
    
    self.arrayDataCounter++;
    NSString *dataLabel = [NSString stringWithFormat:@"_OBJC_LITERAL_ARRAYDATA_%d", self.arrayDataCounter];
    MPWMachOSectionWriter *arrayDataWriter = [self arrayDataSectionWriter];
    [arrayDataWriter declareLocalSymbol:dataLabel];
    
    for (id element in array) {
        NSString *elementSymbol = [self symbolForObject:element];
        [arrayDataWriter addRelocationEntryForSymbol:elementSymbol atOffset:(int)[arrayDataWriter length]];
        uint64_t zero = 0;
        [arrayDataWriter appendBytes:&zero length:sizeof(zero)];
    }
    
    self.arrayCounter++;
    NSString *arrayLabel = [NSString stringWithFormat:@"_OBJC_LITERAL_ARRAY_%d", self.arrayCounter];
    MPWMachOSectionWriter *arrayObjWriter = [self arrayObjSectionWriter];
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
    
    MPWMachOSectionWriter *arrayDataWriter = [self arrayDataSectionWriter];
    
    self.arrayDataCounter++;
    NSString *keysLabel = [NSString stringWithFormat:@"_OBJC_LITERAL_DICTKEYS_%d", self.arrayDataCounter];
    [arrayDataWriter declareLocalSymbol:keysLabel];
    for (id key in dict) {
        NSString *keySymbol = [self symbolForObject:key];
        [arrayDataWriter addRelocationEntryForSymbol:keySymbol atOffset:(int)[arrayDataWriter length]];
        uint64_t zero = 0;
        [arrayDataWriter appendBytes:&zero length:sizeof(zero)];
    }
    
    self.arrayDataCounter++;
    NSString *valuesLabel = [NSString stringWithFormat:@"_OBJC_LITERAL_DICTVALS_%d", self.arrayDataCounter];
    [arrayDataWriter declareLocalSymbol:valuesLabel];
    for (id key in dict) {
        id value = dict[key];
        NSString *valueSymbol = [self symbolForObject:value];
        [arrayDataWriter addRelocationEntryForSymbol:valueSymbol atOffset:(int)[arrayDataWriter length]];
        uint64_t zero = 0;
        [arrayDataWriter appendBytes:&zero length:sizeof(zero)];
    }
    
    self.dictCounter++;
    NSString *dictLabel = [NSString stringWithFormat:@"_OBJC_LITERAL_DICT_%d", self.dictCounter];
    MPWMachOSectionWriter *dictObjWriter = [self dictObjSectionWriter];
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

- (void)writeOnMachOObject:(MPWMachOObjectSerializer *)writer {
    [writer symbolForString:self];
}

@end

@implementation NSNumber (MPWMachOObjectStreaming)

- (void)writeOnMachOObject:(MPWMachOObjectSerializer *)writer {
    [writer symbolForNumber:self];
}

@end

@implementation NSArray (MPWMachOObjectStreaming)

- (void)writeOnMachOObject:(MPWMachOObjectSerializer *)writer {
    [writer symbolForArray:self];
}

@end

@implementation NSDictionary (MPWMachOObjectStreaming)

- (void)writeOnMachOObject:(MPWMachOObjectSerializer *)writer {
    [writer symbolForDictionary:self];
}

@end
