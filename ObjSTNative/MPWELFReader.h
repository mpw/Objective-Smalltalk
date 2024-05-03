//
//  MPWELFReader.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.05.23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWELFReader : NSObject

-(const void*)sectionHeaderPointerAtIndex:(int)numSection;
@property (readonly) NSData *elfData;

-(NSString*)stringAtOffset:(long)offset;

@end

NS_ASSUME_NONNULL_END
