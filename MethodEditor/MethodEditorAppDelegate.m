//
//  MethodEditorAppDelegate.m
//  MPWTalk
//
//  Created by Marcel Weiher on 2/25/12.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "MethodEditorAppDelegate.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MethodDictDocument.h"

@implementation MethodEditorAppDelegate

-(void)awakeFromNib
{
    NSLog(@"MethodEditor App Delegate");
}

- (void)netServiceDidResolveAddress:(NSNetService *)netService
{
    [self updateDocs];
    NSLog(@"resolve netService: %p/%@",netService, netService);
}

- (void)netService:(NSNetService *)netService
     didNotResolve:(NSDictionary *)errorDict
{
    [[self services] removeObject:netService];
    [self updateDocs];
    NSLog(@"service %@ failed to resolve: %@",netService,errorDict);
}

-(void)updateDocs
{
    NSArray *docs=[[NSDocumentController sharedDocumentController] documents];
    NSArray *urls=[self urls];
    for ( MethodDictDocument *doc in docs ) {
        [doc autoresolveFromURLS:urls];
    }
}

-(NSArray*)urls
{
    NSMutableArray *urls=[NSMutableArray arrayWithCapacity:4];
    for ( NSNetService* service in [self services] ) {
        [urls addObject:[NSString stringWithFormat:@"http://%@:%d/",
                         [service hostName],[service port]]];
    }
    return urls;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
           didFindService:(NSNetService *)aNetService
               moreComing:(BOOL)moreComing
{
    NSLog(@"did find service: %@ more coming: %d",aNetService,moreComing);  
    [[self services] addObject:aNetService];
    [aNetService setDelegate:self];
    [aNetService resolveWithTimeout:5.0];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
         didRemoveService:(NSNetService *)aNetService
               moreComing:(BOOL)moreComing
{
    NSLog(@"did remove service: %p/%@ more coming: %d",aNetService,aNetService,moreComing); 
    [[self services] removeObject:aNetService];
    [self updateDocs];
}

objectAccessor(NSNetServiceBrowser, serviceBrowser, setServiceBrowser)

-(void)startBrowsing
{
    NSLog(@"start browsing");
    [self setServices:[NSMutableSet set]];
    [self setServiceBrowser:[[[NSNetServiceBrowser alloc] init] autorelease]];
    [[self serviceBrowser] setDelegate:self];
    [[self serviceBrowser] searchForServicesOfType:@"_methods._tcp" inDomain:@""];

    NSLog(@"did start browsing");
}

-(IBAction)startBrowsing:sender
{
    [self startBrowsing];
}


-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSLog(@"=========  did finish launching");
    [self startBrowsing];
}


objectAccessor(NSMutableSet, services, setServices)


@end
