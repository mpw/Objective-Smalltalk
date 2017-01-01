//
//  MPWClassScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 1/9/09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import "MPWClassScheme.h"
#import <MPWFoundation/DebugMacros.h>
#import "MPWGenericBinding.h"
#import "MPWIdentifier.h"
#import "MPWClassMirror.h"

@implementation MPWClassScheme


-bindingForName:aName inContext:aContext
{
    id binding = [MPWGenericBinding bindingWithName:aName scheme:self];
    return binding;
}

-bindingForMirror:aClassMirror
{
    return [self bindingForName:[aClassMirror name] inContext:nil];
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

-valueForBinding:(MPWGenericBinding*)aBinding
{
    NSString *className=[aBinding name];
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


-(NSArray*)childrenOf:(MPWGenericBinding*)binding
{
//    NSLog(@"childrenOf with binding '%@'",[binding name]);
//    if ( [[binding name] isEqualToString:@"/"]  || [[binding name] isEqualToString:@"."]) {
//        NSArray *rootMirrors=[self rootMirrors];
//        NSLog(@"root mirrors: %@",rootMirrors);
//        NSArray *bindings=[[self collect] bindingForMirror:[rootMirrors each]];
//        NSLog(@"bindings: %@",bindings);
//        return bindings;
//    }
    return [[self collect] bindingForMirror:[[self allClassMirrors] each]];
}




@end

@implementation MPWClassScheme(testing)

+(void)testSimpleClassResolve
{
	id resolver=[[self new] autorelease];
	INTEXPECT( [[resolver bindingForName:@"NSString" inContext:nil] value], [NSString class] , @"class resolver for NSString");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
				@"testSimpleClassResolve",
			nil];
}

@end


