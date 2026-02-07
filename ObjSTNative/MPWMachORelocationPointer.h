//
//  MPWMachOPointer.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 08.10.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class STMachOSection,MPWMachOInSectionPointer;

@interface MPWMachORelocationPointer : NSObject

-(instancetype)initWithSection:(STMachOSection*)section relocEntryIndex:(int)relocEntryIndex;
-(STMachOSection*)targetSection;
-(long)targetOffset;
-(int)indexOfSymtabEntry;
-(MPWMachOInSectionPointer*)targetPointer;

@property (readonly) STMachOSection *section;
@property (readonly) long offset;
@property (readonly) NSString *targetName;
@property (readonly) int targetSectionIndex;

@end

NS_ASSUME_NONNULL_END
