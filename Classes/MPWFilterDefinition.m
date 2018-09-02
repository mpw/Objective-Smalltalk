//
//  MPWFilterDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/1/18.
//

#import "MPWFilterDefinition.h"

@implementation MPWFilterDefinition


-(NSString*)defaultSuperclassName
{
    return @"MPWFilter";
}

-(void)dealloc
{
    [_filterMethod release];
    [super dealloc];
}

@end
