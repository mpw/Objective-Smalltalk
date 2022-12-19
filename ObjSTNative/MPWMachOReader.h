//
//  MPWMachOReader.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 09.09.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWMachOSection,MPWMachORelocationPointer,MPWMachOClassReader,MPWMachOInSectionPointer;

@interface MPWMachOReader : NSObject

@property (readonly) NSData *data;
@property (readonly) int numSections;
@property (readonly) int numberOfClassReferences;


+(instancetype)readerWithData:(NSData*)machodata;
-(instancetype)initWithData:(NSData*)machodata;
-(BOOL)isHeaderValid;
-(int)filetype;
-(int)cputype;
-(int)numLoadCommands;

-(long)segmentOffset;
-(long)segmentSize;
-(const void*)segmentBytes;


-(NSArray<NSString*>*)stringTable;
-(int)numSymbols;

-(NSString*)symbolNameAt:(int)which;
-(long)symbolOffsetAt:(int)which;
-(int)sectionForSymbolAt:(int)which;
-(bool)isSymbolGlobalAt:(int)which;
-(int)indexOfSymbolNamed:(NSString*)symbol;


-(MPWMachOSection*)textSection;
-(MPWMachOSection*)objcClassNameSection;
-(MPWMachOSection*)objcClassReadOnlySection;
-(MPWMachOSection*)objcClassListSection;
-(MPWMachOSection*)objcMethodNamesSection;
-(MPWMachOSection*)objcDataSection;
-(MPWMachOSection*)cfstringSection;
-(MPWMachOSection*)sectionAtIndex:(int)sectionIndex;
-(NSArray<MPWMachORelocationPointer*>*)classPointers;
-(NSArray<MPWMachORelocationPointer*>*)classReferences;

-(NSArray<MPWMachOClassReader*>*)classReaders;
-(MPWMachOInSectionPointer*)pointerForSymbolAt:(int)symbolIndex;


-(void)dumpRelocationsOn:(MPWByteStream*)s;

-(void)verifyBlockDescriptor:(MPWMachOInSectionPointer*)descriptorPointer signature:(NSString*)signature signatureSymbol:(NSString*)symbol;
-(MPWMachOInSectionPointer*)verifyBlockAndReturnDescriptor:(MPWMachOInSectionPointer *)blockPointer codeSymbol:(NSString*)codeSymbol descriptorSymbol:(NSString*)descriptorSymbol;


@end

NS_ASSUME_NONNULL_END
