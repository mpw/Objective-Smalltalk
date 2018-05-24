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
    id evaluatedName=[anIdentifier evaluatedIdentifierNameInContext:aContext];
//    NSLog(@"bindingWithIdentifier evaluatedName: %@",evaluatedName);
	MPWBinding *binding = [self bindingForName:evaluatedName inContext:aContext];
//    NSLog(@"bindingWithIdentifier binding: %@",binding);
    [binding setScheme:self];
    [binding setIdentifier:anIdentifier];
    [binding setDefaultContext:aContext];
//    NSLog(@"bindingWithIdentifier binding scheme: %@",[binding scheme]);
//    NSLog(@"bindingWithIdentifier binding iidentifier: %@",[binding identifier]);
    return binding;
}



-evaluateIdentifier:anIdentifer withContext:aContext
{
//    NSLog(@"-[%@ %@]",[self className],NSStringFromSelector(_cmd));
    MPWScheme *scheme=[anIdentifer scheme];
    id value = [scheme objectForReference:anIdentifer];
    if ( !value ) {
        MPWBinding *binding=[self bindingWithIdentifier:anIdentifer withContext:aContext];
        if (!binding) {
            NSLog(@"no binding");
            value=[aContext valueForUndefinedVariableNamed:[anIdentifer identifierName]];
            NSLog(@"no binding, valueForUndefined value: %@",value);
        } else {
            value=[binding value];
        }
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
