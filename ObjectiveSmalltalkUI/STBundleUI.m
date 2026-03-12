//
//  STBundleUI.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 12.03.26.
//

#import "STBundleUI.h"
#import <MPWFoundationUI/MPWFoundationUI.h>

@implementation STBundle(UI)

-(MPWFileBrowser*)browserForStore:(id <MPWStorage>)store loggingTo:(id <Streaming>)logTarget
{
    MPWFileBrowser *b=[[MPWFileBrowser new] autorelease];
    if ( logTarget) {
        store=[MPWLoggingStore storeWithSource:store loggingTo:logTarget];
    }
    [[b browser] setStore:store];
    [[b browser] setRootReference:@""];
    
    [b view].autoresizingMask =  NSViewWidthSizable | NSViewHeightSizable;
    
    [b setContinuous:YES];
    return b;
}

-(MPWFileBrowser*)classBrowserLoggingTo:(id <Streaming>)logTarget
{
    return [self browserForStore:self.cachedSources loggingTo:logTarget];
}

-(MPWFileBrowser*)classBrowser
{
    return [self classBrowserLoggingTo:nil];
}

-(MPWFileBrowser*)resourceBrowserLoggingTo:(id <Streaming>)logTarget
{
    return [self browserForStore:self.cachedResources loggingTo:logTarget];
}

-(MPWFileBrowser*)resourceBrowser
{
    return [self resourceBrowserLoggingTo:nil];
}


@end

