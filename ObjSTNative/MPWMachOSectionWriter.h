//
//  MPWMachOSectionWriter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.10.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWMachOWriter;

@interface MPWMachOSectionWriter : MPWByteStream

-(void)writeSectionLoadCommandOnWriter:(MPWMachOWriter*)writer offset:(long)offset;

@end

NS_ASSUME_NONNULL_END
