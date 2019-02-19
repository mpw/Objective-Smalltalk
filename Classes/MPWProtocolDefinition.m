//
//  MPWProtocolDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 19.02.19.
//

#import "MPWProtocolDefinition.h"
#import "MPWMethodHeader.h"
#import <objc/runtime.h>

@implementation MPWProtocolDefinition

-(void)addMethodDefinitions:(Protocol*)p
{
    for ( MPWMethodHeader *header in self.methods) {
        const char *name=[[header methodName] UTF8String];
        const char *types=[header typeSignature];
        SEL sel=sel_registerName(name);
        protocol_addMethodDescription(p, sel, types, NO, YES);
    }
}

-(void)defineProtocol
{
    Protocol *p = objc_allocateProtocol([[self name] UTF8String]);
    [self addMethodDefinitions:p];
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
