//
//  MPWSchemeHttpServer.h
//  
//
//  Created by Marcel Weiher on 10/24/11.
//  Copyright (c) 2011 metaobject ltd. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWHTTPServer,MPWScheme;


@interface MPWSchemeHttpServer : NSObject {
    MPWHTTPServer *server;
    MPWScheme *scheme;
}


// methods for instance variable 'server'
- (MPWHTTPServer*) server;

- (void) setupWebServer;

@end
