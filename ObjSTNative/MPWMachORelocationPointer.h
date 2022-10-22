//
//  MPWMachOPointer.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 08.10.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWMachOSection,MPWMachOInSectionPointer;

@interface MPWMachORelocationPointer : NSObject

-(instancetype)initWithSection:(MPWMachOSection*)section relocEntryIndex:(int)relocEntryIndex;
-(MPWMachOSection*)targetSection;
-(long)targetOffset;
-(int)indexOfSymtabEntry;
-(MPWMachOInSectionPointer*)targetPointer;

@property (readonly) MPWMachOSection *section;
@property (readonly) long offset;
@property (readonly) NSString *targetName;
@property (readonly) int targetSectionIndex;

@end

NS_ASSUME_NONNULL_END
