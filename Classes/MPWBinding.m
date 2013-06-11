//
//  MPWBinding.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import "MPWBinding.h"
#import "MPWRelScheme.h"
#import "MPWInterval.h"
#import "MPWVARBinding.h"
#import "MPWCopyOnWriteScheme.h"
#import "MPWIdentifier.h"

@implementation MPWBinding

objectAccessor( MPWScheme, scheme, setScheme )
idAccessor( _value, _setValue )
boolAccessor( isBound ,setIsBound )
objectAccessor(MPWIdentifier,identifier, setIdentifier)
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
		[NSException raise:@"unboundvariable" format:@"variable '%@' not bound to a value",[identifier description]];
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



-(NSArray*)childNames
{
    NSArray *childNames=nil;
    id value=[self value];
    if ( [value respondsToSelector:@selector(allKeys)]) {
        childNames = [value allKeys];
    } else if ( [value respondsToSelector:@selector(count)]) {
        childNames = [MPWInterval intervalFromInt:0 toInt:[value count]-1];
    } else if ( ![value isKindOfClass:[NSValue class]] && ![value isKindOfClass:[NSString class]] && ![value isKindOfClass:[NSData class]]) {
        childNames =  [[value class] ivarNames];
    }
    return childNames;
}



-childWithName:(NSString*)aName
{
    id value=[self value];
    return [MPWVARBinding bindingWithBaseObject:value path:aName];
 }

-(BOOL)hasChildren
{
    return [[self childNames] count] > 0;
}

-(BOOL)isDirectory
{
    return [self hasChildren];
}

-children
{
    return [[self collect] childWithName:[[self childNames] each]];
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

-asScheme
{
    return [[[MPWRelScheme alloc] initWithRef:self] autorelease];
}

-defaultComponentInstance
{
    return [self asScheme];
}

-asCache
{
    return [MPWCopyOnWriteScheme cache:[self asScheme]];
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
    [newIdentifier setScheme:[(MPWIdentifier*)[self identifier] scheme]];
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
