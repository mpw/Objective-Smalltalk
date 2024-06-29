//
//  MPWELFRelocationTable.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.06.24.
//

#import "MPWELFSection.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPWELFRelocationTable : MPWELFSection

-(int)typeOfRelocEntryAt:(int)offset;
-(int)offsetOfRelocEntryAt:(int)offset;
-(int)symbolIndexAtOffset:(int)offset;


@end

NS_ASSUME_NONNULL_END
