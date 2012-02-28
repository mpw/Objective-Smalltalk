//
//  MPWBinding.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import "MPWBinding.h"
#import "MPWRelScheme.h"

@implementation MPWBinding

idAccessor( scheme, setScheme )
idAccessor( _value, _setValue )
boolAccessor( isBound ,setIsBound )
idAccessor(identifier, setIdentifier)
scalarAccessor(MPWEvaluator*, defaultContext, setDefaultContext)

-initWithValue:aValue
{
	self=[super init];
    if (aValue) {
        [self bindValue:aValue];
    }
	return self;
}

+bindingWithValue:aValue
{
	return [[[self alloc] initWithValue:aValue] autorelease];
}


-value
{
	if ( [self isBound] ) {
		return [self _value];
	} else {
		[NSException raise:@"unboundvariable" format:@"variable not bound to a value"];
		return nil;
	}
}

-fileSystemValue
{
    return [self value];
}

-valueForKeyPath:(NSString*)kvpath
{
	return [[self value] valueForKeyPath:kvpath];
}


-valueForPathComponent:(NSString*)kvpath
{
	return [[self value] valueForPathComponent:kvpath];
}

-(void)setValue:newValue forKey:(NSString*)kvpath
{
	[[self value] setValue:newValue forKey:kvpath];
}

-(NSArray*)children
{
    return [NSArray array];
}

-(NSArray*)childNames
{
    return [self children];
}

-(NSArray*)allLinks
{
    return [self children];
}

-(void)bindValue:newValue
{
	[self _setValue:newValue];
	[self setIsBound:YES];
}

-(void)unbindValue
{
	[self setIsBound:NO];
	[self _setValue:nil];
}

-(BOOL)hasChildren
{
    return NO;
}

-asScheme
{
    return [[[MPWRelScheme alloc] initWithRef:self] autorelease];
}

-name
{
    return [[self identifier] identifierName];
}


-bindNames
{
    MPWBinding *evaluated = [[[self class] alloc] init];
    [evaluated setScheme:[self scheme]];
    NSString *name=[[self identifier] evaluatedIdentifierNameInContext:[self defaultContext]];
    id newIdentifier=[[[[[self identifier] class] alloc] init] autorelease];
    [newIdentifier setIdentifierName:name];
    [newIdentifier setScheme:[[self identifier] scheme]];
    [newIdentifier setSchemeName:[[self identifier] schemeName]]; 
    [evaluated setIdentifier:newIdentifier];
    return evaluated;
}

-(void)dealloc
{
	[_value release];
	[scheme release];
	[identifier release];
	[super dealloc];
}




@end
