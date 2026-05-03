//
//  main.m
//  stsh
//
//  Created by Marcel Weiher on 12/1/13.
//
//


#import <MPWFoundation/MPWFoundation.h>
#import "STShell.h"
#import <Sails/Sails.h>

int main (int argc, const char *argv[])
{
    @autoreleasepool {
        SailsControl *sails=[[SailsControl new] autorelease];
        STShell *stsh=[[[STShell alloc] initWithArgs:@[]] autorelease];
        [stsh setCommandName:[NSString stringWithUTF8String:argv[0]]];
        int returnCode = [sails main:argc argv:argv stsh:stsh];
        if ( returnCode == 0) {
            [stsh run];
        }
        return returnCode;
   }
}

