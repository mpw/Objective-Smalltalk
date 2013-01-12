//
//  MPWScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWScheme.h"
#import "MPWBinding.h"
#import "MPWCopyOnWriteScheme.h"

@implementation MPWScheme

+scheme
{
	return [[[self alloc] init] autorelease];
}

-value
{
	return self;		// FIXME:  this is a workaround for not returning proper bindings from the scheme scheme
}

-bindingForName:(NSString*)variableName inContext:aContext
{
	return nil;
}

-bindingWithIdentifier:anIdentifier withContext:aContext
{
	MPWBinding *binding = [self bindingForName:[anIdentifier evaluatedIdentifierNameInContext:aContext] inContext:aContext];
    [binding setScheme:self];
    [binding setIdentifier:anIdentifier];
    [binding setDefaultContext:aContext];
    return binding;
}

-evaluateIdentifier:anIdentifer withContext:aContext
{
	MPWBinding *binding=[self bindingWithIdentifier:anIdentifer withContext:aContext];
	id value=[binding value];
	if (!binding ) {
		value=[aContext valueForUndefinedVariableNamed:[anIdentifer identifierName]];
	}

	if ( ![value isNotNil] ) {
		value=nil;
	}
	return value;
}


-get:uri
{
    MPWBinding *binding=[self bindingForName:uri inContext:nil];
    return [binding value];
}

-get:uri parameters:params
{
    return [self get:uri];
}


-(BOOL)isBoundBinding:(MPWBinding*)aBinding
{
    return YES;
}

-(MPWScheme*)cachedBy:cacheScheme
{
    return [MPWCopyOnWriteScheme cacheWithBase:self cache:cacheScheme];
}


-(MPWScheme*)before:otherScheme
{
    return [[[MPWCopyOnWriteScheme alloc] initWithBase:self cache:otherScheme] autorelease];
}



@end
