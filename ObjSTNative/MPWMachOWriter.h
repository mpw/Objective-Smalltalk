//
//  MPWMachOWriter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.09.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWMachOWriter : MPWByteStream

@property (nonatomic, strong) NSDictionary *globalSymbols;
@property (nonatomic, strong) NSData *textSection;

@end

NS_ASSUME_NONNULL_END
