//
//  MPWAbstractShellCommand
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 22/12/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWAbstractShellCommand.h"


@implementation MPWAbstractShellCommand

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

-process
{
    @throw [NSException exceptionWithName:@"subclassResponsibility" reason:@"need to override -processs" userInfo:nil];
}

-runWithArgs:(NSArray*)args
{
    @throw [NSException exceptionWithName:@"subclassResponsibility" reason:@"need to override -runWithArgs:" userInfo:nil];
}

-processWithArgs:(NSArray*)args
{
    @throw [NSException exceptionWithName:@"subclassResponsibility" reason:@"need to override -processWithArgs:" userInfo:nil];
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

