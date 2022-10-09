//
//  MPWMachOInSectionPointer.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 09.10.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWMachOSection,MPWMachORelocationPointer;

@interface MPWMachOInSectionPointer : NSObject

@property (readonly) MPWMachOSection *section;
@property (readonly) long offset;


-(instancetype)initWithSection:(MPWMachOSection*)section offset:(long)offset;
-(const void*)bytes;
-(BOOL)hasRelocEntry;
-(instancetype)pointerAtOffset:(long)relativeOffset;
-(MPWMachORelocationPointer*)relocationPointer;
-(MPWMachORelocationPointer*)relocationPointerAtOffset:(long)offset;
-(instancetype)targetPointerAtOffset:(long)relativeOffset;


@end

NS_ASSUME_NONNULL_END
