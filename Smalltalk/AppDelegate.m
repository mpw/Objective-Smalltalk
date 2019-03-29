//
//  AppDelegate.m
//  Objective-Smalltalk
//
//  Created by Marcel Weiher on 24.03.19.
//

#import "AppDelegate.h"
#import "CLIView.h"
#import "MPWStCompiler.h"
#import "MPWProgramTextView.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end


@implementation AppDelegate

-(instancetype)init
{
    self=[super init];
    self.compiler = [MPWStCompiler compiler];
    return self;
}

-(void)textDidChange:(MPWProgramTextView*)view
{
    NSLog(@"text did change");
}



-(IBAction)showWorkspace:(id)sender
{
    MPWProgramTextView *workspace=[MPWProgramTextView openInWindow:@"Workspace"];
    workspace.delegate=self;
    workspace.compiler=self.compiler;
}

-(IBAction)showREPL:(id)sender
{
    CLIView *cli=[CLIView openInWindow:@"CLI"];
    MPWStCompiler *compiler=self.compiler;
    [cli setCommandHandler:compiler];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
