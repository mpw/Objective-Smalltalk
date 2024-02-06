//
//  STBundle.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 05.08.20.
//

#import <Foundation/Foundation.h>

@protocol MPWHierarchicalStorage,MPWReferencing;
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
-(id <MPWReferencing>)resourceRef;
-(id <MPWReferencing>)sourceRef;
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


@end

NS_ASSUME_NONNULL_END
