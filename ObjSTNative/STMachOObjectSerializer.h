//
//  MPWMachOObjectSerializer.h
//  ObjSTNative
//
//  Created by Codex on 2026-02-06.
//

#import <MPWFoundation/MPWFoundation.h>

@class STMachOWriter;
@class STMachOSectionWriter;

NS_ASSUME_NONNULL_BEGIN

@interface STMachOObjectSerializer : MPWByteStream

@property (nonatomic, assign, readonly) STMachOWriter *writer;
@property (nonatomic, assign, readonly) STMachOSectionWriter *literalSectionWriter;

- (instancetype)initWithWriter:(STMachOWriter *)writer;
- (instancetype)initWithWriter:(STMachOWriter *)writer
            literalSectionWriter:(STMachOSectionWriter *)literalSectionWriter;
- (NSString *)symbolForObject:(id)object;

@end

NS_ASSUME_NONNULL_END
