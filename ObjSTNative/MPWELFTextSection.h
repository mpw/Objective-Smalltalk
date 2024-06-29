//
//  MPWELFTextSection.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.06.24.
//

#import "MPWELFSection.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPWELFTextSection : MPWELFSection

-(int)typeOfRelocEntryAt:(int)offset;
-(int)offsetOfRelocEntryAt:(int)offset;


@end

NS_ASSUME_NONNULL_END
