//
//  MPWMachOSection.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.10.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWMachOSection : NSObject

-(instancetype)initWithSectionHeader:(const void*)headerptr inMacho:(NSData*)bytes;
-(NSData*)sectionData;

-(NSString*)nameOfRelocEntryAt:(int)i;
-(long)offsetOfRelocEntryAt:(int)i;
-(bool)isExternalRelocEntryAt:(int)i;
-(int)typeOfRelocEntryAt:(int)i;
-(int)numRelocEntries;
-(int)relocEntryOffset;


@end

NS_ASSUME_NONNULL_END
