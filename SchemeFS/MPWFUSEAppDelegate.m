//
//  MPWAppDelegate.m
//  SchemeFS
//
//  Created by Marcel Weiher on 11/3/11.
//  Copyright (c) 2012 Marcel Weiher. All rights reserved.
//

#import "MPWFUSEAppDelegate.h"
#import "MPWSchemeFilesystem.h"
#import <OSXFUSE/OSXFUSE.h>

@implementation MPWFUSEAppDelegate

// @synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

- (void)didMount:(NSNotification *)notification {
    NSDictionary* userInfo = [notification userInfo];
    NSString* mountPath = [userInfo objectForKey:kGMUserFileSystemMountPathKey];
    NSString* parentPath = [mountPath stringByDeletingLastPathComponent];
    [[NSWorkspace sharedWorkspace] selectFile:mountPath
                     inFileViewerRootedAtPath:parentPath];
}

- (void)didUnmount:(NSNotification*)notification {
    [[NSApplication sharedApplication] terminate:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didMount:)
                   name:kGMUserFileSystemDidMount object:nil];
    [center addObserver:self selector:@selector(didUnmount:)
                   name:kGMUserFileSystemDidUnmount object:nil];
    
    NSString* mountPath = @"/Volumes/Hello";
    MPWSchemeFilesystem* hello = [[MPWSchemeFilesystem alloc] init];
    fs_ = [[GMUserFileSystem alloc] initWithDelegate:hello isThreadSafe:YES];
    NSMutableArray* options = [NSMutableArray array];
    [options addObject:@"rdonly"];
    [options addObject:@"volname=HelloFS"];
    [options addObject:[NSString stringWithFormat:@"volicon=%@", 
                        [[NSBundle mainBundle] pathForResource:@"Fuse" ofType:@"icns"]]];
    [fs_ mountAtPath:mountPath withOptions:options];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [fs_ unmount];  // Just in case we need to unmount;
    [[fs_ delegate] release];  // Clean up HelloFS
    [fs_ release];
    return NSTerminateNow;
}
@end
