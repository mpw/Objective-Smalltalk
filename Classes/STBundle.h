//
//  STBundle.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 05.08.20.
//

#import <MPWFoundation/MPWFoundation.h>

@class STCompiler,MPWWriteBackCache;

@protocol ClassCompiled<MPWNotificationProtocol>
-(void)didCompileClass:className;
@end


NS_ASSUME_NONNULL_BEGIN

@interface STBundle : NSObject

+(instancetype)bundleWithPath:(NSString*)path;

-(id <MPWHierarchicalStorage>)resources;
-(id <MPWHierarchicalStorage>)sources;
-(NSArray<NSString*>*)sourceNames;
-(NSDictionary*)info;
-(STCompiler*)interpreter;
-(NSDictionary*)methodDict;

-(id <MPWHierarchicalStorage>)storeForSubDir:(NSString*)subdir;

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
-(void)startNotifyingCompiles;
-(void)stopNotifyingCompiles;


@property (readonly) BOOL isPresentOnDisk;
@property (assign) BOOL saveSource;           // should probably be a temp hack
@property (assign) BOOL useCache;      // should probably be a temp hack
@property (nonatomic,strong) NSDictionary *info;
@property (nonatomic, weak) id errorReporter;
@property (nonatomic, strong,nullable) id compileSuccessReporter;

-(id <MPWHierarchicalStorage>)sourceDir;      // compatibility

-(NSString*)path;

-(BOOL)loadFrameworks;

@property (nonatomic, readonly) bool frameworksLoaded;
@property (nonatomic, readonly) bool sourcesCompiled;

@end

NS_ASSUME_NONNULL_END
