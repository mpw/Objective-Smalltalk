//
//  STSiteBundle.m
//  SiteBuilding
//
//  Created by Marcel Weiher on 03.08.20.
//

#import "STSiteBundle.h"
#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>
#import "STSiteServer.h"
//#import <ObjectiveHTTPD/MPWHTTPServer.h>



@implementation STSiteBundle
{
    STSiteServer *siteServer;
;
}


lazyAccessor(STSiteServer*, siteServer, setSiteServer, createSiteServer)



-(NSString*)siteClassName
{
    return self.info[@"site"];
}

-(Class)siteClass
{
    NSLog(@"siteClassName %@ class %p",[self siteClassName],NSClassFromString([self siteClassName]));
    return NSClassFromString([self siteClassName]);
}

-(NSArray*)siteTests
{
    return [self.siteClass testSelectors];
}

-(void)runSiteTests
{
//    NSLog(@"run tests: %@",[self siteTests]);
    for (NSString *testName in [self siteTests]) {
        @try {
            id fixture=[self.siteClass testFixture];
            if ( [fixture respondsToSelector:@selector(doTest:withTest:)]) {
                [fixture doTest:testName withTest:nil];
            }
        } @catch ( NSException *e ) {
            NSLog(@"test: %@ failed: %@",testName,e);
        }
    }
}

-(void)setupSite
{
    [self siteServer];
}

-(Class)siteServerClass
{
    return NSClassFromString(@"STSiteServer");
}



-(STSiteServer*)createSiteServer
{
    NSAssert([self siteServerClass]!=nil, @"MPWSiteServer not linked into program, can't set up a site");
    Class siteClass = [self siteClass];
    NSAssert(siteClass != nil, @"should have a siteClass at this point");
    NSLog(@"siteClass: %@",siteClass);
    id sitemap=nil;
    if ( [siteClass instancesRespondToSelector:@selector(initWithBundle:)]) {
        sitemap = [[[[self siteClass] alloc] initWithBundle:self] autorelease];
        NSLog(@"sitemap: %@ initWithBundle",sitemap);
        NSAssert(sitemap != nil, @"should have a sitemap with initWithBundle:");
    } else {
        sitemap = [[[[self siteClass] alloc] init] autorelease];
        if ( [sitemap respondsToSelector:@selector(setBundle:)]) {
            [sitemap setBundle:self];
        }
        NSLog(@"sitemap: %@ setBundle",sitemap);
        NSAssert(sitemap != nil, @"should have a sitemap with setBundle:");
    }
    NSAssert(sitemap != nil, @"should have a sitemap at this point");
    STSiteServer *server = [[[[self siteServerClass] alloc] initWithSite:sitemap siteDict:@{} interpreter:self.interpreter] autorelease];
    if ( [server respondsToSelector:@selector(setupSite)]) {
        [server setupSite];
    }
    [server disableCaching];
    NSLog(@"created server %@ withe sitemap %@",server,sitemap);
    return server;
}



-(void)startWebServerOnPort:(int)port
{
    MPWHTTPServer *httpServer=[self.siteServer server];
    [httpServer setType:@"_http._tcp."];
    [httpServer setBonjourName:[self siteClassName]];
    [httpServer setPort:port];
    [httpServer setDefaultMimeType:@"text/html"];

    NSError *startError = nil;
    [httpServer start:&startError];
    [self.siteServer disableCaching];
}

-(Class)httpServerClass
{
    return NSClassFromString(@"MPWHTTPServer");
}

-(void)setupSimpleSite
{
    NSAssert([self httpServerClass]!=nil, @"MPWHTTPServer not linked into program, can't start site");
    Class siteClass = [self siteClass];
    id sitemap=nil;
    if ( [siteClass instancesRespondToSelector:@selector(initWithBundle:)]) {
        sitemap = [[[[self siteClass] alloc] initWithBundle:self] autorelease];
    } else {
        sitemap = [[[[self siteClass] alloc] init] autorelease];
        if ( [sitemap respondsToSelector:@selector(setBundle:)]) {
            [sitemap setBundle:self];
        }
    }
    self.siteServer = [[[[self httpServerClass] alloc] init] autorelease];
    [self.siteServer setDelegate:sitemap];
}


-(id)renderer
{
    return self.siteServer.renderer;
}

-(void)runSite:(int)port
{
    [self methodDict];
    [self setupSite];
    [self startWebServerOnPort:port];
}

-(void)runSimpleSite:(int)port
{
    [self methodDict];
    [self setupSimpleSite];
    // FIXME:  this really does return an MPWHTTPServer
    //         so why is the type for self.siteServer wrong?
    MPWHTTPServer *httpServer=(MPWHTTPServer*)self.siteServer;
    [httpServer setType:@"_http._tcp."];
    [httpServer setBonjourName:[self siteClassName]];
    [httpServer setPort:port];
    [httpServer setDefaultMimeType:@"text/html"];
    NSError *startError = nil;
    [httpServer start:&startError];
}

-(void)runSite
{
    [self runSite:8081];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STSiteBundle(testing) 

+testSelectors
{
    return @[];
}

@end
