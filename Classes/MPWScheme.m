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

-(NSArray<MPWReference*>*)childrenOfReference:(MPWReference*)aReference
{
    return @[];
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
    MPWGenericReference *ref=[MPWGenericReference referenceWithPath:prefix];
    NSArray *potentialChildren=[self childrenOfReference:ref];
    NSMutableArray *names=[NSMutableArray array];
    for ( MPWGenericReference *reference in potentialChildren) {
        NSString *name = [reference path];
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
