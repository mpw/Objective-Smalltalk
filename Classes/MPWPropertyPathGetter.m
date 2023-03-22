//
//  MPWPropertyPathGetter.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/26/18.
//

#import "MPWPropertyPathGetter.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWPropertyPath.h"
#import "MPWPropertyPathDefinition.h"
#import "MPWMethodHeader.h"


@implementation MPWPropertyPathGetter

CONVENIENCEANDINIT(getter, WithPropertyPathDefinitions:newPaths)
{
    self=[super init];
    self.propertyPathDefs=newPaths;
    self.methodHeader=[MPWMethodHeader methodHeaderWithString:[self declarationString]];
    return self;
}

-(id)evaluateFoundPropertyPath:(MPWPropertyPathDefinition*)def onTarget:target boundParams:(NSDictionary*)pathParams additionalParams:(NSArray*)param
{
    MPWScriptedMethod *m=[def get];
    NSArray *params=[pathParams objectsForKeys:[def.propertyPath formalParameters] notFoundMarker:@""];
    params = [params arrayByAddingObject:param.lastObject];
     id result=[m evaluateOnObject:target parameters:params];
    return result;
}


-(id)evaluateOnObject:(id)target parameters:(NSArray *)parameters
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

-declarationString
{
    return @"at:aReference";
}

-(void)dealloc
{
    [_propertyPathDefs release];
    [super dealloc];
}

-(NSString*)script
{
    return @" 'property path'. ";
}

-(BOOL)isPropertyPathDefs
{
    
}

@end
