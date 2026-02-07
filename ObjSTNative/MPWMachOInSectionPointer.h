//
//  MPWMachOInSectionPointer.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 09.10.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class STMachOSection,MPWMachORelocationPointer;

@interface MPWMachOInSectionPointer : NSObject

@property (readonly) STMachOSection *section;
@property (readonly) long offset;


-(instancetype)initWithSection:(STMachOSection*)section offset:(long)offset;
-(const void*)bytes;
-(NSString*)stringValue;        // of a cString
-(NSString*)cfStringValue;      // of an NSString / CFString
-(BOOL)hasRelocEntry;
-(instancetype)pointerAtOffset:(long)relativeOffset;
-(MPWMachORelocationPointer*)relocationPointer;
-(MPWMachORelocationPointer*)relocationPointerAtOffset:(long)offset;
-(instancetype)targetPointerAtOffset:(long)relativeOffset;


@end

NS_ASSUME_NONNULL_END
