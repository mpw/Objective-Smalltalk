//
//  STBundle+ObjSTNative.m
//  ObjSTNative
//
//  Created by Codex.
//

#import "STBundle+ObjSTNative.h"

#import "MPWMachODylibWriter.h"
#import "STNativeCompiler.h"
#import "STClassDefinition.h"
#import "MPWStatementList.h"

@interface STBundle (PathAccess)
- (NSString *)path;
@end

@implementation STBundle (ObjSTNative)

- (NSString *)nativeDylibName
{
    NSString *bundleName = [[[self path] lastPathComponent] stringByDeletingPathExtension];
    if (bundleName.length == 0) {
        bundleName = @"bundle";
    }
    return bundleName;
}

- (NSString *)nativeDylibPath
{
    return [[self path] stringByAppendingPathComponent:[self nativeDylibName]];
}

- (NSArray<STClassDefinition *> *)compiledClassesWithCompiler:(STNativeCompiler *)compiler
{
    NSMutableArray<STClassDefinition *> *classes = [NSMutableArray array];
    id<MPWHierarchicalStorage> sourceStore = [self sources];

    for (NSString *sourceName in [self sourceNames]) {
        NSData *sourceData = sourceStore[sourceName];
        if (!sourceData) {
            continue;
        }
        id compiled = [compiler compile:sourceData];
        if ([compiled isKindOfClass:[STClassDefinition class]]) {
            [classes addObject:compiled];
        } else if ([compiled isKindOfClass:[MPWStatementList class]]) {
            NSArray *statements = [(MPWStatementList *)compiled statements];
            for (id item in statements) {
                if ([item isKindOfClass:[STClassDefinition class]]) {
                    [classes addObject:item];
                }
            }
        } else if ([compiled isKindOfClass:[NSArray class]]) {
            for (id item in (NSArray *)compiled) {
                if ([item isKindOfClass:[STClassDefinition class]]) {
                    [classes addObject:item];
                }
            }
        }
    }

    return classes;
}

- (void)compileSourcesToNativeDylibWithoutCodesigning
{
    NSArray<NSString *> *frameworks = @[
        @"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation",
        @"/Library/Frameworks/MPWFoundation.framework/Versions/A/MPWFoundation",
    ];
    NSString *installName = [@"@rpath/" stringByAppendingString:[self nativeDylibName]];
    [self compileSourcesToNativeDylibWithFrameworks:frameworks installName:installName];
}

- (void)compileSourcesToNativeDylib
{
    [self compileSourcesToNativeDylibWithoutCodesigning];
    [self codesign];
}

- (void)compileSourcesToNativeDylibWithFrameworks:(NSArray<NSString *> *)frameworks
                                           installName:(NSString *)installName
{
    MPWMachODylibWriter *writer = [MPWMachODylibWriter stream];
    STNativeCompiler *compiler = [[[STNativeCompiler alloc] initWithWriter:writer] autorelease];

    if (installName.length > 0) {
        writer.installName = installName;
    }
    for (NSString *frameworkPath in frameworks) {
        [writer.frameworks addObject:frameworkPath];
    }

    NSArray<STClassDefinition *> *classes = [self compiledClassesWithCompiler:compiler];
    if (classes.count == 0) {
        return ;
    }

    NSData *dylibData = [compiler compileClassesToMachoO:classes];
    if (dylibData) {
        [dylibData writeToFile:[self nativeDylibPath] atomically:YES];
    }
}

-(void)codesign
{
    system([[NSString stringWithFormat:@"codesign --deep -s - %@", self.path] UTF8String]);

}

@end
