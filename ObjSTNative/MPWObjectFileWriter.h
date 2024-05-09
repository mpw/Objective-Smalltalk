//
//  MPWObjectFileWriter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 06.05.24.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWStringTableWriter;

@interface MPWObjectFileWriter : MPWByteStream
{
    int symtabCount;
    int symtabCapacity;
}

-(int)stringTableOffsetOfString:(NSString*)theString;

@property (readonly) MPWStringTableWriter *stringTableWriter;
@property (readonly) NSMutableDictionary *globalSymbolOffsets;

-(void)writeSymtabEntryOfType:(int)theType section:(int)theSection stringOffset:(int)stringOffset address:(long)addreess;
-(int)declareGlobalSymbol:(NSString*)symbol atOffset:(int)offset type:(int)theType section:(int)theSection;
-(int)declareGlobalSymbol:(NSString*)symbol atOffset:(int)offset;
-(int)declareExternalSymbol:(NSString*)symbol;

@end

NS_ASSUME_NONNULL_END
