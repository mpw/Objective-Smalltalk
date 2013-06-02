//
//  MPWGenericBinding.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 11/27/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWGenericBinding.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWGenericScheme.h"

@implementation MPWGenericBinding

objectAccessor( NSString, name, setName )

-initWithName:(NSString*)envName scheme:newScheme
{
	self=[super init];
	[self setName:envName];
	[self setScheme:newScheme];
	return self;
}

+bindingWithName:(NSString*)envName scheme:newScheme
{
    return [[[self alloc] initWithName:envName scheme:newScheme] autorelease];
}

-path
{
    return name;
}

#define GENERICSCHEME  ((MPWGenericScheme*)[self scheme])

-(BOOL)isBound
{
	return [GENERICSCHEME isBoundBinding:self];
}

-_value
{
	return [GENERICSCHEME valueForBinding:self];
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

-childWithName:(NSString*)aName
{
    return [[self scheme] childWithName:aName of:self];
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
