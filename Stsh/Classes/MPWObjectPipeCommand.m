//
//  MPWObjectPipeCommand.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 19/2/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import "MPWObjectPipeCommand.h"


@implementation MPWObjectPipeCommand

idAccessor( commandClass, setCommandClass )

-initWithCommandClass:newCommandClass name:newName
{
	self = [super initWithName:newName];
	[self setCommandClass:newCommandClass];
	return self;
}

-processWithArgs:args
{
	id command=[[self commandClass] stream];
	return [command with:[args objectAtIndex:0]];
}

-adaptCommand:aCommand
{
	return [aCommand wrappedAsMPWStream];
}



-process
{
	return [self processWithArgs:[NSArray arrayWithObject:@""]];
}

-wrappedAsMPWStream
{
	return [self process];
}



-(void)dealloc
{
	[commandClass release];
	[super dealloc];
}

@end


@implementation MPWObjectPipeCommand(tests)


+(void)testRunOfUpcaseFilter
{
	IDEXPECT( @"1" ,@"2" , @"whatever");
}

+testSelectors
{
	return @[
//		@"testRunOfUpcaseFilter",
		];
}


@end
