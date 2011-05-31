//
//  MPWSchemeScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 6/30/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWSchemeScheme.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWVARBinding.h"

@implementation MPWSchemeScheme

objectAccessor( NSMutableDictionary, _schemes, setSchemes )

-(NSDictionary*)schemes { return [self _schemes]; }

-init
{
	self=[super init];
	[self setSchemes:[NSMutableDictionary dictionary]];
	return self;
}

-localVarsForContext:aContext
{
	return [self schemes];
}

-(void)setSchemeHandler:(MPWScheme*)aSchem   forSchemeName:(NSString*)schemeName
{
	[[self _schemes] setObject:aSchem forKey:schemeName];
}


-bindingForName:(NSString*)variableName inContext:aContext
{
	id localVars = [self localVarsForContext:aContext];
	id binding=nil;
	binding = [[[MPWVARBinding alloc] initWithBaseObject:localVars path:variableName] autorelease];		
	return binding;
}


-objectForKey:aKey
{
	return [[self schemes] objectForKey:aKey];
}

-description
{
	return [NSString stringWithFormat:@"scheme-resolver with the following schemes: %@",[[self schemes] allKeys]];
}

-(void)dealloc
{
	[_schemes release];
	[super dealloc];
}

@end
