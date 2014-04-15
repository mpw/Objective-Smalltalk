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


-valueForBinding:(MPWGenericBinding*)aBinding
{
    return NSClassFromString([aBinding name]);
}

-(NSArray*)childrenOf:(MPWGenericBinding*)binding
{
    //  yes, it ignores the binding passed in
    NSArray *allClasses=[MPWClassMirror allClasses];
    NSMutableArray *bindings=[NSMutableArray array];
    for ( MPWClassMirror *cm in allClasses ) {
        [bindings addObject:[self bindingForName:[cm name] inContext:nil]];
    }
    return bindings;
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


