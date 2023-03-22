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
-(id <MPWHierarchicalStorage>)sourceDir;
-(NSArray<NSString*>*)sourceNames;
-(NSDictionary*)info;
-(STCompiler*)interpreter;
-(NSDictionary*)methodDict;
-(id <MPWReferencing>)resourceRef;
-(id <MPWReferencing>)sourceRef;
-(MPWWriteBackCache*)cachedResources;
-(void)save;


@property (readonly) BOOL isPresentOnDisk;

@end

NS_ASSUME_NONNULL_END
