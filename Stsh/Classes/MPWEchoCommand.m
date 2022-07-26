//
//  MPWEchoCommand.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/2/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import "MPWEchoCommand.h"
#import "MPWCommandFilter.h"

@implementation MPWEchoCommand

idAccessor( toEcho, setToEcho )

-initWithTarget:aTarget
{
	self=[super initWithTarget:aTarget];
	[self setToEcho:@""];
	return self;
}

-runProcess
{
//	NSLog(@"run echo command");
    [self forward:[self toEcho]];
    return [self result];
}



-pipe:other
{
//	NSLog(@"pipe:");
	 [self setTarget:[other wrappedAsMPWStream]];
	 return self;
}

-with:firstArg
{
	[self setToEcho:firstArg];
	return self;
}



@end

@implementation  MPWWriteStream(wrapped)

-(MPWWriteStream*)wrappedAsMPWStream
{
	return self;
}
-process
{
	return self;
}

-adaptCommand:aCommand
{
	return [[[MPWCommandFilter alloc] initWithTarget:nil command:aCommand] autorelease];

}

//-pipe:other
//{
////    NSLog(@"pipe:");
//     [self setTarget:[other wrappedAsMPWStream]];
//     return self;
//}

@end
