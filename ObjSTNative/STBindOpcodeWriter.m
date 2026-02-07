//
//  MPWBindOpcodeWriter.m
//  ObjSTNative
//
//  Writes bind and rebase opcodes for Mach-O dylibs
//

#import "STBindOpcodeWriter.h"
#import <mach-o/loader.h>

@implementation MPWBindEntry
@end

@implementation MPWRebaseEntry
@end

@interface STBindOpcodeWriter()
@property (nonatomic, strong) NSMutableArray<MPWBindEntry*> *bindEntries;
@property (nonatomic, strong) NSMutableArray<MPWRebaseEntry*> *rebaseEntries;
@end

@implementation STBindOpcodeWriter

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.bindEntries = [NSMutableArray array];
        self.rebaseEntries = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Adding Entries

-(void)addBindForSymbol:(NSString*)symbol
              fromDylib:(int)dylibOrdinal
            atSegment:(int)segmentIndex
               offset:(long)offset
               addend:(long)addend
{
    MPWBindEntry *entry = [[[MPWBindEntry alloc] init] autorelease];
    entry.symbolName = symbol;
    entry.dylibOrdinal = dylibOrdinal;
    entry.segmentIndex = segmentIndex;
    entry.segmentOffset = offset;
    entry.type = BIND_TYPE_POINTER;
    entry.addend = addend;
    [self.bindEntries addObject:entry];
}

-(void)addBindForSymbol:(NSString*)symbol
              fromDylib:(int)dylibOrdinal
            atSegment:(int)segmentIndex
               offset:(long)offset
{
    [self addBindForSymbol:symbol fromDylib:dylibOrdinal atSegment:segmentIndex offset:offset addend:0];
}

-(void)addBindForSymbol:(NSString*)symbol atSegment:(int)segmentIndex offset:(long)offset
{
    // Use flat namespace lookup (special ordinal -2)
    [self addBindForSymbol:symbol fromDylib:BIND_SPECIAL_DYLIB_FLAT_LOOKUP atSegment:segmentIndex offset:offset];
}

-(void)addRebaseAtSegment:(int)segmentIndex offset:(long)offset
{
    MPWRebaseEntry *entry = [[[MPWRebaseEntry alloc] init] autorelease];
    entry.segmentIndex = segmentIndex;
    entry.segmentOffset = offset;
    entry.type = REBASE_TYPE_POINTER;
    [self.rebaseEntries addObject:entry];
}

#pragma mark - ULEB128 Encoding

// Encode unsigned LEB128
-(void)appendULEB128:(unsigned long)value toData:(NSMutableData*)data
{
    do {
        uint8_t byte = value & 0x7F;
        value >>= 7;
        if (value != 0) {
            byte |= 0x80;  // More bytes to follow
        }
        [data appendBytes:&byte length:1];
    } while (value != 0);
}

// Encode signed LEB128
-(void)appendSLEB128:(long)value toData:(NSMutableData*)data
{
    BOOL more = YES;
    while (more) {
        uint8_t byte = value & 0x7F;
        value >>= 7;
        // Check if sign bit needs extending
        BOOL signBit = (byte & 0x40) != 0;
        if ((value == 0 && !signBit) || (value == -1 && signBit)) {
            more = NO;
        } else {
            byte |= 0x80;
        }
        [data appendBytes:&byte length:1];
    }
}

#pragma mark - Bind Opcodes

-(NSData*)bindOpcodeData
{
    NSMutableData *data = [NSMutableData data];

    // Sort entries by segment, then offset for efficient encoding
    NSArray *sorted = [self.bindEntries sortedArrayUsingComparator:^NSComparisonResult(MPWBindEntry *a, MPWBindEntry *b) {
        if (a.segmentIndex != b.segmentIndex) {
            return a.segmentIndex < b.segmentIndex ? NSOrderedAscending : NSOrderedDescending;
        }
        if (a.segmentOffset != b.segmentOffset) {
            return a.segmentOffset < b.segmentOffset ? NSOrderedAscending : NSOrderedDescending;
        }
        return NSOrderedSame;
    }];

    int currentSegment = -1;
    long currentOffset = 0;
    int currentType = -1;
    int currentDylib = 0;

    for (MPWBindEntry *entry in sorted) {
        // Set dylib ordinal if changed
        if (entry.dylibOrdinal != currentDylib) {
            if (entry.dylibOrdinal > 0 && entry.dylibOrdinal <= 15) {
                // Ordinal fits in immediate
                uint8_t opcode = BIND_OPCODE_SET_DYLIB_ORDINAL_IMM | (entry.dylibOrdinal & BIND_IMMEDIATE_MASK);
                [data appendBytes:&opcode length:1];
            } else if (entry.dylibOrdinal > 15) {
                // Need ULEB for large ordinal
                uint8_t opcode = BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB;
                [data appendBytes:&opcode length:1];
                [self appendULEB128:entry.dylibOrdinal toData:data];
            } else {
                // Special ordinal (negative values)
                uint8_t opcode = BIND_OPCODE_SET_DYLIB_SPECIAL_IMM | (entry.dylibOrdinal & BIND_IMMEDIATE_MASK);
                [data appendBytes:&opcode length:1];
            }
            currentDylib = entry.dylibOrdinal;
        }

        // Set symbol name
        uint8_t symbolOpcode = BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM | 0; // flags = 0
        [data appendBytes:&symbolOpcode length:1];
        const char *name = [entry.symbolName UTF8String];
        [data appendBytes:name length:strlen(name) + 1];  // Include null terminator

        // Set type if changed
        if (entry.type != currentType) {
            uint8_t opcode = BIND_OPCODE_SET_TYPE_IMM | (entry.type & BIND_IMMEDIATE_MASK);
            [data appendBytes:&opcode length:1];
            currentType = entry.type;
        }

        // Set segment and offset
        if (entry.segmentIndex != currentSegment || entry.segmentOffset != currentOffset) {
            uint8_t opcode = BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB | (entry.segmentIndex & BIND_IMMEDIATE_MASK);
            [data appendBytes:&opcode length:1];
            [self appendULEB128:entry.segmentOffset toData:data];
            currentSegment = entry.segmentIndex;
            currentOffset = entry.segmentOffset;
        }

        // Set addend if non-zero
        if (entry.addend != 0) {
            uint8_t opcode = BIND_OPCODE_SET_ADDEND_SLEB;
            [data appendBytes:&opcode length:1];
            [self appendSLEB128:entry.addend toData:data];
        }

        // Do the bind
        uint8_t bindOpcode = BIND_OPCODE_DO_BIND;
        [data appendBytes:&bindOpcode length:1];
        currentOffset += 8;  // Pointer size for arm64
    }

    // Done
    uint8_t doneOpcode = BIND_OPCODE_DONE;
    [data appendBytes:&doneOpcode length:1];

    return data;
}

#pragma mark - Rebase Opcodes

-(NSData*)rebaseOpcodeData
{
    NSMutableData *data = [NSMutableData data];

    if (self.rebaseEntries.count == 0) {
        // Empty rebase info - just DONE
        uint8_t done = REBASE_OPCODE_DONE;
        [data appendBytes:&done length:1];
        return data;
    }

    // Sort entries by segment, then offset
    NSArray *sorted = [self.rebaseEntries sortedArrayUsingComparator:^NSComparisonResult(MPWRebaseEntry *a, MPWRebaseEntry *b) {
        if (a.segmentIndex != b.segmentIndex) {
            return a.segmentIndex < b.segmentIndex ? NSOrderedAscending : NSOrderedDescending;
        }
        if (a.segmentOffset != b.segmentOffset) {
            return a.segmentOffset < b.segmentOffset ? NSOrderedAscending : NSOrderedDescending;
        }
        return NSOrderedSame;
    }];

    int currentSegment = -1;
    long currentOffset = 0;
    int currentType = -1;

    for (MPWRebaseEntry *entry in sorted) {
        // Set type if changed
        if (entry.type != currentType) {
            uint8_t opcode = REBASE_OPCODE_SET_TYPE_IMM | (entry.type & REBASE_IMMEDIATE_MASK);
            [data appendBytes:&opcode length:1];
            currentType = entry.type;
        }

        // Set segment and offset if segment changed
        if (entry.segmentIndex != currentSegment) {
            uint8_t opcode = REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB | (entry.segmentIndex & REBASE_IMMEDIATE_MASK);
            [data appendBytes:&opcode length:1];
            [self appendULEB128:entry.segmentOffset toData:data];
            currentSegment = entry.segmentIndex;
            currentOffset = entry.segmentOffset;
        } else if (entry.segmentOffset != currentOffset) {
            // Same segment, different offset - add to current offset
            long delta = entry.segmentOffset - currentOffset;
            if (delta > 0 && delta <= 15 * 8) {
                // Can use scaled immediate
                int scaledDelta = (int)(delta / 8);
                uint8_t opcode = REBASE_OPCODE_ADD_ADDR_IMM_SCALED | (scaledDelta & REBASE_IMMEDIATE_MASK);
                [data appendBytes:&opcode length:1];
            } else {
                uint8_t opcode = REBASE_OPCODE_ADD_ADDR_ULEB;
                [data appendBytes:&opcode length:1];
                [self appendULEB128:delta toData:data];
            }
            currentOffset = entry.segmentOffset;
        }

        // Do the rebase
        uint8_t rebaseOpcode = REBASE_OPCODE_DO_REBASE_IMM_TIMES | 1;  // Rebase 1 time
        [data appendBytes:&rebaseOpcode length:1];
        currentOffset += 8;  // Pointer size for arm64
    }

    // Done
    uint8_t doneOpcode = REBASE_OPCODE_DONE;
    [data appendBytes:&doneOpcode length:1];

    return data;
}

-(void)dealloc
{
    [_bindEntries release];
    [_rebaseEntries release];
    [super dealloc];
}

@end


#pragma mark - Tests

#import <MPWFoundation/DebugMacros.h>

@implementation STBindOpcodeWriter(testing)

+(void)testEmptyBindProducesDone
{
    STBindOpcodeWriter *writer = [[[self alloc] init] autorelease];
    NSData *bindData = [writer bindOpcodeData];
    EXPECTTRUE(bindData.length == 1, @"should be just DONE opcode");
    const uint8_t *bytes = bindData.bytes;
    INTEXPECT(bytes[0], BIND_OPCODE_DONE, @"should be DONE");
}

+(void)testEmptyRebaseProducesDone
{
    STBindOpcodeWriter *writer = [[[self alloc] init] autorelease];
    NSData *rebaseData = [writer rebaseOpcodeData];
    EXPECTTRUE(rebaseData.length == 1, @"should be just DONE opcode");
    const uint8_t *bytes = rebaseData.bytes;
    INTEXPECT(bytes[0], REBASE_OPCODE_DONE, @"should be DONE");
}

+(void)testSingleBindEntry
{
    STBindOpcodeWriter *writer = [[[self alloc] init] autorelease];
    [writer addBindForSymbol:@"_objc_msgSend" fromDylib:1 atSegment:1 offset:0x100];

    NSData *bindData = [writer bindOpcodeData];
    EXPECTTRUE(bindData.length > 1, @"should have opcodes");

    // Verify structure: should have dylib ordinal, symbol name, type, segment+offset, bind, done
    const uint8_t *bytes = bindData.bytes;

    // First byte should set dylib ordinal 1
    INTEXPECT(bytes[0] & BIND_OPCODE_MASK, BIND_OPCODE_SET_DYLIB_ORDINAL_IMM, @"should set dylib");
    INTEXPECT(bytes[0] & BIND_IMMEDIATE_MASK, 1, @"dylib ordinal should be 1");
}

+(void)testSingleRebaseEntry
{
    STBindOpcodeWriter *writer = [[[self alloc] init] autorelease];
    [writer addRebaseAtSegment:1 offset:0x100];

    NSData *rebaseData = [writer rebaseOpcodeData];
    EXPECTTRUE(rebaseData.length > 1, @"should have opcodes");

    const uint8_t *bytes = rebaseData.bytes;

    // First byte should set type
    INTEXPECT(bytes[0] & REBASE_OPCODE_MASK, REBASE_OPCODE_SET_TYPE_IMM, @"should set type");
}

+(void)testMultipleBindEntries
{
    STBindOpcodeWriter *writer = [[[self alloc] init] autorelease];
    [writer addBindForSymbol:@"_objc_msgSend" fromDylib:1 atSegment:1 offset:0x100];
    [writer addBindForSymbol:@"_objc_alloc" fromDylib:1 atSegment:1 offset:0x108];

    NSData *bindData = [writer bindOpcodeData];
    // Should encode both binds
    EXPECTTRUE(bindData.length > 20, @"should have opcodes for both symbols");

    // Last byte should be DONE
    const uint8_t *bytes = bindData.bytes;
    INTEXPECT(bytes[bindData.length - 1], BIND_OPCODE_DONE, @"should end with DONE");
}

+(void)testFlatNamespaceBind
{
    STBindOpcodeWriter *writer = [[[self alloc] init] autorelease];
    [writer addBindForSymbol:@"_someSymbol" atSegment:1 offset:0x200];

    NSData *bindData = [writer bindOpcodeData];
    const uint8_t *bytes = bindData.bytes;

    // Should use special dylib ordinal for flat lookup
    INTEXPECT(bytes[0] & BIND_OPCODE_MASK, BIND_OPCODE_SET_DYLIB_SPECIAL_IMM, @"should use special dylib");
}

+(NSArray*)testSelectors
{
    return @[
        @"testEmptyBindProducesDone",
        @"testEmptyRebaseProducesDone",
        @"testSingleBindEntry",
        @"testSingleRebaseEntry",
        @"testMultipleBindEntries",
        @"testFlatNamespaceBind",
    ];
}

@end
