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

@property (nonatomic, assign) long offset;

-(void)writeSectionLoadCommandOnWriter:(MPWMachOWriter*)writer;

@end

NS_ASSUME_NONNULL_END
