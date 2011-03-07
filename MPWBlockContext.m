//
//  MPWBlockContext.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import "MPWBlockContext.h"
#import "MPWStatementList.h"
#import "MPWEvaluator.h"

@implementation MPWBlockContext

idAccessor( block, setBlock )
idAccessor( context, setContext )

-initWithBlock:aBlock context:aContext
{
	self=[super init];
	[self setBlock:aBlock];
	[self setContext:aContext];
	return self;
}

+blockContextWithBlock:aBlock context:aContext
{
	return [[[self alloc] initWithBlock:aBlock context:aContext] autorelease];
}

-evaluateIn:aContext
{
	if ( aContext ) {
		return [aContext evaluate:[[self block] statements]];
	} else {
		return [[[self block] statements] evaluateIn:aContext];
	}
}

-value
{
	return [self evaluateIn:[self context]];
}

-value:anObject
{
	[[self context] bindValue:anObject toVariableNamed:[[[self block] arguments] objectAtIndex:0]];
	return [self value];
}

-whileTrue:anotherBlock
{
    id retval=nil;
	while ( [[self value] boolValue] ) {
		retval=[anotherBlock value];
	}
    return retval;
}

-(void)dealloc
{
	[block release];
	[context release];
	[super dealloc];
}

@end
