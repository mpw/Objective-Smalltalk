//
//  MPWObjectFileWriter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 06.05.24.
//

#import "STObjectFileWriter.h"
#import "MPWStringTableWriter.h"

@interface STObjectFileWriter()

@property (nonatomic, strong) MPWStringTableWriter *stringTableWriter;
@property (nonatomic, strong) NSMutableDictionary *globalSymbolOffsets;
@property (nonatomic, strong) NSMutableSet *externalSymbolNames;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSDictionary*> *symbolAddressInfo;

@end

@implementation STObjectFileWriter

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.stringTableWriter = [MPWStringTableWriter writer];
    self.globalSymbolOffsets=[NSMutableDictionary dictionary];
    self.externalSymbolNames=[NSMutableSet set];
    self.symbolAddressInfo=[NSMutableDictionary dictionary];
    return self;
}

-(int)stringTableOffsetOfString:(NSString*)theString
{
    return [self.stringTableWriter stringTableOffsetOfString:theString];
}

-(void)generateStringTable
{
    for (NSString* symbol in self.globalSymbolOffsets.allKeys) {
        [self stringTableOffsetOfString:symbol];
    }
}

-(void)writeSymtabEntryOfType:(int)theType section:(int)theSection stringOffset:(int)stringOffset address:(long)addreess
{
    [NSException raise:@"unimplemented" format:@"writeSymtabEntryOfType not implemented"];
}

-(void)growSymtab
{
    [NSException raise:@"unimplemented" format:@"growSymtab not implemented"];
}


-(int)declareGlobalSymbol:(NSString*)symbol atOffset:(int)offset type:(int)theType section:(int)theSection
{
    int entryIndex = 0;
    NSNumber *offsetEntry = self.globalSymbolOffsets[symbol];
    if ( offsetEntry == nil ) {
        entryIndex = symtabCount;
        //        NSLog(@"symtab[%d]=%@",symtabCount,symbol);
        self.globalSymbolOffsets[symbol]=@(symtabCount);
        if ( symtabCount >= symtabCapacity ) {
            [self growSymtab];
        }
        int stringOffset=[self stringTableOffsetOfString:symbol];

        [self writeSymtabEntryOfType:theType section:theSection stringOffset:stringOffset address:offset];

        // Store address info for linker to use
        self.symbolAddressInfo[symbol] = @{
            @"section": @(theSection),
            @"offset": @(offset)
        };
    } else {
        entryIndex = [offsetEntry intValue];
    }
    return entryIndex;
}

-(int)globalFuncSymbolType
{
    return 0xf;     // Mach-O, overriden for ELF
}

-(int)textSectionNumber
{
    return 1;       // Mach-O, and should compute
}

-(int)declareGlobalSymbol:(NSString*)symbol atOffset:(int)offset
{
    return [self declareGlobalSymbol:symbol atOffset:offset type:[self globalFuncSymbolType] section:[self textSectionNumber]];
}

-(int)sectionNumberForExternalSymbols
{
    return 0;       // Mach-O, and should compute
}

-(int)typeForExternalSymbols
{
    return 0x1;       // Mach-O, and should compute this magic number somehow
}


-(int)declareExternalSymbol:(NSString*)symbol
{
    [self.externalSymbolNames addObject:symbol];
    return [self declareGlobalSymbol:symbol atOffset:0 type:self.typeForExternalSymbols section:self.sectionNumberForExternalSymbols];
}



-(void)dealloc
{
    [_stringTableWriter release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STObjectFileWriter(testing) 

+(void)testCanWriteStringsToStringTable
{
    STObjectFileWriter *writer = [self stream];
    INTEXPECT( [writer stringTableOffsetOfString:@"_add"],1,@"offset");
    INTEXPECT( [writer stringTableOffsetOfString:@"_sub"],6,@"offset");
    INTEXPECT( [writer stringTableOffsetOfString:@"_add"],1,@"repeat");
}

+(NSArray*)testSelectors
{
   return @[
       @"testCanWriteStringsToStringTable",
			];
}

@end
