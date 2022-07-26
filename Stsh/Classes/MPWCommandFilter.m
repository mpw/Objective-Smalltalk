//
//  MPWCommandFilter.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 06/03/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//
//	I wrap an external command (MPWShellProcess) so it looks like a filter stream (MPWWriteStream)
//
//

#import "MPWCommandFilter.h"
#import "MPWShellProcess.h"
#import "MPWUpcaseFilter.h"
#include <sys/time.h>


@interface NSFileHandle(isDataAvailable)
-(BOOL)isDataAvailable;
@end


@implementation NSFileHandle(isDataAvailable)

-(BOOL)isDataAvailable
{
	int fd = [self fileDescriptor];
	struct timeval timeout;
	fd_set infds,outfds,exceptfds;
	FD_SET( fd, &infds );
	FD_ZERO( &infds );
	FD_ZERO( &outfds );
	FD_ZERO( &exceptfds );
	memset( &timeout, 0, sizeof timeout );
	select( fd, &infds, &outfds, &exceptfds, &timeout );
	return (FD_ISSET(fd, &infds)) ? YES : NO;
}

@end


@implementation MPWCommandFilter



objectAccessor( NSFileHandle, processStdin, setProcessStdin )
objectAccessor( NSFileHandle, processStdout, setProcessStdout )
idAccessor(  shellProcess, setShellProcess )
boolAccessor( isTarget, setIsTarget )
boolAccessor( doLines, setDoLines )
idAccessor( scanner ,setScanner )

-initWithTarget:aTarget command:aCommand
{
	if ( self=[super initWithTarget:aTarget] ) {
        [self setShellProcess:aCommand];
        configured = NO;
        if ( [aTarget respondsToSelector:@selector(setIsTarget:)] ) {
            [aTarget setIsTarget:YES];
        }
        [self setIsTarget:YES];
    }
	return self;
}

-(BOOL)needStdinPipe
{
	return [self isTarget];
}

-(BOOL)needStdoutPipe
{
	return [self target] != nil && 
		   ([self target] != [MPWByteStream Stdout]);
}

-(void)configureProcess
{
	if ( !configured ) {
		NSPipe *inpipe = nil;
		NSPipe *outpipe = nil;
		if ( [self needStdinPipe] ) {
			inpipe = [NSPipe pipe];
			[self setProcessStdin:[inpipe fileHandleForWriting]];
		}
		if ( [self needStdoutPipe] ) {
			outpipe = [NSPipe pipe];
			[self setProcessStdout:[outpipe fileHandleForReading]];
		}
		[[self shellProcess] configureProcessForRunningWithStdinput:inpipe stdoutput:outpipe];
		configured=YES;
		running=NO;
	}
}

-(void)startRunning
{
	if ( !running ) {
		[self configureProcess];
		[[self shellProcess] startRunning];
		running=YES;
		eofReached=NO;
	}
}

-runProcess
{
	[self startRunning];
	[self flush];
	return [self result];
}

-(void)awaitResultForSeconds:(NSTimeInterval)seconds
{
    
}

-value
{
    return [self runProcess];
}

-(void)run
{
    [self runProcess];
}

-(BOOL)isDataAvailableFromCommand
{
	return [[self processStdout] isDataAvailable];
}

-(void)forwardLines
{
	id line;
	while ( nil != (line=[scanner nextLine]) ) {
		[self forward:line];
	}
}

-(void)forwardDataFromCommandToTarget
{
	id data = [[self processStdout] availableData];
	if ( [data length] > 0 ) {
		if ( doLines ) {
			if ( !scanner ) {
				[self setScanner:[[[MPWScanner alloc] initWithData:data] autorelease]];
			} else {
				[scanner addData:data];
			}
		} else {
            [self forward:data];
		}
	} else {
		eofReached=YES;
		if ( doLines ) {
			[self forwardLines];
		}
	}
	
}

-(void)pickupDataIfAvailable
{
	if ( [self isDataAvailableFromCommand] ) {
		[self forwardDataFromCommandToTarget];
	}
}

-(void)writeObject:anObject
{
	[self startRunning];
	[self pickupDataIfAvailable];
	[[self processStdin] writeData:[NSData dataWithBytes:[anObject cString] length:[anObject length]]];
}


-(void)flushLocal
{
	[self startRunning];
	[[self processStdin] closeFile];
	while (!eofReached ) {
		[self forwardDataFromCommandToTarget];
	}
	[super flushLocal];
}

-(void)dealloc
{
	[shellProcess release];
	[processStdin release];
	[processStdout release];
	[super dealloc];
}

-description
{
    return [NSString stringWithFormat:@"<%@ %p: shellProcess: %@ target: %@",[self class],self,shellProcess,self.target];
}

@end

#import <MPWFoundation/DebugMacros.h>

@implementation MPWCommandFilter(testing)

+filterWithCommandNamed:(NSString*)commandName args:(NSArray*)args target:aTarget
{
	id shellCommand = [[[MPWShellProcess alloc] initWithName:commandName arguments:args] autorelease];
	id stream = [[[self alloc] initWithTarget:aTarget command:shellCommand] autorelease];
	return stream;
}

+filterWithCommandNamed:(NSString*)commandName args:(NSArray*)args 
{
	id theTarget = [self defaultTarget];
	return [self filterWithCommandNamed:commandName args:args target:theTarget];
}


+(void)testSimpleCommandWithOutputOnly
{
	id echo = [self filterWithCommandNamed:@"echo" args:[NSArray arrayWithObject:@"Hello World!"]];
	id result;
	[echo close];
	result = [echo target];
	INTEXPECT( [result count], 1, @"echo should return exactly one result");
	IDEXPECT( [[result lastObject] stringValue], @"Hello World!\n", @"result of running echo command" );
}

+(void)testSimpleFilter
{
	id wc = [self filterWithCommandNamed:@"wc" args:[NSArray array]];
	id wcresult;
	[wc writeObject:@"hello world\n"];
	[wc writeObject:@"another line\n"];
	[wc writeObject:@"and yet another line\n"];
	[wc close];
	wcresult=[wc target];
	INTEXPECT( [wcresult count], 1, @"wc should return exactly one line of result ");
	IDEXPECT( [[wcresult lastObject] stringValue], @"       3       8      46\n", @"result of running wc command" );
}

+(void)testSimplePipe
{
	id wc = [self filterWithCommandNamed:@"wc" args:[NSArray array]];
	id wcresult;
	id echo = [self filterWithCommandNamed:@"echo" args:[NSArray arrayWithObject:@"Hello World!"] target:wc];
	[echo close];
	wcresult=[wc target];
	INTEXPECT( [wcresult count], 1, @"wc should return exactly one line of result ");
	IDEXPECT( [wcresult lastObject], @"       1       2      13\n", @"result of running wc command" );
}

+(void)testSimplePipeWithFilterStreamTarget
{
	id upcase = [MPWUpcaseFilter stream];
	id upcaseresult=nil;
	id echo = [self filterWithCommandNamed:@"echo" args:[NSArray arrayWithObject:@"Hello World!"] target:upcase];
	[echo close];
	upcaseresult=[upcase target];
	INTEXPECT( [upcaseresult count], 1, @"upcase should return exactly one line of result ");
	IDEXPECT( [upcaseresult lastObject], @"HELLO WORLD!\n", @"result of filtering" );
}

+(void)testSimplePipeReturningTextLines
{
	id launchtl_list_path = [self frameworkPath:@"launchctl_list_result"];
	id resultArray=[NSMutableArray array];
	id cat = [self filterWithCommandNamed:@"cat" args:[NSArray arrayWithObject:launchtl_list_path] 
												target:resultArray];
	[cat setDoLines:YES];
	[cat close];
	INTEXPECT( [resultArray count], 89, @"number of lines in launchctl_list_result");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
		@"testSimpleCommandWithOutputOnly",
		@"testSimpleFilter",
//		@"testSimplePipe",   FIXME
		@"testSimplePipeWithFilterStreamTarget",
//		@"testSimplePipeReturningTextLines",
		nil];
}

@end


@implementation NSString(asLines1)

-(NSArray*)asLines_1
{
	NSArray* array=[self componentsSeparatedByString:@"\n"];
	if ( [[array lastObject] length] == 0 ) {
		array=[array subarrayWithRange:NSMakeRange(0,[array count]-1)];
	}
	return array;
}

@end
