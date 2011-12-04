//
//  MPWTreeNodeScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/23/11.
//  Copyright (c) 2011 metaobject ltd. All rights reserved.
//

#import "MPWTreeNodeScheme.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWTreeNode.h"
#import "MPWGenericBinding.h"

@implementation MPWTreeNodeScheme

idAccessor( root, setRoot )

-init
{
	self = [super init];
	[self setRoot:[MPWTreeNode root]];
	return self;
}

-nodeForPath:(NSArray*)pathArray
{
    return [root nodeForPathEnumerator:[pathArray objectEnumerator]];
}

-contentForPath:(NSArray*)array
{
	return [[self nodeForPath:array] content];
}


-(void)setValue:newValue forBinding:(MPWGenericBinding*)aBinding
{
    
}


-(void)dealloc
{
	[root release];
	[super dealloc];
}


@end
