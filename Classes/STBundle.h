//
//  STBundle.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 05.08.20.
//

#import <Foundation/Foundation.h>

@protocol MPWHierarchicalStorage;
@class MPWStCompiler;

NS_ASSUME_NONNULL_BEGIN

@interface STBundle : NSObject

+(instancetype)bundleWithPath:(NSString*)path;

-(id <MPWHierarchicalStorage>)resources;
-(id <MPWHierarchicalStorage>)sourceDir;
-(NSArray<NSString*>*)sourceNames;
-(NSDictionary*)info;
-(MPWStCompiler*)interpreter;
-(NSDictionary*)methodDict;

@end

NS_ASSUME_NONNULL_END
