//
//  main.m
//  stsh
//
//  Created by Marcel Weiher on 12/1/13.
//
//


#import <MPWFoundation/MPWFoundation.h>
#import "MPWStsh.h"


int main (int argc, const char *argv[])
{
    [[NSAutoreleasePool alloc] init];
    NSMutableArray *args=[NSMutableArray array];
    for (int i=1;i<argc;i++) {
        [args addObject:[NSString stringWithUTF8String:argv[i]]];
    }
    MPWStsh *stsh=[[[MPWStsh alloc] initWithArgs:args] autorelease];
    [[stsh evaluator] evaluateScriptString:@"scheme:gpio := MPWBCMStore store."];
    [stsh run];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}
