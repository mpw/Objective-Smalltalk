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

-(void)setupStoreWithPaths:(NSArray<MPWPropertyPathDefinition*>*)newPaths
{
    for ( MPWPropertyPathDefinition *def in newPaths) {
        if ( def.set ) {
            self.store[def.propertyPath] = def.set;
        }
    }
}


-(instancetype)initWithPropertyPathDefinitions:(NSArray<MPWPropertyPathDefinition *> *)defs
{
    self=[super initWithPropertyPathDefinitions:defs];
    self.store.useParam = true;
    return self;
}

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
    id ref=[parameters.firstObject name];        // the lastObject is an MPWIdentifier
    NSLog(@"setter: %@",ref);
    self.store.target = target;                 // should pass as parameter not method
    self.store.additionalParam = parameters.lastObject;
    return [self.store at:ref];         // this returns nil when there's no match, previous threw exception?
}


@end
