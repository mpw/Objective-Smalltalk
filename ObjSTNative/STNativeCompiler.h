//
//  STNativeCompiler.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.10.22.
//

#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

NS_ASSUME_NONNULL_BEGIN

@class STObjectCodeGeneratorARM;
@class MPWMachOWriter;

@interface STNativeCompiler : STCompiler

@property (readonly) bool jit;
@property (nonatomic, assign) bool logging;

+(instancetype)jitCompiler;
+(instancetype)stackBlockCompiler;      // for testing
-(instancetype)initWithWriter:(MPWMachOWriter*)aWriter;
-(int)linkObjects:(NSArray*)objects toExecutable:(NSString*)executable inDir:(NSString*)dir additionalFrameworks:(NSArray*)additionalFrameworks;
-(int)linkObjects:(NSArray*)objects toSharedLibrary:(NSString*)executable inDir:(NSString*)dir withFrameworks:(NSArray*)frameworks;
-(NSData*)compileClassToMachoO:(STClassDefinition*)aClass;
-(NSData*)compileClassesToMachoO:(NSArray<STClassDefinition*>*)classes;
-writer;
-(STJittableData*)generatedCode;

objectAccessor_h(STObjectCodeGeneratorARM*, codegen, setCodegen)

@end

NS_ASSUME_NONNULL_END
