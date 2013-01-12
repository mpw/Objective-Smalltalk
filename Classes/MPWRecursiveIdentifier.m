//
//  MPWRecursiveIdentifier.m
//  MPWTalk
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWRecursiveIdentifier.h"


@implementation MPWRecursiveIdentifier

idAccessor( nextIdentifer, setNextIdentifier )

-(void)dealloc
{
	[nextIdentifer release];
	[super dealloc];
}
@end
