//
//  MPWPropertyPathDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import "MPWPropertyPathDefinition.h"

@implementation MPWPropertyPathDefinition{
    MPWScriptedMethod *methods[MPWRESTVerbMAX];
}

-(void)setMethod:(MPWScriptedMethod*)method forVerb:(MPWRESTVerb)verb
{
    [methods[verb] release];
    methods[verb]=[method retain];
}

-(MPWScriptedMethod*)getMethodAtVerb:(MPWRESTVerb)verb
{
    return methods[verb];
}


-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: propertyPath: %@>",[self class],self,[self propertyPath]];
}

-(void)dealloc
{
    [_propertyPath release];
    for (int i=0;i<MPWRESTVerbMAX;i++) {
        [methods[i] release];
    }
    [super dealloc];
}

@end
