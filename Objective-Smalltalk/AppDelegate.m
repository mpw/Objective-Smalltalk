//
//  AppDelegate.m
//  Objective-Smalltalk
//
//  Created by Marcel Weiher on 24.03.19.
//

#import "AppDelegate.h"
#import <ObjectiveSmalltalkUI/CLIView.h>
#import <ObjectiveSmalltalk/MPWStCompiler.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

-(IBAction)showWorkspace:(id)sender
{
    NSWindow *console=[[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 500, 500)
                                                  styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskResizable
                                                    backing:NSBackingStoreBuffered defer:NO];
    [console setTitle:@"Workspace"];
    CLIView *cli=[[CLIView alloc] initWithFrame:NSMakeRect(0, 0, 490, 490)];
    [console setContentView:cli];
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    [cli setCommandHandler:compiler];
    [console makeKeyAndOrderFront:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
