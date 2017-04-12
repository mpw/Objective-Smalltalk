//
//  MPWClassDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 4/12/17.
//
//

#import "MPWClassDefinition.h"

@implementation MPWClassDefinition

-(void)dealloc
{
    [_name release];
    [_superclassName release];
    [_instanceVariableDescriptions release];
    [_methods release];
    [super dealloc];
}

@end
