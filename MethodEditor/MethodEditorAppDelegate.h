//
//  MethodEditorAppDelegate.h
//  MPWTalk
//
//  Created by Marcel Weiher on 2/25/12.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MethodEditorAppDelegate : NSObject <NSApplicationDelegate>
{
    NSMutableSet *services;
    NSNetServiceBrowser *serviceBrowser;
}

-(IBAction)startBrowsing:sender;


@end
