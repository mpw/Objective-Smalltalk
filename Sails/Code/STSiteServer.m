//
//  MPWSiteServer.m
//  ObjectiveHTTPD
//
//  Created by Marcel Weiher on 2/11/12.
//  Copyright (c) 2012 Marcel Weiher. All rights reserved.
//

#import "STSiteServer.h"
//#import <MethodServer/MethodServer.h>
#import <ObjectiveSmalltalk/STCompiler.h>
#import <ObjectiveSmalltalk/MPWMethodStore.h>
//#import "MPWHTTPServer.h"

@implementation STSiteServer

objectAccessor(MPWHTTPServer*, server, setServer)
objectAccessor(MPWSiteMap*, sitemap, setSitemap)
objectAccessor(MPWTemplater*, templater, setTemplater )
objectAccessor(MPWWriteThroughCache*, cache , setCache )
objectAccessor(STCompiler*, interpreter , setInterpreter )
objectAccessor(MethodServer*, methodServer , setMethodServer)
//objectAccessor(STHTMLRenderScheme*, renderer , setRenderer)

-(void)initializeAndClearCache
{
//    [[self cache] setReadWrite:[NSClassFromString(@"MPWSiteMap") scheme]];
}

-(void)enableCaching
{
    [[self server] setDelegate:[self cache]];
}

-(void)disableCaching
{
    NSLog(@"cached disabled");
    [[self server] setDelegate:[self templater]];
}

-(Class)httpServerClass
{
    return NSClassFromString(@"MPWHTTPServer");
}

-createServer:aTemplater
{
    if ( ![self server] && [self httpServerClass] ) {
        [self setServer:[[[[self httpServerClass] alloc] init] autorelease]];
    }
    [[self server] setDefaultMimeType:@"text/html"];
//
//    [self setRenderer:[STHTMLRenderScheme scheme]];
//    [[self renderer] setSourceScheme:aTemplater];
    [[self sitemap] setRenderer:aTemplater];
    [self setCache:[MPWWriteThroughCache storeWithSource:aTemplater]];
    [self initializeAndClearCache];
//    [cache setCacheReads:YES];
    [self enableCaching];
//    [self disableCaching];
//    NSLog(@"site-def: %@",[cache graphViz]);
    return [self server];
}

-(void)createMethodServer
{
    [self setMethodServer:[[[NSClassFromString(@"MethodServer") alloc] initWithMethodDictName:@"website"] autorelease]];
    [[self methodServer] setupWithInterpreter:[self interpreter]];
    [[self methodServer] setupWebServerInBackground];

    [[self methodServer] setDelegate:self];
}

-(void)setupSite
{
    if ( [[self sitemap] respondsToSelector:@selector(setupSite)]) {
        [[self sitemap] setupSite];
        [self setTemplater:[[self sitemap] createTemplater]];
        [self createServer:[self templater]];
    }
}

-(void)loadMethods
{
    [[self interpreter] defineMethodsInExternalDict:self.methodDict];
}

-(NSDictionary*)siteDictForSiteMap:(MPWSiteMap*)sitemap
{
#if TARGET_OS_IPHONE
    NSDictionary* dict=[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"website" ofType:@"classdict"]];
#else
    NSString* methodString = [[sitemap frameworkResource:@"website" category:@"classdict"] stringValue];
    NSDictionary *dict=[methodString propertyList];
#endif
    return dict;
}
-(NSDictionary*)storedSiteDict
{
    return [self siteDictForSiteMap:[self sitemap]];
}

-(instancetype)initWithSite:(MPWSiteMap*) aSite siteDict:(NSDictionary*)dict interpreter:(STCompiler*)interpreter
{
	self = [super init];
    [self setSitemap:aSite];
    [self setInterpreter:interpreter];
    self.methodDict = [[[dict objectForKey:@"methodDict"] mutableCopy] autorelease];

    [self loadMethods];
    
    [[self interpreter] bindValue:aSite toVariableNamed:@"site"];


    [[self interpreter] bindValue:self toVariableNamed:@"siteServer"];
    [[self interpreter] bindValue:[self server] toVariableNamed:@"server"];

//    [self createMethodServer];
//
//    NSString *uid=[dict objectForKey:@"uniqueID"];
//    if ( uid ) {
//        [[self methodServer] setUniqueID:uid];
//    }
    if ( [[self sitemap] respondsToSelector:@selector(sitemap)]) {
        [[[self interpreter] schemes]  setSchemeHandler:[[self sitemap] sitemap] forSchemeName:@"dynamic"];
    }

//    [self setupInterpreter];

	return self;
}

-(instancetype)initWithSite:(MPWSiteMap*) aSite
{
    self = [self initWithSite: aSite siteDict:[self siteDictForSiteMap:aSite] interpreter:[STCompiler compiler]];
    [self setupSite];
    return self;
}

-(NSDictionary*)siteDict
{
    NSDictionary *methods = [[[self interpreter] methodStore] externalScriptDict];
    NSMutableDictionary *totalDict = [[[self storedSiteDict] mutableCopy] autorelease];
    totalDict[@"methodDict"]=methods;
    return totalDict;
}


-(void)didDefineMethods:server
{
//    NSLog(@"======= didDefineMethods, now setup site again");
    [self setupSite];
    [self initializeAndClearCache];
}



@end
