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
#import "MPWIdentifier.h"
#import <MPWFoundation/NSNil.h>
#import "MPWEvaluator.h"

@implementation MPWScheme

+scheme
{
	return [[[self alloc] init] autorelease];
}

-valueForBinding:(MPWBinding*)aBinding
{
    return nil;
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

	if ( [value respondsToSelector:@selector(isNotNil)]  && ![value isNotNil] ) {
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

-(NSArray*)childrenOf:(MPWBinding*)aBinding
{
    return @[];
}

-(NSArray*)childrenOf:(MPWBinding*)aBinding inContext:aContext
{
    return [self childrenOf:aBinding];
}



-(NSArray *)completionsForPartialName:(NSString *)partialName inContext:aContext
{
//    NSLog(@"completionsForPartialName: '%@' %@",partialName,[partialName class]);
    NSArray *pathComponents=[partialName componentsSeparatedByString:@"/"];
    NSString *prefix=[[pathComponents subarrayWithRange:NSMakeRange(0, pathComponents.count-1)] componentsJoinedByString:@"/"];
    NSString *suffix=pathComponents.lastObject;
    if ( prefix.length == 0 ) {
        prefix=@".";
    }
//    NSLog(@"prefix: '%@' suffix: '%@'",prefix,suffix);
    NSArray *potentialChildren=[self childrenOf:[self bindingForName:prefix inContext:aContext] inContext:aContext];
    NSMutableArray *names=[NSMutableArray array];
    for ( MPWBinding *binding in potentialChildren) {
        NSString *name = [binding name];
//        NSLog(@"name: %@",name);
        if ( !suffix || [suffix length]==0 || [name hasPrefix:suffix] ) {
            if ( [suffix isEqualToString:name] ) {
                name=@"/";
            }
            [names addObject:name];
        }
    }
//    NSLog(@"potential names: %@",names);
    return names;
}


@end
