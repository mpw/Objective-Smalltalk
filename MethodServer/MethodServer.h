//
//  MethodServer.h
//  MethodServer
//
//  Created by Marcel Weiher on 10/16/11.
//  Copyright (c) 2012 Marcel Weiher. All rights reserved.
//


#import <ObjectiveHTTPD/MPWSchemeHttpServer.h>

@class MPWStCompiler;


@interface MethodServer : MPWSchemeHttpServer
{
    MPWStCompiler *interpreter;
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
-(MPWStCompiler*)interpreter;
-(void)setMethodDict:(NSDictionary*)dict;

@end
