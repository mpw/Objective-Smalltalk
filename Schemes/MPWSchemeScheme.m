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
#import "MPWIdentifier.h"
#import <MPWFoundation/MPWGenericReference.h>

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

-(void)setSchemeHandler:(MPWAbstractStore*)aScheme   forSchemeName:(NSString*)schemeName
{
//    NSLog(@"%p scheme handler: '%@' for scheme name: '%@'",self,aScheme,schemeName);
    if ( aScheme && schemeName) {
        [[self _schemes] setObject:aScheme forKey:schemeName];
    }
}

-(id)objectForReference:(id)aReference
{
    // FIXME:  identiifierName is legacy 
    return [[self schemes] objectForKey:[aReference identifierName]];
}

-(void)setObject:(id)theObject forReference:(id)aReference
{
    [self _schemes][[aReference identifierName]]=theObject;
}

-bindingForReference:aReference inContext:aContext
{
    NSString *variableName=[aReference path];
//    NSLog(@"%p bindingForName: %@",self,variableName);
    id localVars = [self localVarsForContext:aContext];
    MPWBinding* binding=nil;
//    NSLog(@"scheme %p: localVars: %@",self,localVars);
    binding = [[[MPWVARBinding alloc] initWithBaseObject:localVars path:variableName] autorelease];
    [binding setReference:[MPWIdentifier identifierWithName:variableName]];
    [binding setStore:self];
//    NSLog(@"binding: %@",binding);
    return binding;
}

-(id)copy
{
    MPWSchemeScheme* copy=[[self class] new];
    NSDictionary *theSchemes=[self schemes];
    for ( NSString *key in [theSchemes allKeys]) {
        [copy setSchemeHandler:theSchemes[key] forSchemeName:key];
    }
    return copy;

}


-objectForKey:aKey
{
	return [[self schemes] objectForKey:aKey];
}

-(NSArray<MPWReference*>*)childrenOfReference:(MPWReference*)aReference
{
    NSArray *allNames=[[self schemes] allKeys];
    NSMutableArray *reference=[NSMutableArray array];
    for ( NSString *variableName in allNames) {
        [reference addObject:[self referenceForPath:variableName]];
    }
    return reference;
}

-(NSArray *)completionsForPartialName:(NSString *)partialName inContext:aContext
{
    return (NSArray*)[[[super completionsForPartialName:partialName inContext:aContext] collect] stringByAppendingString:@":"];
}


-description
{
	return [NSString stringWithFormat:@"<%@:%p: scheme-resolver with the following schemes: %@>",[self class],self,[[self schemes] allKeys]];
}

-(void)dealloc
{
	[_schemes release];
	[super dealloc];
}

@end
