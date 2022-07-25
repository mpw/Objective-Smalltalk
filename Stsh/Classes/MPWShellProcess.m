//
//  MPWShellProcess.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 07/12/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWShellProcess.h"
#import "MPWCommandFilter.h"

@implementation MPWShellProcess

boolAccessor( doLines , setDoLines )

+(NSArray*)PATH
{
	id environment = [[NSProcessInfo processInfo] environment];
	id pathEnv=[environment objectForKey:@"PATH"];
	id paths = [pathEnv componentsSeparatedByString:@":"];
	return paths;
}


+(NSString*)findCommandOnPath:(NSString*)commandName
{
	id fullPath = nil;
	if ( ![commandName hasPrefix:@"/"] )  {
		NSArray *paths=[self PATH];
		int i;
		
		for (i=0;i<[paths count];i++) {
			 NSString *path=[[paths objectAtIndex:i] stringByAppendingPathComponent:commandName];
			if ( [[NSFileManager defaultManager] fileExistsAtPath:path] ) {
				fullPath = path;
			}
		}
	} else {
		fullPath = commandName;
	}
	return fullPath;
}

objectAccessor( NSString, name, setName )
objectAccessor( NSMutableArray, arguments, setArguments )
objectAccessor( NSTask, task, setTask )

+processWithName:(NSString*)aName
{
    return [[[self alloc] initWithName:aName] autorelease];
}

-initWithName:(NSString*)aName
{
    self=[super init];
    [self setName:aName];
    [self setArguments:[NSMutableArray array]];
    return self;
}

-(void)addArguments:anArgumentArray
{
    [[self arguments] addObjectsFromArray:anArgumentArray];
}

-initWithName:(NSString*)aName arguments:(NSArray*)args
{
    self = [self initWithName:aName];
    [self addArguments:args];
    return self;
}

-(void)configureProcessForRunningWithStdinput:processStdin stdoutput:processStdout
{
    task = [[NSTask alloc] init];
    if ( processStdin ) {
        [task setStandardInput:processStdin];
    }
	if ( processStdout ) {
		[task setStandardOutput:processStdout];
	}
	[task setArguments:[self arguments]];
	[task setLaunchPath:[[self class] findCommandOnPath:[self name]]];
}

-(void)startRunning
{
	[task launch];
}


-resultOfRunning:readHandleOfPipe
{
    id result;
	[self startRunning];
	result = [[readHandleOfPipe readDataToEndOfFile] stringValue];
//	[task waitUntilExit];
    return result;
}

-adaptCommand:aCommand
{
	return [aCommand wrappedAsMPWStream];
}


#if 0
-pipe:otherCommand
{
   	NSPipe *interProcessPipe = [NSPipe pipe];
   	NSPipe *pipe = [NSPipe pipe];
	NSFileHandle *readHandleOfPipe=[pipe fileHandleForReading];
	otherCommand = [otherCommand process];
    [self configureProcessForRunningWithStdinput:nil stdoutput:interProcessPipe];
    [otherCommand configureProcessForRunningWithStdinput:interProcessPipe stdoutput:pipe];
    [task launch];
    return [otherCommand resultOfRunning:readHandleOfPipe];
}
#else
-pipe:otherCommand
{
	return [[otherCommand adaptCommand:self] pipe:[otherCommand process]];;
}

#endif

-wrappedAsMPWStream
{
	id filter = [[[MPWCommandFilter alloc] initWithTarget:nil command:self] autorelease];
	[filter setDoLines:[self doLines]];
	return filter;
}



-runWithTarget:newTarget
{
	id filter=[self wrappedAsMPWStream];
	[filter setTarget:newTarget];
//	[filter runProcess];
	[filter run];
	return [filter target];
#if 0
	id commandFilter = [[[MPWCommandFilter 

	NSPipe *pipe = [NSPipe pipe];
	NSFileHandle *readHandleOfPipe=[pipe fileHandleForReading];


    [self configureProcessForRunningWithStdinput:nil stdoutput:pipe];
    return [self resultOfRunning:readHandleOfPipe];
#endif	
}

-runProcess
{
    return [self runWithTarget:[NSMutableArray array]];
}


+resultOfRunningCommand:(NSString*)command withArgs:args
{
    id process = [[[self alloc] initWithName:command arguments:args] autorelease];
    id result = [process runProcess];
	return result;
}

+linesReturnedByCommand:(NSString*)command withArgs:args
{
	return [[self resultOfRunningCommand:command withArgs:args] componentsSeparatedByString:@"\n"];
}

+resultOfRunningCommand:(NSString*)command withArg:arg
{
	return [self resultOfRunningCommand:command withArgs:[NSArray arrayWithObject:arg]];
}

-process
{
	return self;
}

-description
{
	return [NSString stringWithFormat:@"<%@ %p: name: %@ arguments: %@>",[self class],self,name,arguments];
}

-(void)dealloc
{
    [arguments release];
    [name release];
    [task release];
    [super dealloc];
}

@end

@implementation MPWShellProcess(testing)

+(void)testSimpleShellEchoCommand
{
	id command = @"echo";
	id arg = @"hi";
    id result = [self resultOfRunningCommand:command withArgs:[NSArray arrayWithObjects:@"-n",arg,nil]];
	IDEXPECT(result, @"hi", command );
}

+(void)testAnotherShellEchoCommand
{
	id command = @"/bin/echo";
	id arg = @"hello world!";
    id result = [self resultOfRunningCommand:command withArgs:[NSArray arrayWithObjects:@"-n",arg,nil]];
	IDEXPECT(result, arg, command );
}

+(void)testFindingACommandOnPath
{
	IDEXPECT( [self findCommandOnPath:@"echo"] , @"/bin/echo", @"echo command");
}

+(void)testLinesReturnedByCommand
{
	id lines = [self linesReturnedByCommand:@"echo" withArgs:[NSArray arrayWithObject:@"hi"]];
	IDEXPECT( [lines objectAtIndex:0],@"hi", @"line-wise return");
}

+(void)testSimpleTwoPartPipe
{
    id command1,command2;
    id result;
    int numResults=0,lines=0,words=0,characters=0;
    command1 = [self processWithName:@"echo"];
    command2 = [self processWithName:@"wc"];
    [command1 addArguments:[NSArray arrayWithObjects:@"Hello World!",nil]];

    result = [command1 pipe:command2];
	NSLog(@"initial result= %@",result);
    result = [result runProcess];
	if ( result ) {
		numResults=sscanf( [[result stringValue] UTF8String], "%d %d %d",&lines,&words,&characters);
	}
    INTEXPECT( numResults, 3 , @"wc should have this many components");
	INTEXPECT( lines,1, @"just one line");
	INTEXPECT( words,2, @"two words");
	INTEXPECT( characters,13, @"twelve characters");
}

+testSelectors
{
    return [NSArray arrayWithObjects:
 //       @"testSimpleShellEchoCommand",
 //       @"testAnotherShellEchoCommand",
		@"testFindingACommandOnPath",
//		@"testLinesReturnedByCommand",
//        @"testSimpleTwoPartPipe",
        nil];
}

@end
