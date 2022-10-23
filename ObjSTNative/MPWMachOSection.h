//
//  MPWMachOSection.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.10.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWMachOReader;

@interface MPWMachOSection : NSObject

-(instancetype)initWithSectionHeader:(const void*)headerptr inMacho:(MPWMachOReader*)newReader;

-(NSString*)nameOfRelocEntryAt:(int)i;
-(long)offsetOfRelocEntryAt:(int)i;
-(bool)isExternalRelocEntryAt:(int)i;
-(int)typeOfRelocEntryAt:(int)i;
-(long)offset;
-(long)size;
-(long)offsetInTargetSectionForRelocEntryAt:(int)which;
-(int)indexOfRelocationEntryAtOffset:(long)offset;
-(int)indexOfSymboltableEntryAtOffset:(long)offset;
-(int)numRelocEntries;
-(int)relocEntryOffset;
-(MPWMachOSection*)sectionForRelocEntryAt:(int)which;
-(NSArray<NSString*>*)strings;


-(NSData*)sectionData;
-(const void*)bytes;
-(const void*)segmentBytes;

-(NSString*)objcClassName;
-(NSString*)sectionName;
-(NSString*)segmentName;


@end

NS_ASSUME_NONNULL_END
