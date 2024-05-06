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
@property (nonatomic, assign) long sectionOffset;
@property (nonatomic, strong) NSData* sectionData;
@property (readonly) long sectionLength;

-(void)writeSctionHeaderOnWriter:(MPWByteStream*)writer;
-(void)writeSectionDataOnWriter:(MPWByteStream*)writer;


@end

NS_ASSUME_NONNULL_END
