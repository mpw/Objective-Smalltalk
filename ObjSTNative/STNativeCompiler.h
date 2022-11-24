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

+(instancetype)jitCompiler;

@end

NS_ASSUME_NONNULL_END
