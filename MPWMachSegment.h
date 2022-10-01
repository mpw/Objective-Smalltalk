//
//  MPWMachSegment.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 01.10.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWMachSegment : NSObject

-(instancetype)initWithSegmentPointer:(const void*)segptr;

@end

NS_ASSUME_NONNULL_END
