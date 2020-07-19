//
//  MPWPropertyPathSetter.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/27/18.
//

#import "MPWPropertyPathSetter.h"
#import "MPWPropertyPathDefinition.h"
#import "MPWScriptedMethod.h"

@implementation MPWPropertyPathSetter

-declarationString
{
    return @"<void>at:aReference put:newValue";
}

-(id)evaluateFoundPropertyPath:(MPWPropertyPathDefinition*)def onTarget:target boundParams:(NSDictionary*)pathParams additionalParams:(NSArray*)param
{
    MPWScriptedMethod *m=[def set];
    NSArray *params=[pathParams objectsForKeys:[def.propertyPath formalParameters] notFoundMarker:@""];
    params=[params arrayByAddingObject:param[0]];
    params = [params arrayByAddingObject:param.lastObject];
    id result=[m evaluateOnObject:target parameters:params];
    return result;
}

-(id)evaluateOnObject:(id)target parameters:(NSArray *)parameters
{
    parameters=@[ parameters[1], parameters[0]];
    return [super evaluateOnObject:target parameters:parameters];
}


@end
