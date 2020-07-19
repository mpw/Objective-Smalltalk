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
    return @"<void>put:newValue at:aReference";
//    return @"<void>at:aReference put:newValue";       // FIXME at:put:
}

-(id)evaluateFoundPropertyPath:(MPWPropertyPathDefinition*)def onTarget:target boundParams:(NSDictionary*)pathParams additionalParams:(NSArray*)param
{
    //            NSLog(@"matched: %@",def.propertyPath.pathComponents);
    //            NSLog(@"matched args: %@",pathParams);
    MPWScriptedMethod *m=[def set];
    NSArray *params=[pathParams objectsForKeys:[def.propertyPath formalParameters] notFoundMarker:@""];
    params=[params arrayByAddingObject:param[0]];
            NSLog(@"array aprams: %@",params);
    params = [params arrayByAddingObject:param.lastObject];
    id result=[m evaluateOnObject:target parameters:params];
    return result;
}

-(id)evaluateOnObject1:(id)target parameters:(NSArray *)parameters
{
    NSLog(@"parameters: %@",parameters);
    id <MPWReferencing> ref=parameters.firstObject;
    parameters=[parameters subarrayWithRange:NSMakeRange(1, 1)];
    //    NSLog(@"reference: %@",ref);
    for ( MPWPropertyPathDefinition *def in self.propertyPathDefs) {
        //        NSLog(@"try def: %@",def);
        NSDictionary *pathParams=[def.propertyPath bindingsForMatchedReference:ref];
        if (pathParams) {
            ///            NSLog(@"match: %@",def);
            return [self evaluateFoundPropertyPath:def onTarget:target boundParams:pathParams additionalParams:parameters];
        }
    }
    //    NSLog(@"no match for %@",ref);
    [NSException raise:@"undefined" format:@"undefined path: %@ for object: %@",ref,target];
    return nil;
}


@end
