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

@implementation MPWBlockExpression

idAccessor( statements, setStatements )
idAccessor( arguments, setArguments )

-initWithStatements:newStatements arguments:newArgNames
{
	self=[super init];
	[self setStatements:newStatements];
	[self setArguments:newArgNames];
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


-(void)dealloc
{
	[statements release];
	[arguments release];
	[super dealloc];
}

@end
