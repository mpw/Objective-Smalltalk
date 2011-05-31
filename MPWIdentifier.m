//
//  MPWIdentifier.m
//  MPWTalk
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWIdentifier.h"
#import "MPWEvaluator.h"
#import "MPWScheme.h"

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

-pathComponents
{
	return [[self identifierName] componentsSeparatedByString:@"/"];
}

-evaluatedPathComponentsInContext:aContext
{
	NSMutableArray *evaluated = [NSMutableArray array];
	for ( id component in [self pathComponents] ) {
		if ( [component hasPrefix:@"{"] && [component hasSuffix:@"}"] ) {
			NSString *nested=[component substringWithRange:NSMakeRange(1, [component length]-2)];
			component=[aContext evaluateScriptString:nested];
			component = [[component  stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		}
		[evaluated addObject:component];
	}
	return evaluated;
	
}

-evaluatedIdentifierNameInContext:aContext
{
	return [[self evaluatedPathComponentsInContext:aContext] componentsJoinedByString:@"/"];
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
