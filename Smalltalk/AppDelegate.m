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

@
@implementation AppDelegate



-(IBAction)showWorkspace:(id)sender
{
    CLIView *cli=[CLIView openInWindow:@"Workspace"];
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    [cli setCommandHandler:compiler];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
