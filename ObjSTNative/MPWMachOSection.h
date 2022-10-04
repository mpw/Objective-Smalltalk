//
//  MPWMachOSection.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.10.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWMachOSection : NSObject

-(instancetype)initWithSectionHeader:(const void*)headerptr inMacho:(NSData*)bytes;

@end

NS_ASSUME_NONNULL_END
