//
//  MPWELFReader.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.05.23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWELFSection,MPWELFSymbolTable;

@interface MPWELFReader : NSObject

-(const void*)sectionHeaderPointerAtIndex:(int)numSection;

@property (readonly) NSData *elfData;

-(NSString*)stringAtOffset:(long)offset;
-(instancetype)initWithData:(NSData*)newData;

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
-(MPWELFSection*)sectionAtIndex:(int)numSection;


@property (readonly) MPWELFSymbolTable* symbolTable;

@end

NS_ASSUME_NONNULL_END
