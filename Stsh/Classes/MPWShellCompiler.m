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
#import <ObjectiveSmalltalk/MPWFileSchemeResolver.h>
#import <MPWFoundation/MPWURLSchemeResolver.h>
#import "MPWEnvScheme.h"
#import <MPWFoundation/MPWNeXTPListWriter.h>
#import "MPWAbstractShellCommand.h"
#import "MPWStsh.h"
#import "MPWShellPrinter.h"
#import <MPWFoundation/MPWFDStreamSource.h>
#import "MPWCommandStore.h"
#import <ObjectiveSmalltalk/MPWSchemeScheme.h>

@implementation MPWShellCompiler


+internalCommands
{
    return @{
             @"echo":  [MPWEchoCommand class],
             @"upcase": [MPWUpcaseFilter class],
             };
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

-(MPWSchemeScheme*)createSchemes
{
    MPWSchemeScheme *schemes=[super createSchemes];
    [schemes setSchemeHandler:[MPWCommandStore store] forSchemeName:@"sh"];
    return schemes;
}

-init
{
	self=[super init];
    id Rawstdout=[MPWByteStream Stdout];
    MPWShellPrinter* Stdout=[MPWShellPrinter streamWithTarget:[MPWByteStream Stdout] ];
    Stdout.environment = [self schemeForName:@"var"];
    id Stderr=[MPWByteStream Stderr];
    id Stdin=[MPWFDStreamSource fd:0];
    [self bindValue:Rawstdout toVariableNamed:@"rawstdout"];
    [self bindValue:Stdout toVariableNamed:@"stdout"];
    [self bindValue:Stderr toVariableNamed:@"stderr"];
    [self bindValue:Stdin toVariableNamed:@"stdin"];
    [self bindValue:@"\n" toVariableNamed:@"newline"];
    [self bindValue:@"\t" toVariableNamed:@"tab"];
//   [self addExternalCommands:[[self class] externalCommandNames]];
//   [self addInternalCommands:[[self class] internalCommands]];
	return self;
}

-executeShellExpression:compiledExpression
{
    return [compiledExpression evaluateIn:self];
}

@end
