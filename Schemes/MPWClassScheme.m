//
//  MPWClassScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 1/9/09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import "MPWClassScheme.h"
#import <MPWFoundation/DebugMacros.h>
#import "MPWBinding.h"

@implementation MPWClassScheme


-bindingForName:aName inContext:aContext
{
     id binding = [MPWBinding bindingWithValue:NSClassFromString(aName)];
	return binding;
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


