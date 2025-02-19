//
//  STPropertyPathDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import "STPropertyPathDefinition.h"

@implementation STPropertyPathDefinition{
    STScriptedMethod *methods[MPWRESTVerbMAX];
}

-(void)setMethod:(STScriptedMethod*)method forVerb:(MPWRESTVerb)verb
{
    [methods[verb] release];
    methods[verb]=[method retain];
}

-(STScriptedMethod*)methodForVerb:(MPWRESTVerb)verb
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
