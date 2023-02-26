//
//  MPWVarScheme.m
//  Arch-S
//
//  Created by Marcel Weiher on 25.12.09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import "MPWVarScheme.h"
#import "MPWVARBinding.h"
#import "STEvaluator.h"
#import "MPWIdentifier.h"

@implementation MPWVarScheme
-(Class)bindingClass
{
    return [MPWVARBinding class];
}

-bindingForReference:aReference inContext:aContext
{
    NSString *variableName=[aReference path];
    MPWBinding *binding = [aContext cachedBindingForName:variableName];
    if (!binding)  {
        binding=[self createBindingForName:variableName inContext:aContext];
        [aContext cacheBinding:binding forName:variableName];
    }
    return binding;
}


-createBindingForName:(NSString*)variableName inContext:(STEvaluator*)aContext
{
    NSString *firstName=variableName;
    MPWBinding *theBinding=nil;
    NSString *remainder=nil;
    NSRange firstPathSeparator=[variableName rangeOfString:@"/"];
    BOOL isCompound = firstPathSeparator.location !=  NSNotFound;
    if ( isCompound ) {
        firstName=[variableName substringToIndex:firstPathSeparator.location];
        remainder=[variableName substringFromIndex:firstPathSeparator.location+1];
    }
    theBinding=[aContext bindingForLocalVariableNamed:firstName];
    [theBinding setReference:[MPWIdentifier identifierWithName:firstName]];
    if ( isCompound) {
        theBinding= [[[[self bindingClass] alloc] initWithBaseObject:[theBinding value] path:remainder] autorelease];
    }
    return theBinding;
}

-(id)at:(id)aReference
{
    NSArray *pathComponents = [aReference relativePathComponents];
    id tempValue = [[self.context bindingForLocalVariableNamed: [pathComponents firstObject]] value];
    if ( pathComponents.count > 1) {
        id remainingReference = [[[[aReference class] alloc] initWithPathComponents:[pathComponents subarrayWithRange:NSMakeRange(1,pathComponents.count-1)] scheme:[aReference schemeName]] autorelease];
        tempValue=[tempValue at:remainingReference];
    }
    return tempValue;
}


-(NSArray<MPWReference*>*)childrenOfReference:(MPWReference*)aReference
{
    NSArray *allNames=[[self.context localVars] allKeys];
    NSMutableArray *bindings=[NSMutableArray array];
    for ( NSString *variableName in allNames) {
        [bindings addObject:[self referenceForPath:variableName]];
    }
    return bindings;
}
-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p:  context:%@  vars: %@>",[self class],self,
            [self context],[[self context] localVars]];
}


@end

@implementation NSArray(mykvc)

-at:anObject
{
    return [self objectAtIndex:[anObject intValue]];
}

-valueForUndefinedKey:(NSString*)aKey
{
	if ( isdigit( [aKey characterAtIndex:0] )) {
		return [self objectAtIndex:[aKey intValue]];
	} else {
		return [super valueForUndefinedKey:aKey];
	}
}


@end

@implementation NSObject(Storage)

-at:(id <MPWReferencing>)aReference
{
    return [self valueForKeyPath:[[aReference relativePathComponents] componentsJoinedByString:@"."]];
}

-(void)at:(id <MPWReferencing>)aReference put:anObject
{
//    NSLog(@"NSObject at:%@ put:%@",aReference,anObject);
    [self setValue:anObject forKeyPath:[[aReference relativePathComponents] componentsJoinedByString:@"."]];
}

-(void)put:obj at:ref
{
    NSLog(@"put:at: called by: %@",[NSThread callStackSymbols]);
}

@end

@implementation NSMutableDictionary(putat)

-(void)put:obj at:ref
{
    self[[ref path]]=obj;
}

@end
