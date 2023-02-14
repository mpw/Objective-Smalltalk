//
//  MPWScheme.m
//  Arch-S
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWScheme.h"
#import "MPWBindingLegacy.h"
#import "MPWIdentifier.h"
#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/NSNil.h>
#import "STEvaluator.h"
#import "STMessagePortDescriptor.h"

@implementation MPWAbstractStore(SchemeCompatibility)

+scheme
{
    return [[[self alloc] init] autorelease];
}

-bindingForReference:aReference inContext:aContext
{
    return [MPWBinding bindingWithReference:aReference inStore:self];
}

-bindingWithIdentifier:(MPWIdentifier*)anIdentifier withContext:aContext
{
    id <MPWReferencing> ref=[self referenceForPath:[anIdentifier evaluatedIdentifierNameInContext:aContext]];
    ref.schemeName=anIdentifier.schemeName;
    return [self bindingForReference:ref inContext:aContext];
}


-bindingForName:(NSString*)variableName inContext:aContext
{
    return [self bindingForReference:[self referenceForPath:variableName] inContext:aContext];
}




@end

@implementation MPWScheme
@end

@implementation MPWAbstractStore(completion)




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
    id <MPWReferencing> ref=[self referenceForPath:prefix];
    NSArray *potentialChildren=[self childrenOfReference:ref];
    NSMutableArray *names=[NSMutableArray array];
    for ( MPWGenericReference *reference in potentialChildren) {
        NSString *name = [reference path];
        if ( [name hasPrefix:@"./"]) {
             name=[name substringFromIndex:2];
        }
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

@implementation MPWAbstractStore(caching)


-(MPWScheme*)cachedBy:cacheScheme
{
    return (MPWScheme*)[MPWWriteThroughCache storeWithSource:self cache:cacheScheme];
}

-before:otherScheme
{
    return [self cachedBy:otherScheme];
}

-defaultInputPort
{
    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:nil protocol:@protocol(MPWStorage) sends:NO] autorelease];
}

@end

@implementation MPWMappingStore(ports)

-defaultOutputPort
{
    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:@"source" protocol:@protocol(MPWStorage) sends:YES] autorelease];
}


@end
