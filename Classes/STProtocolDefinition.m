//
//  STProtocolDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 19.02.19.
//

#import "STProtocolDefinition.h"
#import "MPWMethodHeader.h"
#import <objc/runtime.h>

@implementation STProtocolDefinition

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

-(id)evaluateIn:(id)aContext
{
    [self defineProtocol];
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

@end
