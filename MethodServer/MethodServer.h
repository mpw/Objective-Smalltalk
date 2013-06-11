//
//  MethodServer.h
//  MethodServer
//
//  Created by Marcel Weiher on 10/16/11.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
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
-(void)setup;
-(void)setDelegate:aDelegate;
-delegate;

@end
