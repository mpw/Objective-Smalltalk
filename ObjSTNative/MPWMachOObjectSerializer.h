//
//  MPWMachOObjectSerializer.h
//  ObjSTNative
//
//  Created by Codex on 2026-02-06.
//

#import <MPWFoundation/MPWFoundation.h>

@class STMachOWriter;

NS_ASSUME_NONNULL_BEGIN

@interface MPWMachOObjectSerializer : MPWByteStream

@property (nonatomic, assign, readonly) STMachOWriter *writer;

- (instancetype)initWithWriter:(STMachOWriter *)writer;
- (NSString *)symbolForObject:(id)object;

@end

NS_ASSUME_NONNULL_END
