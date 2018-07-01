//
//  MPWMethodStore.h
//  MPWTalk
//
//  Created by Marcel Weiher on 25/01/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWMethodHeader,MPWClassMethodStore;

@interface MPWMethodStore : MPWObject {
    NSMutableDictionary *classes;
    NSMutableDictionary *metaClasses;
    
    
    
    id typeDict;        // not used
	id compiler;
}

-initWithCompiler:aCompiler;
-(void)defineMethodsInExternalDict:(NSDictionary*)scriptDict;
//-methodDictionaryForClassNamed:(NSString*)className;
-(NSArray*)classesWithScripts;
-(void)addScript:(NSString*)scriptString forClass:(NSString*)className methodHeader:(MPWMethodHeader*)header;
	//  private
-(NSDictionary*)externalScriptDict;
-(void)addScript:scriptString forClass:className methodHeaderString:methodHeaderString;
-(void)addScript:scriptString forMetaClass:className methodHeaderString:methodHeaderString;
-(NSArray*)methodNamesForClassName:(NSString*)aClassName;
-methodForClass:aClassName name:aMethodName;

-(void)installMethods;

-(MPWClassMethodStore*)classStoreForName:(NSString*)name;
-(MPWClassMethodStore*)metaClassStoreForName:(NSString*)name;


@end
