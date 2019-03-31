//
//  AppDelegate.h
//  Objective-Smalltalk
//
//  Created by Marcel Weiher on 24.03.19.
//

#import "MPWAppDelegate.h"
#import <Cocoa/Cocoa.h>


@interface AppDelegate : MPWAppDelegate <NSApplicationDelegate>


-(IBAction)showWorkspace:(id)sender;
-(IBAction)showREPL:(id)sender;

@end

