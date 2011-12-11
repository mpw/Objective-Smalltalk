//
//  MPWRelScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 5/10/11.
//  Copyright 2011 metaobject ltd. All rights reserved.
//

#import "MPWRelScheme.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWIdentifier.h"
#import "MPWBinding.h"

@implementation MPWRelScheme

objectAccessor( MPWScheme, baseScheme, setBaseScheme )
objectAccessor( NSString, baseIdentifier, setBaseIdentifier )

-bindingForName:anIdentifierName inContext:aContext
{
	return [[self baseScheme] bindingForName:[[self baseIdentifier] stringByAppendingPathComponent:anIdentifierName] inContext:aContext];
}


-initWithBaseScheme:(MPWScheme*)aScheme baseURL:(NSString*)str
{
	self=[super init];
	[self setBaseScheme:aScheme];
	[self setBaseIdentifier:str];
	return self;
}

-initWithBaseRef:(MPWBinding*)aBinding
{
    [aBinding scheme];
}

-(void)dealloc
{
	[baseScheme release];
	[baseIdentifier release];
	[super dealloc];
}

@end

