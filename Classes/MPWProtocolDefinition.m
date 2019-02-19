//
//  MPWProtocolDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 19.02.19.
//

#import "MPWProtocolDefinition.h"
#import <objc/runtime.h>

@implementation MPWProtocolDefinition


-(void)defineProtocol
{
    Protocol *p = objc_allocateProtocol([[self name] UTF8String]);
    objc_registerProtocol(p);
}

-(void)dealloc
{
    [_name release];
    [_instanceVariableDescriptions release];
    [_methods release];
    [_propertyPathDefinitions release];
    [super dealloc];
}

@end
