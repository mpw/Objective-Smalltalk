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

@interface NSView(openInWindow)
-(void)openInWindow:(NSString*)windowName;
@end
@implementation NSView(openInWindow)

-openInWindow:(NSString*)windowName
{
    NSWindow *theWindow=[[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 500, 500)
                                                  styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskResizable
                                                    backing:NSBackingStoreBuffered defer:NO];
    [theWindow setTitle:windowName];
    [theWindow setContentView:self];
    [theWindow makeKeyAndOrderFront:nil];
    return self;
}

+openInWindow:(NSString*)name
{
    NSView *aView = [[self alloc] initWithFrame:NSMakeRect(0, 0, 490, 490)];
    [aView openInWindow:name];
    return aView ;
}

@end

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
