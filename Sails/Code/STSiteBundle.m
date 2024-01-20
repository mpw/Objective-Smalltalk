//
//  STSiteBundle.m
//  SiteBuilding
//
//  Created by Marcel Weiher on 03.08.20.
//

#import "STSiteBundle.h"
#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>
#import <ObjectiveHTTPD/MPWSiteServer.h>
#import <ObjectiveHTTPD/MPWHTTPServer.h>



@implementation STSiteBundle
{
    MPWSiteServer *siteServer;
;
}


lazyAccessor(MPWSiteServer*, siteServer, setSiteServer, createSiteServer)



-(NSString*)siteClassName
{
    return self.info[@"site"];
}

-(Class)siteClass
{
    return NSClassFromString([self siteClassName]);
}

-(NSArray*)siteTests
{
    return [self.siteClass testSelectors];
}

-(void)runSiteTests
{
    NSLog(@"run tests: %@",[self siteTests]);
    for (NSString *testName in [self siteTests]) {
        @try {
            id fixture=[self.siteClass testFixture];
            [fixture doTest:testName withTest:nil];
        } @catch ( NSException *e ) {
            NSLog(@"test: %@ failed: %@",testName,e);
        }
    }
}

-(void)setupSite
{
    [self siteServer];
}



-(MPWSiteServer*)createSiteServer
{
    id sitemap = [[[[self siteClass] alloc] init] autorelease];
    NSLog(@"create siteServer with sitemap: %@",sitemap);
    if ( [sitemap respondsToSelector:@selector(setBundle:)]) {
        NSLog(@"will set bundle: %@",self);
        NSLog(@"on sitemap: %p/%@",sitemap,sitemap);
        [sitemap setBundle:self];
        NSLog(@"sitemap's bundle: %@",[sitemap bundle]);
    }
    MPWSiteServer *server = [[[MPWSiteServer alloc] initWithSite:sitemap siteDict:@{} interpreter:self.interpreter] autorelease];
    [server setupSite];

    [server disableCaching];
    return server;
}

-(void)startWebServerOnPort:(int)port
{
    MPWHTTPServer *httpServer=[self.siteServer server];
    [httpServer setType:@"_http._tcp."];
    [httpServer setBonjourName:[self siteClassName]];
    [httpServer setPort:port];
    NSError *startError = nil;
    [httpServer start:&startError];
    [self.siteServer disableCaching];
}

-(void)setupSimpleSite
{
    id sitemap = [[[[self siteClass] alloc] init] autorelease];
    self.siteServer = [[[MPWHTTPServer alloc] init] autorelease];
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
    MPWHTTPServer *httpServer=self.siteServer;
    [httpServer setType:@"_http._tcp."];
    [httpServer setBonjourName:[self siteClassName]];
    [httpServer setPort:port];
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
