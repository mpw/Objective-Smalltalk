//
//  MPWClassMirror.h
//  MPWTest
//
//  Created by Marcel Weiher on 5/29/11.
//  Copyright 2011 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MPWClassMirror : NSObject
{
	Class theClass;
}

+(instancetype)mirrorWithClassNamed:(NSString*)aClassName;
+(instancetype)mirrorWithMetaClassNamed:(NSString*)aClassName;
+(instancetype)mirrorWithClass:(Class)aClass;
-(NSString*)name;
+(NSArray*)allUsefulClasses;
-(Class)theClass;
-(Class)theSuperclass;
-(BOOL)isInBundle:(NSBundle*)aBundle;
-(MPWClassMirror*)createSubclassWithName:(NSString*)name;
-(MPWClassMirror*)createAnonymousSubclass;
-(MPWClassMirror*)superclassMirror;
-(MPWClassMirror*)metaClassMirror;

@end


@interface MPWClassMirror(objc)

-(const char*)cStringClassName;
+(Class)superclassOfClass:(Class)aClass;
+(NSArray*)allClasses;
-(Class)_createClass:(const char*)name;
-(NSArray*)methodMirrors;

@end
