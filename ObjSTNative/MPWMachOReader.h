//
//  MPWMachOReader.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 09.09.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWMachOReader : NSObject

-(instancetype)initWithData:(NSData*)machodata;
-(BOOL)isHeaderValid;
-(int)filetype;
-(int)cputype;
-(int)numLoadCommands;
-(NSArray<NSString*>*)stringTable;
-(int)numSymbols;
-(int)numRelocEntries;
-(int)relocEntryOffset;

-(NSString*)symbolNameAt:(int)which;
-(long)symbolOffsetAt:(int)which;
-(bool)isSymbolGlobalAt:(int)which;

-(NSString*)nameOfRelocEntryAt:(int)i;
-(long)offsetOfRelocEntryAt:(int)i;
-(bool)isExternalRelocEntryAt:(int)i;
-(int)typeOfRelocEntryAt:(int)i;


-(NSData*)textSection;


@end

NS_ASSUME_NONNULL_END
