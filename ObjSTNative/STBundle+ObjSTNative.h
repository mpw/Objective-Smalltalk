//
//  STBundle+ObjSTNative.h
//  ObjSTNative
//
//  Created by Codex.
//

#import <ObjectiveSmalltalk/STBundle.h>

NS_ASSUME_NONNULL_BEGIN

@interface STBundle (ObjSTNative)

- (NSString *)nativeDylibName;
- (NSString *)nativeDylibPath;
- (void)compileSourcesToNativeDylib;
- (NSData * _Nullable)compileSourcesToNativeDylibWithFrameworks:(NSArray<NSString *> *)frameworks
                                                   installName:(NSString * _Nullable)installName;

@end

NS_ASSUME_NONNULL_END
