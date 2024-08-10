//
//  STBundle.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 05.08.20.
//

#import <Foundation/Foundation.h>

@protocol MPWHierarchicalStorage,MPWIdentifying;
@class STCompiler,MPWWriteBackCache;

NS_ASSUME_NONNULL_BEGIN

@interface STBundle : NSObject

+(instancetype)bundleWithPath:(NSString*)path;

-(id <MPWHierarchicalStorage>)resources;
-(id <MPWHierarchicalStorage>)sources;
-(NSArray<NSString*>*)sourceNames;
-(NSDictionary*)info;
-(STCompiler*)interpreter;
-(NSDictionary*)methodDict;

-(id <MPWHierarchicalStorage>)soreForSubDir:(NSString*)subdir;

-(id <MPWIdentifying>)resourceRef;
-(id <MPWIdentifying>)sourceRef;
-(id <MPWHierarchicalStorage>)cachedResources;
-(id <MPWHierarchicalStorage>)cachedSources;
-(id <MPWHierarchicalStorage>)rawResources;
-(id <MPWHierarchicalStorage>)rawSources;
-(void)save;

-(id)resultOfCompilingSourceFileNamed:(NSString*)sourceName;
-(void)compileSourceFile:(NSString*)sourceName;
-(void)compileAllSourceFiles;


@property (readonly) BOOL isPresentOnDisk;
@property (assign) BOOL saveSource;           // should probably be a temp hack
@property (assign) BOOL useCache;      // should probably be a temp hack
@property (nonatomic,strong) NSDictionary *info;

-(id <MPWHierarchicalStorage>)sourceDir;      // compatibility


@end

NS_ASSUME_NONNULL_END
