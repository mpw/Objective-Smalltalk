//
//  MethodDict.h
//  MPWTalk
//
//  Created by Marcel Weiher on 10/16/11.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MethodDict : NSObject
{
    NSMutableDictionary *dict;
}



- (NSData *)asXml;
-initWithXml:(NSData*)data;
-(NSArray*)classes;
-(NSArray*)methodsForClass:(NSString*)className;
-(NSString*)fullNameForMethodName:(NSString*)shortName ofClass:(NSString*)className;
-(NSString*)methodForClass:(NSString*)className methodName:(NSString*)methodName;
-(void)setMethod:(NSString*)methodBody name:(NSString*)methodName  forClass:(NSString*)className;
-(void)deleteMethodName:(NSString*)methodName forClass:(NSString*)className;

@end
