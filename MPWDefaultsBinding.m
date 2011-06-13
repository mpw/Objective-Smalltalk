//
//  MPWDefaultsBinding.m
//  MPWTalk
//
//  Created by Marcel Weiher on 6/4/11.
//  Copyright 2011 metaobject ltd. All rights reserved.
//

#import "MPWDefaultsBinding.h"


@implementation MPWDefaultsBinding

objectAccessor( NSString, key, setKey )

-initWithKey:newKey
{
	self=[super init];
	[self setKey:newKey];
	return self;
}

-(BOOL)isBound
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:[self key]] != nil;
}

-_value
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:[self key]]; 
}

-(void)_setValue:newValue
{
	[[NSUserDefaults standardUserDefaults] setObject:newValue forKey:[self key]];
}

-(void)dealloc
{
	[key release];
	[super dealloc];
}

@end
