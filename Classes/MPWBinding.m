//
//  MPWBinding.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//
#import "MPWBinding.h"
#if 0
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
idAccessor( delegate, setDelegate)

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

-(void)didChange
{
    if (delegate) {
//        NSLog(@"%@ sending changed: to delegate:%p/%@/%@",[self class],delegate,[delegate class],delegate);
        [delegate changed:self];
//       NSLog(@"did send changed to delegate: %@",delegate);
    }
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:anObject change:change context:(void*)kvoContext
{
    [self didChange];
}

-(void)bindValue:newValue
{
	[self _setValue:newValue];
	[self setIsBound:YES];
    [self didChange];
}

-(void)unbindValue
{
	[self setIsBound:NO];
	[self _setValue:nil];
    [self didChange];
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
    MPWBinding *evaluated = [[[[self class] alloc] init] autorelease];
    [evaluated setScheme:[self scheme]];
    NSString *name=[[self identifier] evaluatedIdentifierNameInContext:[self defaultContext]];
    id newIdentifier=[[[[[self identifier] class] alloc] initWithName:name] autorelease];
    [newIdentifier setScheme:[(MPWIdentifier*)[self identifier] scheme]];
    [newIdentifier setSchemeName:[[self identifier] schemeName]]; 
    [evaluated setIdentifier:newIdentifier];
    return evaluated;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: identifier: %@ scheme: %@ value: %@>",[self class],self,identifier,scheme,_value];
}

-(void)startObserving
{
    
}

-(void)stopObserving
{
    
}

-(NSUInteger)hash
{
    return ([[self identifier] hash] << 2) ^ (NSUInteger)[self defaultContext];
}

-(BOOL)isEqual:(id)object
{
    return [[self identifier] isEqual:[object identifier]] &&
            [self defaultContext] == [object defaultContext];
}

-(void)dealloc
{
	[_value release];           // this used to be disabled, probably because of unclear over-release crashers
	[scheme release];
	[identifier release];
	[super dealloc];
}




@end

#endif

@implementation MPWBinding(legacy)

-(void)bindValue:newValue
{
    [self setValue:newValue];
    //    [self setIsBound:YES];
    //    [self didChange];
}

-(void)setIdentifier:newIdentifier
{
    [self setReference:newIdentifier];
}

-(void)setScheme:newScheme
{
    [self setStore:newScheme];
}

-scheme
{
    return self.store;
}

-identifier
{
    return [self reference];
}

-(void)setDefaultContext:newContext
{
}

-name
{
    return [[self.reference pathComponents] componentsJoinedByString:@"/"];
}

-initWithValue:aValue
{
    NSAssert1( aValue == nil,@"-initWithValue expecting nil, got %@",aValue);
    return [self init];
}

@end

