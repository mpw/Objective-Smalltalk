//
//  MPWShellCommand.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 22/12/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWShellCommand.h"


@implementation MPWShellCommand

idAccessor(name,setName )
boolAccessor( returnsLines, setReturnsLines )

-initWithName:aName
{
    self=[super init];
    [self setName:aName];
    return self;
}

-adaptCommand:aCommand
{
	return aCommand;
}

-pipe:otherCommand
{
	return [[self process] pipe:otherCommand];
//	return [[otherCommand adaptCommand:[self process]] pipe:[otherCommand process]];;
}


-runProcess
{
    return [self runWithArgs:[NSArray array]];
}

-executeInShell:aShell
{
//	NSLog(@"run MPWShellCommand");
    return [self runProcess];
}



-run:firstArg
{
    return [self runWithArgs:[NSArray arrayWithObject:firstArg]];
}


-with:firstArg
{
    return [self processWithArgs:[NSArray arrayWithObject:firstArg]];
}

-(void)dealloc
{
	[name release];
	[super dealloc];
}

@end

