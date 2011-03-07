//
//  MPWIdentifier.m
//  MPWTalk
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWIdentifier.h"


@implementation MPWIdentifier

idAccessor( scheme, setScheme )
idAccessor( schemeName, setSchemeName )
idAccessor( identifierName, setIdentifierName )

-schemeWithContext:aContext
{
	id theScheme=[self scheme];
	NSAssert1( theScheme!=nil , @"scheme %@ could not be evaluated", [self schemeName]);
	return theScheme;
}

-evaluateIn:aContext
{
	return [[self schemeWithContext:aContext] evaluteIdentifier:self withContext:aContext];
}

-(void)dealloc
{
	[scheme release];
	[schemeName release];
	[identifierName release];
	[super dealloc];
}

@end
