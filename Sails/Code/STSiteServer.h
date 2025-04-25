//
//  MPWSiteServer.h
//  ObjectiveHTTPD
//
//  Created by Marcel Weiher on 2/11/12.
//  Copyright (c) 2012 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWHTTPServer,MPWSiteMap,MPWTemplater,MethodServer;

@class STCompiler,STHTMLRenderScheme;

@interface STSiteServer : NSObject
{
    MPWHTTPServer           *server;
    MPWSiteMap              *sitemap;
    MPWTemplater            *templater;
    STHTMLRenderScheme     *renderer;
    MPWWriteThroughCache    *cache;
    STCompiler           *interpreter;
    MethodServer            *methodServer;
}

objectAccessor_h(MPWHTTPServer*, server, setServer)
objectAccessor_h(MPWSiteMap*, sitemap, setSitemap)
objectAccessor_h(MPWTemplater*, templater, setTemplater )
objectAccessor_h(MPWWriteThroughCache*, cache , setCache )
objectAccessor_h(STCompiler*, interpreter , setInterpreter )
objectAccessor_h(MethodServer*, methodServer , setMethodServer)
objectAccessor_h(STHTMLRenderScheme*, renderer , setRenderer)

@property (nonatomic, strong) NSMutableDictionary *methodDict;

-(void)loadMethods;
-(NSDictionary*)siteDict;

-(void)disableCaching;

-(instancetype)initWithSite:(MPWSiteMap*) aSite siteDict:(NSDictionary*)dict interpreter:(STCompiler*)interpreter;
-(instancetype)initWithSite:(MPWSiteMap*) aSite;


@end

@interface STSiteServer(external)
-(void)setupSite;
@end
