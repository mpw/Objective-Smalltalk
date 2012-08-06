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
    IBOutlet NSTextField *isOK;
    IBOutlet NSWindow    *errorWindow;
    IBOutlet NSTableView *exceptionNames;
    IBOutlet NSTableView *exceptionStackTrace;
    
    MethodDict *methodDict;
    NSString   *uniqueID;
    NSArray    *exceptions;
}

-(IBAction)eval:sender;
-(IBAction)didSelect:(NSBrowser*)sender;
-(IBAction)getErrors:(id)sender;
-(IBAction)selectError:(id)sender;
-(NSString*)uniqueID;

@end
