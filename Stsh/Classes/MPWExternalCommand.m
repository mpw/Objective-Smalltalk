//
//  MPWExternalCommand.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/2/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import "MPWExternalCommand.h"
#import "MPWShellProcess.h"


@implementation MPWExternalCommand
idAccessor(path,setPath )
boolAccessor( isText, setIsText )
-initWithName:aName
{
    self=[super initWithName:aName];
    [self setPath:[MPWShellProcess findCommandOnPath:[self name]]];
    return self;
}



-(NSString*)nameOrPath
{
    if ( [self path] ) {
        return [self path];
    } else {
        return [self name];
    }
}

-process
{
	id process = [MPWShellProcess processWithName:[self name]];
	[process setDoLines:[self isText]];
	return process;
}

-processWithArgs:(NSArray*)args
{
	id process=[self process];
//	NSLog(@"%@ processWithArgs: %@",self,args);
	[process addArguments:args];
	[process setDoLines:[self isText]];
	return process;
}

-runWithArgs:(NSArray*)args
{
	return [[self processWithArgs:args] runProcess];
}

-(void)dealloc
{
	[path release];
	[super dealloc];
}


@end

