//
//  AppDelegate.m
//  Objective-Smalltalk
//
//  Created by Marcel Weiher on 24.03.19.
//

#import "STAppDelegate.h"
#import "CLIView.h"
#import "MPWStCompiler.h"
#import "MPWProgramTextView.h"

@interface STAppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end


@implementation STAppDelegate


-(void)textDidChange:(MPWProgramTextView*)view
{
}



//-(IBAction)showWorkspace:(id)sender
//{
//    MPWProgramTextView *workspace=[MPWProgramTextView openInWindow:@"Workspace"];
//    workspace.delegate=self;
//    workspace.compiler=self.compiler;
//}

-(IBAction)showREPL:(id)sender
{
    CLIView *cli=[CLIView openInWindow:@"CLI"];
    MPWStCompiler *compiler=self.compiler;
    [cli setCommandHandler:compiler];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSApplication sharedApplication] setServicesProvider:self];
    
}

-validRequestorForSendType:sendType
                returnType:returnType
{
    NSLog(@"AppDelegate validRequestFor...");
    return nil;
}
-(void)evaluateSmalltalk:(NSPasteboard*)pasteboard userData:userData error:error
{
    NSPasteboardItem *item=[[pasteboard pasteboardItems] firstObject];
    NSString *stRequest=[item stringForType:NSPasteboardTypeString];
    [pasteboard clearContents];
    NSString *result=@"";
    @try {
        result = [[self.compiler evaluateScriptString:stRequest] stringValue] ?: @"";
    } @catch ( id error ) {
        NSLog(@"erorr evaluating: %@",error);
    }
//    NSLog(@"result: '%@'",result);
    [pasteboard writeObjects: @[ result ]];



}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
