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

-(NSString*)path
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
	[GENERICSCHEME setValue:newValue forBinding:self];
}

-(BOOL)isRoot
{
    return [[self name] isEqualToString:@"/"];
}

-(BOOL)hasChildren
{
    return [GENERICSCHEME hasChildren:self];
}

-(NSArray*)children
{
    return [GENERICSCHEME childrenOf:self];
}

-(void)delete
{
    [GENERICSCHEME delete:self];
}


-(NSArray*)childNames
{
    return (NSArray*)[[[[[self children] collect] path] collect] lastPathComponent];
}


-(void)dealloc
{
	[name release];
	[super dealloc];
}

@end
