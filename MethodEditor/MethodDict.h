//
//  MethodDict.h
//  MethodEditor
//
//  Created by Marcel Weiher on 9/25/11.
//  Copyright 2011 metaobject ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MethodDict : NSDocument
{
    IBOutlet NSTextField *methodHeader;
    IBOutlet NSTextView  *methodBody;
    IBOutlet NSBrowser   *methodBrowser;
    IBOutlet NSTextField *address;
    IBOutlet NSTextField *evalText;
    NSMutableDictionary *dict;
    
}

-(IBAction)eval:sender;
-(IBAction)didSelect:(NSBrowser*)sender;

@end
