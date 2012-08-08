//
//  MPWFilterScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 8/8/12.
//
//

#import "MPWFilterScheme.h"

@implementation MPWFilterScheme

objectAccessor(MPWScheme, source, setSource)

-(void)dealloc
{
    [source release];
    [super dealloc];
}

@end
