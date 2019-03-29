//
//  AppDelegate.h
//  Objective-Smalltalk
//
//  Created by Marcel Weiher on 24.03.19.
//

#import <Cocoa/Cocoa.h>

@class MPWStCompiler;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, retain) MPWStCompiler *compiler;

-(IBAction)showWorkspace:(id)sender;
-(IBAction)showREPL:(id)sender;

@end

