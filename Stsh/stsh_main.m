//
//  main.m
//  stsh
//
//  Created by Marcel Weiher on 12/1/13.
//
//


#import <MPWFoundation/MPWFoundation.h>
#import <Stsh/MPWStsh.h>


int main (int argc, const char *argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int i;
	NSMutableArray *args=[NSMutableArray array];
	for (i=1;i<argc;i++) {
		[args addObject:[NSString stringWithCString:argv[i]]];
	}
	[MPWStsh runWithArgs:args];
    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}
