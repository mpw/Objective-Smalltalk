//
//  MPWRecursiveIdentifier.m
//  Arch-S
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWRecursiveIdentifier.h"


@implementation MPWRecursiveIdentifier

objectAccessor( MPWIdentifier, nextIdentifer, setNextIdentifier )

-resolveRescursiveIdentifierWithContext:aContext
{
    MPWRecursiveIdentifier *identifier=[super resolveRescursiveIdentifierWithContext:aContext];
    [identifier setNextIdentifier:[self nextIdentifer]];
    return identifier;
}

-(NSString*)path
{
    return self.nextIdentifer.path;
}


-(void)dealloc
{
	[nextIdentifer release];
	[super dealloc];
}
@end
