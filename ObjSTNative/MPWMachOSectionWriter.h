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

-(void)writeSectionLoadCommandOnWriter:(MPWByteStream*)writer;
-(void)writeSectionDataOn:(MPWByteStream*)writer;
-(void)writeRelocationEntriesOn:(MPWByteStream*)writer;

-(void)declareGlobalSymbol:(NSString*)symbol;

-(long)totalSize;
-(BOOL)isActive;

@end

NS_ASSUME_NONNULL_END
