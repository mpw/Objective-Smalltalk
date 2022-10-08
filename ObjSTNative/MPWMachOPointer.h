//
//  MPWMachOPointer.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 08.10.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWMachOSection;

@interface MPWMachOPointer : NSObject

-(instancetype)initWithSection:(MPWMachOSection*)section relocEntryIndex:(int)relocEntryIndex;
-(MPWMachOSection*)targetSection;
-(long)targetOffset:(long)relativeOffset;
-(long)targetOffset;
-(int)indexOfSymtabEntryAtRelativeOffset:(long)relativeOffset;

@property (readonly) MPWMachOSection *section;
@property (readonly) long offset;
@property (readonly) NSString *name;

@end

NS_ASSUME_NONNULL_END
