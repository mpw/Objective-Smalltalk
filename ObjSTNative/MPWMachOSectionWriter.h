//
//  MPWMachOSectionWriter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.10.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWMachOWriter;
@protocol SymbolWriter;

@interface MPWMachOSectionWriter : MPWByteStream 

@property (nonatomic, assign) long offset;
@property (nonatomic, assign) long address;
@property (nonatomic, assign) long relocationEntryOffset;

@property (nonatomic) long sectionNumber;
@property (nonatomic, weak) id <SymbolWriter> symbolWriter;
@property (nonatomic, strong) NSString *segname;
@property (nonatomic, strong) NSString *sectname;
@property (nonatomic, assign) int flags;
@property (nonatomic, assign) int relocationType;
@property (nonatomic, assign) int relocationLength;
@property (nonatomic, assign) int relocationPCRel;
@property (nonatomic, assign) int alignment;

-(void)writeSectionLoadCommandOnWriter:(MPWByteStream*)writer;
-(void)writeSectionDataOn:(MPWByteStream*)writer;
-(void)writeRelocationEntriesOn:(MPWByteStream*)writer;

-(void)declareGlobalSymbol:(NSString*)symbol;
-(void)declareLocalSymbol:(NSString*)symbol;

-(void)declareGlobalTextSymbol:(NSString*)symbol;
-(void)addRelocationEntryForSymbol:(NSString*)symbol atOffset:(int)offset;
-(void)addRelocationEntryForSymbol:(NSString*)symbol atOffset:(int)offset type:(int)type relative:(BOOL)relative;

-(long)sectionDataSize;
-(long)relocEntrySize;
-(long)totalSize;
-(BOOL)isActive;

@end

NS_ASSUME_NONNULL_END
