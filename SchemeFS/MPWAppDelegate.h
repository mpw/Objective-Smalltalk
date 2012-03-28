//
//  MPWAppDelegate.h
//  SchemeFS
//
//  Created by Marcel Weiher on 11/3/11.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GMUserFileSystem;

@interface MPWAppDelegate : NSObject <NSApplicationDelegate> {
    GMUserFileSystem* fs_;
}


@property (assign) IBOutlet NSWindow *window;

@end
