//
//  STProgramTextView.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 19.08.24.
//

#import "STProgramTextView.h"
#import "MPWREPLViewPrinter.h"
#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

@implementation STProgramTextView

-(IBAction)printIt:sender;
{
    id result = nil;
    
    @try {
        result = [self.compiler evaluateScriptString:[self selectedTextOrCurrentLine]];
    } @catch (NSException *e) {
        result = e;
    }
    MPWREPLViewPrinter *printer=[MPWREPLViewPrinter streamWithTarget:[NSMutableString string]];
    [printer writeObject:result];
    NSString *resultText=(NSString*)[printer target];
    NSRange currentSelection=[self selectedRange];
    [self setSelectedRange:NSMakeRange( currentSelection.location+currentSelection.length,0)];
    currentSelection=[self selectedRange];
    if ( resultText.length ) {
        [self insertTextAtCursor:@" "];
        [self insertTextAtCursor:resultText];
        [self setSelectedRange:NSMakeRange( currentSelection.location+1, resultText.length)];
    }
}



-(IBAction)doIt:sender
{
    [self.compiler evaluateScriptString:[self selectedTextOrCurrentLine]];
}
@end
