//
//  STNativeCompiler.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.10.22.
//

#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

NS_ASSUME_NONNULL_BEGIN

@interface STNativeCompiler : STCompiler

@property (nonatomic, assign) bool jit;
@property (nonatomic, assign) bool logging;

+(instancetype)jitCompiler;
+(instancetype)stackBlockCompiler;      // for testing
-(int)linkObjects:(NSArray*)objects toExecutable:(NSString*)executable inDir:(NSString*)dir additionalFrameworks:(NSArray*)additionalFrameworks;
-(int)linkObjects:(NSArray*)objects toSharedLibrary:(NSString*)executable inDir:(NSString*)dir withFrameworks:(NSArray*)frameworks;
-(NSData*)compileClassToMachoO:(STClassDefinition*)aClass;
-writer;

@end

NS_ASSUME_NONNULL_END
