//
//  MPWMachOReader.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 09.09.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWMachOReader : NSObject

-(instancetype)initWithData:(NSData*)machodata;
-(BOOL)isHeaderValid;

@end

NS_ASSUME_NONNULL_END
