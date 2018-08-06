//
//  MPWPropertyPathDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import "MPWPropertyPathDefinition.h"

@implementation MPWPropertyPathDefinition

-(void)dealloc
{
    [_propertyPath release];
    [_body release];
    [super dealloc];
}

@end
