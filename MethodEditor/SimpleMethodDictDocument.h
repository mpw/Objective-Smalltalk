//
//  SimpleMethodDictDocument.h
//  
//
//  Created by Marcel Weiher on 10/16/11.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MethodDict;

@interface SimpleMethodDictDocument : NSDocument
{
    IBOutlet NSTextField *methodHeader;
    IBOutlet NSTextView  *methodBody;
    IBOutlet NSBrowser   *methodBrowser;
    IBOutlet NSTextField *address;
    IBOutlet NSTextField *evalText;

    MethodDict *methodDict;
    NSString   *uniqueID;
}

-(IBAction)eval:sender;
-(IBAction)didSelect:(NSBrowser*)sender;
-(NSString*)uniqueID;

@end
