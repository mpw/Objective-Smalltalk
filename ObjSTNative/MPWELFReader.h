//
//  MPWELFReader.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.05.23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWELFSection,MPWELFSymbolTable,MPWELFRelocationTable;

@interface MPWELFReader : NSObject

-(const void*)sectionHeaderPointerAtIndex:(int)numSection;

@property (readonly) NSData *elfData;

-(NSString*)stringAtOffset:(long)offset;
-(NSString*)sectionNameAtOffset:(long)offset;
-(instancetype)initWithData:(NSData*)newData;

-(BOOL)isHeaderValid;
-(int)elfType;
-(int)elfClass;
-(int)elfEndianness;
-(int)elfMachine;
-(int)elfVersion;
-(int)numProgramHeaders;
-(int)programHeaderEntrySize;
-(int)numSectionHeaders;
-(int)sectionHeaderEntrySize;
-(long)sectionHeaderOffset;
-(MPWELFSection*)stringTable;
-(MPWELFSection*)sectionStringTable;
-(MPWELFSection*)sectionAtIndex:(int)numSection;
-(MPWELFSection*)findElfSectionOfType:(int)type name:(nullable NSString*)name;

@property (readonly) MPWELFSymbolTable* symbolTable;
@property (readonly) MPWELFSection* sectionStringTable;
@property (readonly) MPWELFRelocationTable* textRelocationTable;

@end

NS_ASSUME_NONNULL_END
