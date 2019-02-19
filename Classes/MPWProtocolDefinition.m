//
//  MPWProtocolDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 19.02.19.
//

#import "MPWProtocolDefinition.h"

@implementation MPWProtocolDefinition


-(void)dealloc
{
    [_name release];
    [_instanceVariableDescriptions release];
    [_methods release];
    [_propertyPathDefinitions release];
    [super dealloc];
}

@end
