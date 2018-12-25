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
    return @"<void>setObject:newValue forReference:aReference";
}

-(id)evaluateFoundPropertyPath:(MPWPropertyPathDefinition*)def onTarget:target boundParams:(NSDictionary*)pathParams additionalParams:param
{
    //            NSLog(@"matched: %@",def.propertyPath.pathComponents);
    //            NSLog(@"matched args: %@",pathParams);
    MPWScriptedMethod *m=[def set];
    NSArray *params=[pathParams objectsForKeys:[def.propertyPath formalParameters] notFoundMarker:@""];
    params=[params arrayByAddingObject:param[0]];
    //            NSLog(@"array aprams: %@",params);
    id result=[m evaluateOnObject:target parameters:params];
    return result;
}



@end
