//
//  MethodServer.h
//  MethodServer
//
//  Created by Marcel Weiher on 10/16/11.
//  Copyright (c) 2012 Marcel Weiher. All rights reserved.
//


#import <ObjectiveHTTPD/MPWSchemeHttpServer.h>

@class STCompiler;


@interface MethodServer : MPWSchemeHttpServer
{
    STCompiler *interpreter;
    id delegate;
    NSString *methodDictName,*projectDir;
    NSString *uniqueID;
    NSMutableArray *exceptions;
}

-(void)setupWithInterpreter:anInterpreter;
- (id)initWithMethodDictName:(NSString*)newName;
-(void)setupMethodServer;
-(void)setupWithoutStarting;

-(void)setDelegate:aDelegate;
-delegate;
-(STCompiler*)interpreter;
-(void)setMethodDict:(NSDictionary*)dict;

@end
