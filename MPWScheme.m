//
//  MPWScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWScheme.h"
#import "MPWBinding.h"

@implementation MPWScheme

-value
{
	return self;		// FIXME:  this is a workaround for not returning proper bindings from the scheme scheme
}

-bindingWithIdentifier:anIdentifier withContext:aContext
{
	return [self bindingForName:[anIdentifier identifierName] inContext:aContext];
}

-evaluteIdentifier:anIdentifer withContext:aContext
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
	//	return [aContext valueOfVariableNamed:[anIdentifer identifierName] withScheme:[anIdentifer schemeName]];
}


@end
