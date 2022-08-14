//
//  MPWRecursiveIdentifier.m
//  Arch-S
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWRecursiveIdentifier.h"


@implementation MPWRecursiveIdentifier

objectAccessor(MPWIdentifier*, nextIdentifier, setNextIdentifier )

-resolveRescursiveIdentifierWithContext:aContext
{
    MPWRecursiveIdentifier *identifier=[super resolveRescursiveIdentifierWithContext:aContext];
    [identifier setNextIdentifier:[self nextIdentifier]];
    return identifier;
}

-(NSString*)path
{
    return self.nextIdentifier.path;
}


-(void)dealloc
{
	[nextIdentifier release];
	[super dealloc];
}
@end
