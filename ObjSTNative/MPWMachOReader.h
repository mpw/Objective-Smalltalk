//
//  MPWMachOReader.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 09.09.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWMachOSection;

@interface MPWMachOReader : NSObject

@property (readonly) NSData *data;
@property (readonly) int numSections;


-(instancetype)initWithData:(NSData*)machodata;
-(BOOL)isHeaderValid;
-(int)filetype;
-(int)cputype;
-(int)numLoadCommands;

-(long)segmentOffset;
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
-(MPWMachOSection*)sectionAtIndex:(int)sectionIndex;


@end

NS_ASSUME_NONNULL_END
