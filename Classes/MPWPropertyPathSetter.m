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

-(id)evaluateOnObject_get:(id)target parameters:(NSArray *)parameters
{
    id <MPWReferencing> ref=parameters.lastObject;
    for ( MPWPropertyPathDefinition *def in self.propertyPathDefs) {
        NSDictionary *pathParams=[def.propertyPath bindingsForMatchedReference:ref];
        if (pathParams) {
            return [self evaluateFoundPropertyPath:def onTarget:target boundParams:pathParams additionalParams:parameters];
        }
    }
    [NSException raise:@"undefined" format:@"undefined path: '%@' for object: %@",ref,target];
    return nil;
}

-(id)evaluateOnObject:(id)target parameters:(NSArray *)parameters
{
    parameters=@[ parameters[1], parameters[0]];
    return [self evaluateOnObject_get:target parameters:parameters];
}


@end
