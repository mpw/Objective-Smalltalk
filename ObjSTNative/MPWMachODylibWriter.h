//
//  MPWMachODylibWriter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.01.26.
//

#import "MPWMachOWriter.h"

NS_ASSUME_NONNULL_BEGIN

@class MPWBindOpcodeWriter;

@interface MPWMachODylibWriter : MPWMachOWriter

@property (nonatomic, strong) NSString *installName;
@property (nonatomic, assign) uint32_t currentVersion;      // e.g., 0x10000 for 1.0.0
@property (nonatomic, assign) uint32_t compatibilityVersion; // e.g., 0x10000 for 1.0.0
@property (nonatomic, strong, nullable) MPWBindOpcodeWriter *bindOpcodeWriter;
@property (nonatomic, strong, readonly) NSMutableArray *frameworks;

@end

NS_ASSUME_NONNULL_END
