//
//  MPWELFSection.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 02.05.24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWELFReader;

@interface MPWELFSection : NSObject



-(instancetype)initWithSectionNumber:(int)secNo reader:(MPWELFReader*)sectionHeaderPtr;
-(int)sectionType;
-(long)sectionOffset;
-(long)sectionSize;
-(long)numEntries;
-(long)entrySize;
-(int)sectionNameOffset;
-(long)dataOffsetForOffset:(long)offset;
-(NSString*)sectionName;

@property (nonatomic, assign) int sectionNumber;
@property (readonly) MPWELFReader* reader;

@end

NS_ASSUME_NONNULL_END
