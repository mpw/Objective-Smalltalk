//
//  STFilterDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/1/18.
//

#import "STFilterDefinition.h"

@implementation STFilterDefinition


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
