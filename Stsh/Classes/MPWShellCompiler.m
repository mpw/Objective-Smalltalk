//
//  MPWShellCompiler.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 4/10/06.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import "MPWShellCompiler.h"
#import "MPWExternalCommand.h"

#import "MPWObjectPipeCommand.h"
#import "MPWUpcaseFilter.h"
#import "MPWEchoCommand.h"
#import "MPWFileSchemeResolver.h"
#import "MPWURLSchemeResolver.h"
#import "MPWEnvScheme.h"

@implementation MPWShellCompiler


+internalCommands
{
	return [NSDictionary dictionaryWithObjectsAndKeys:[MPWEchoCommand class],@"echo",[MPWUpcaseFilter class],@"upcase",nil];
}




+externalCommandNames
{
    return [@"as rm ls find grep ps cat wc cc kill slay nps ssh cvs man open sort less sed top vi curl sh bash" componentsSeparatedByString:@" "];
}


-(void)addExternalCommand:(NSString*)externalCommandName
{
    id command = [[[MPWExternalCommand alloc] initWithName:externalCommandName] autorelease];
	[command setIsText:NO];
    [self bindValue:command toVariableNamed:externalCommandName];
}


-(void)addInternalCommand:commandClass forName:commandName
{
	id command = [[[MPWObjectPipeCommand alloc] initWithCommandClass:commandClass name:commandName] autorelease];
	[self bindValue:command toVariableNamed:commandName];
}

-(void)addInternalCommands:(NSDictionary*)commands
{
	id commandNameEnumerator = [commands keyEnumerator];
	id commandName;
	while ( nil != ( commandName = [commandNameEnumerator nextObject] )) {
		[self addInternalCommand:[commands objectForKey:commandName] forName:commandName];
	}
}

-(void)addExternalCommands:(NSArray*)externalCommands
{
	id commandEnumerator = [externalCommands objectEnumerator];
	id nextCommand;
	while ( nextCommand = [commandEnumerator nextObject] ) {
		[self addExternalCommand:nextCommand];
	}
}

-init
{
	self=[super init];
   id Stdout=[MPWByteStream Stdout];
   id Stderr=[MPWByteStream Stderr];
   [self bindValue:Stdout toVariableNamed:@"stdout"];
   [self bindValue:Stderr toVariableNamed:@"stderr"];
   [self bindValue:@"\n" toVariableNamed:@"newline"];
   [self bindValue:@"\t" toVariableNamed:@"tab"];
   [self addExternalCommands:[[self class] externalCommandNames]];
   [self addInternalCommands:[[self class] internalCommands]];
	return self;
}

-executeShellExpression:compiledExpression
{
//	NSLog(@"will execute in shell: %@",compiledExpression);
    return [compiledExpression executeInShell:self];
}

@end
