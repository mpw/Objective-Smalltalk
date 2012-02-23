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

objectAccessor( NSString, name, setName )

-initWithName:(NSString*)envName scheme:newScheme
{
	self=[super init];
	[self setName:envName];
	[self setScheme:newScheme];
	return self;
}

-path
{
    return name;
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
	[[self scheme] setValue:newValue forBinding:self];
}

-(BOOL)isRoot
{
    return [[self name] isEqualToString:@"/"];
}

-(BOOL)hasChildren
{
    return [[self scheme] hasChildren:self];
}

-childWithName:(NSString*)name
{
    return [[self scheme] childWithName:name of:self];
}

-(NSArray*)children
{
    return [[self scheme] childrenOf:self];
}

-(NSArray*)childNames
{
    return [[[[[self children] collect] path] collect] lastPathComponent];
}


-(void)dealloc
{
	[name release];
	[super dealloc];
}

@end
