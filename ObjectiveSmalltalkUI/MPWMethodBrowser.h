//
//  VBMethodBrowser.h
//  ViewBuilderFramework
//
//  Created by Marcel Weiher on 23.01.19.
//  Copyright © 2019 Marcel Weiher. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MPWFoundation/MPWFoundation.h>

#import <MPWFoundationUI/MPWFoundationUI.h>
NS_ASSUME_NONNULL_BEGIN

@class CLIView;
@protocol MethodDict;

@interface MPWMethodBrowser : NSViewController
{
    IBOutlet MPWBrowser  *methodBrowser;
    IBOutlet NSTextField *address;
    IBOutlet NSTextField *evalText;
    IBOutlet NSTextField *isOK;
    IBOutlet NSWindow    *errorWindow;
    IBOutlet NSTableView *exceptionNames;
    IBOutlet NSTableView *exceptionStackTrace;

    IBOutlet NSPanel     *createClassPanel;
    IBOutlet NSTextField *createClassField;

    IBOutlet NSWindow    *replWindow;

    IBOutlet NSMatrix   *instanceClassSelector;

    NSString   *uniqueID;
    NSArray    *exceptions;
}

@property (nonatomic, strong)   IBOutlet NSTextField *methodHeader;
@property (nonatomic, strong)   IBOutlet NSTextView  *methodBody;
@property (assign)              BOOL                 continuous;
@property (nonatomic, strong)   id <MPWStorage>      methodStore;
@property (nonatomic, strong)   IBOutlet CLIView     *cliView;
@property (nonatomic, weak)     id                   delegate;

-(void)display;

-(instancetype)initWithDefaultNib;
-(MPWBrowser*)methodBrowser;;

@end


NS_ASSUME_NONNULL_END
