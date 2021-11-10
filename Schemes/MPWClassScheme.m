//
//  MPWClassScheme.m
//  Arch-S
//
//  Created by Marcel Weiher on 1/9/09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import "MPWClassScheme.h"
#import <MPWFoundation/DebugMacros.h>
#import "MPWIdentifier.h"
#import "MPWClassMirror.h"

@implementation MPWClassScheme


-referenceForMirror:aClassMirror
{
    return [self referenceForPath:[aClassMirror name]];
}

-(NSArray *)allClassMirrors
{
    return [MPWClassMirror allClasses];
}

-(NSArray *)rootMirrors
{
    NSArray *mirrors=[self allClassMirrors];
    NSMutableArray *result=[NSMutableArray array];
    for ( MPWClassMirror *mirror in mirrors ) {
        if ( ![mirror superclassMirror] ) {
            [result addObject:mirror];
        }
    }
    return result;
}

-(id)at:(id)aReference
{
    NSString *className=[aReference path];
    if ( [className length] == 0 || [className isEqualToString:@"."] ) {
        return [[[self allClassMirrors] collect] name];
    } else if ( [className isEqualToString:@"/"]  )  {
        return [[[self rootMirrors] collect] name];
    } else {
        if ( [className hasPrefix:@"/"]) {
            className=[className substringFromIndex:1];
        }
        return NSClassFromString(className);
    }
}


-(NSArray*)childrenOfReference:(MPWGenericReference*)aReference
{
//    NSLog(@"childrenOf with binding '%@'",[binding name]);
//    if ( [[binding name] isEqualToString:@"/"]  || [[binding name] isEqualToString:@"."]) {
//        NSArray *rootMirrors=[self rootMirrors];
//        NSLog(@"root mirrors: %@",rootMirrors);
//        NSArray *bindings=[[self collect] bindingForMirror:[rootMirrors each]];
//        NSLog(@"bindings: %@",bindings);
//        return bindings;
//    }
    return [[[self collect] referenceForMirror:[[self allClassMirrors] each]] subarrayWithRange:NSMakeRange(0,100)];
}

-(BOOL)hasChildren:(id<MPWReferencing>)aReference
{
    return [self childrenOfReference:aReference] > 0;
}


@end

@implementation MPWClassScheme(testing)

+(void)testSimpleClassResolve
{
	id resolver=[[self new] autorelease];
    INTEXPECT( [resolver at:[MPWGenericReference referenceWithPath:@"NSString"]], [NSString class] , @"class resolver for NSString");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
				@"testSimpleClassResolve",
			nil];
}

@end


