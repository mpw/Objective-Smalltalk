//
//  STMachOObjectFileLoader.h
//  ObjSTNative
//
//  Loads Mach-O object files (.o) directly into executable memory
//  without dlopen, avoiding code signing requirements.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class STJittableData;

@interface STMachOObjectFileLoader : NSObject

/// Load an object file from NSData. Copies sections into executable memory
/// and resolves relocations.
-(instancetype)initWithData:(NSData*)objectFileData;

/// Look up a function pointer by symbol name (with leading underscore).
/// Returns NULL if the symbol is not found.
-(void* _Nullable)functionPointerForSymbol:(NSString*)symbolName;

/// The executable memory backing the loaded code.
@property (nonatomic, readonly) STJittableData *executableMemory;

/// Errors encountered during loading (symbol resolution failures, etc.)
@property (nonatomic, readonly) NSArray<NSString*> *errors;

@end

NS_ASSUME_NONNULL_END
