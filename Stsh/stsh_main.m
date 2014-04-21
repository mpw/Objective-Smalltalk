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
	[MPWStsh runWithArgCount:argc argStrings:argv];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}
