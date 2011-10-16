//
//  MethodServer.h
//  MethodServer
//
//  Created by Marcel Weiher on 10/16/11.
//  Copyright (c) 2011 metaobject ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPWStCompiler,MPWHTTPServer;

@interface MethodServer : NSObject
{
    MPWStCompiler *interpreter;
    MPWHTTPServer *server;
    id delegate;
}
@end
