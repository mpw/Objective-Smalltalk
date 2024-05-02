//
//  MPWELFSection.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 02.05.24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWELFSection : NSObject



-(instancetype)initWithSectionHeaderPointer:(const void*)sectionHeaderPtr;
-(int)sectionType;
-(long)sectionOffset;
-(long)sectionSize;
-(long)sectionNameOffset;
-(long)dataOffsetForOffset:(long)offset;

@end

NS_ASSUME_NONNULL_END
