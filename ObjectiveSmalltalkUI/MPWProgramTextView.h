//
//  MPWProgramTextView.h
//  SketchView
//
//  Created by Marcel Weiher on 9/15/15.
//  Copyright © 2015 Marcel Weiher. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MPWStCompiler;

@interface MPWProgramTextView : NSTextView

@property (nonatomic, strong)  MPWStCompiler *compiler;

-(IBAction)doIt:sender;
-(IBAction)printIt:sender;

@end
