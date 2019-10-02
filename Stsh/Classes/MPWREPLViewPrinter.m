//
//  MPWREPLViewPrinter.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 02.10.19.
//

#import "MPWREPLViewPrinter.h"

@implementation MPWREPLViewPrinter


-(int)terminalWidth
{
    return 1000;
}

-(int)numColumnsForTerminalWidth:(int)terminalWidth maxWidth:(int)maxWidth
{
    return 1;
}

@end
