//
//  MPWARMObjectCodeGenerator.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.09.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWARMObjectCodeGenerator : MPWByteStream

@property (nonatomic, strong)  NSDictionary *symbolOffsets;

@end

@protocol SymbolWriter

@end


NS_ASSUME_NONNULL_END
