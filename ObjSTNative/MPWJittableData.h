//
//  MPWJittableData.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 26.09.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWJittableData : NSObject

-(instancetype)initWithCapacity:(long)initialCapacity;
-(unsigned const char*)bytes;
-(unsigned char*)mutableBytes;
-(void)appendBytes:(const void*)newBytes length:(long)newLength;
-(long)length;
-(long)capacity;
-(void)makeExecutable;
-(void)makeWritable;


@end

NS_ASSUME_NONNULL_END
