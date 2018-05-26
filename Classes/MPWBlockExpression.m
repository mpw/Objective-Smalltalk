//
//  MPWBlockExpression.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import "MPWBlockExpression.h"
#import "MPWBlockContext.h"
#import <MPWFoundation/NSNil.h>
#import "MPWIdentifier.h"

@implementation MPWBlockExpression

idAccessor( statements, setStatements )
idAccessor( declaredArguments, setDeclaredArguments )

-initWithStatements:newStatements arguments:newArgNames
{
	self=[super init];
	[self setStatements:newStatements];
	[self setDeclaredArguments:newArgNames];
	return self;
}

+blockWithStatements:newStatements arguments:newArgNames
{
	return [[[self alloc] initWithStatements:newStatements arguments:newArgNames] autorelease];
}

-evaluateIn:aContext
{
	return [MPWBlockContext blockContextWithBlock:self context:aContext];
}

-(void)addToVariablesWritten:(NSMutableSet*)variablesWritten
{
	[statements addToVariablesWritten:variablesWritten];
}

-(void)addToVariablesRead:(NSMutableSet*)variablesRead
{
	[statements addToVariablesRead:variablesRead];
}

-(NSArray*)implicitArguments
{
    NSMutableArray *implicits=[NSMutableArray array];
    for ( MPWIdentifier *identifier in [self variablesRead]) {
        if ( [[identifier identifierName] hasPrefix:@"$"] ) {
            [implicits addObject:[identifier identifierName]];
        }
    }
    return implicits;
}

-(NSArray*)arguments
{
    NSArray *arguments=[self declaredArguments];
    if ( arguments.count == 0) {
        arguments=[self implicitArguments];
    }
    return arguments;
}


-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%p: statements: %@ arguments: %@>",[self class],self,statements,[self arguments]];
}


-(void)dealloc
{
	[statements release];
	[declaredArguments release];
	[super dealloc];
}

@end
