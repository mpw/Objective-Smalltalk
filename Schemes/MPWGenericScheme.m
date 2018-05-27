//
//  MPWGenericScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/21/11.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "MPWGenericScheme.h"
#import "MPWGenericBinding.h"

@implementation MPWGenericScheme


-(MPWBinding*)bindingForName:uriString inContext:aContext
{
	return [[[MPWGenericBinding alloc] initWithName:uriString scheme:self] autorelease];
}


-(BOOL)hasChildren:(MPWGenericBinding*)binding
{
    return NO;
}

-(NSArray*)childrenOf:(MPWGenericBinding*)binding
{
    return @[];
}

-(void)delete:(MPWGenericBinding*)binding
{
}

@end
