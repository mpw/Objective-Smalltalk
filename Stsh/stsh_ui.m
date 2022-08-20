//
//  stsh_ui.m
//  stui
//
//  Created by Marcel Weiher on 20.08.22.
//


#import <MPWFoundationUI/MPWFoundationUI.h>
#import "MPWStsh.h"

@interface MPWStshUI : MPWStsh

@property (nonatomic, strong) CLIApp *app;

@end



int main (int argc, const char *argv[])
{
    [[NSAutoreleasePool alloc] init];
    NSMutableArray *args=[NSMutableArray array];
    for (int i=1;i<argc;i++) {
        [args addObject:[NSString stringWithUTF8String:argv[i]]];
    }
    MPWStsh *stsh=[[[MPWStshUI alloc] initWithArgs:args] autorelease];
    [stsh setCommandName:[NSString stringWithUTF8String:argv[0]]];
    [stsh run];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}

@implementation MPWStshUI

-(void)setEvaluator:newEval
{
    [super setEvaluator:newEval];
    self.app = [CLIApp sharedApplication];
    if ( self.app ) {
        [newEval bindValue:self.app toVariableNamed:@"app"];
    }
    
}

-(void)evaluateReturnValue:value
{
    [self.app runFromCLI:value];
}

@end

