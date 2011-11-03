//
//  MethodServer.h
//  MethodServer
//
//  Created by Marcel Weiher on 10/16/11.
//  Copyright (c) 2011 metaobject ltd. All rights reserved.
//


#import <MPWSideweb/MPWSchemeHttpServer.h>

@class MPWStCompiler;


@interface MethodServer : MPWSchemeHttpServer
{
    MPWStCompiler *interpreter;
    id delegate;
}
@end
