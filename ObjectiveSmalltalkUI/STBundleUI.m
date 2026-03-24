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
    MPWFileBrowser *browser = [self browserForStore:self.cachedSources loggingTo:logTarget];
    self.errorReporter = browser;
    return browser;
}

-(MPWFileBrowser*)classBrowser
{
    return [self classBrowserLoggingTo:[[[MPWBlockTargetStream alloc] initWithBlock:^(id object) {
        [self sourceCodeDidChange:object];
    }] autorelease]];
//    return [self classBrowserLoggingTo:[[[MPWEventSender alloc] initWithNotificationProtocol:@protocol(SourceCodeChanged) shouldPostOnMainThread:NO] autorelease]];
}

-(void)dummy
{
    NSLog(@"%@",@protocol(ResourceChanged));
    NSLog(@"%@",@protocol(ClassCompiled));

}

-(MPWFileBrowser*)resourceBrowserLoggingTo:(id <Streaming>)logTarget
{
    return [self browserForStore:self.cachedResources loggingTo:logTarget];
}

-(MPWFileBrowser*)resourceBrowser
{
    return [self resourceBrowserLoggingTo:[self classBrowserLoggingTo:[[[MPWEventSender alloc] initWithNotificationProtocol:@protocol(ResourceChanged) shouldPostOnMainThread:NO] autorelease]]];
}

-(void)sourceCodeDidChange:(MPWRESTOperation*)restOp
{
    NSString *sourceName = restOp.identifier.path.lastPathComponent;
    BOOL error=NO;
    NSString *message=[NSString stringWithFormat:@"compiled %@",sourceName];
    @try {
        [self compileSourceFile:sourceName];
    } @catch ( NSException* exception ) {
        error=YES;
        message=[NSString stringWithFormat:@"Error compiling %@: %@",sourceName,exception.reason];
    }
    if ( error ) {
        [self.errorReporter reportError:message];
    } else {
        [self.errorReporter reportMessage:message];
    }
}


@end

