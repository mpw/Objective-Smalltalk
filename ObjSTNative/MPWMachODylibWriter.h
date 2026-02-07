//
//  MPWMachODylibWriter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.01.26.
//

#import "STMachOWriter.h"

NS_ASSUME_NONNULL_BEGIN

@class MPWBindOpcodeWriter;

@interface MPWMachODylibWriter : STMachOWriter

@property (nonatomic, strong) NSString *installName;
@property (nonatomic, assign) uint32_t currentVersion;      // e.g., 0x10000 for 1.0.0
@property (nonatomic, assign) uint32_t compatibilityVersion; // e.g., 0x10000 for 1.0.0
@property (nonatomic, strong, nullable) MPWBindOpcodeWriter *bindOpcodeWriter;
@property (nonatomic, strong, readonly) NSMutableArray *frameworks;

+ (instancetype)streamWithInstallName:(NSString *)installName
                     externalLibraries:(NSArray<NSString *> *)externalLibraries;
- (void)addExternalLibraryPath:(NSString *)path;
- (void)useFoundationRuntimeLibraries;
- (void)addExportedTextSymbol:(NSString *)symbol
                      codeData:(NSData *)codeData
                      atOffset:(NSUInteger)offset;
- (BOOL)writeSignedDylibToPath:(NSString *)path error:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
