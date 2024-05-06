//
//  MPWELFSectionWriter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 06.05.24.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWELFSectionWriter : MPWByteStream

@property (nonatomic, assign) int sectionType;
@property (nonatomic, assign) int sectionNumber;

-(void)writeSctioHeaderOnWriter:(MPWByteStream*)writer;


@end

NS_ASSUME_NONNULL_END
