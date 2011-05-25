//
//  MPWGenericBinding.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 11/27/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWGenericBinding.h"
#import <MPWFoundation/MPWFoundation.h>

@implementation MPWGenericBinding

objectAccessor( NSString*, name, setName )
idAccessor( scheme, setScheme )

-initWithName:(NSString*)envName scheme:newScheme
{
	self=[super init];
	[self setName:envName];
	[self setScheme:newScheme];
	return self;
}


-(BOOL)isBound
{
	return [[self scheme] isBoundBinding:self];
}

-_value
{
	return [[self scheme] valueForBinding:self];
}

-(void)_setValue:newValue
{
	[[self scheme] setValue:newValue forBidning:self];
}



-(void)dealloc
{
	[name release];
	[scheme release];
	[super dealloc];
}

@end
