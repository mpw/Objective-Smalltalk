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

@interface MPWPropertyPathGetter()

@property (nonatomic,strong) NSArray<MPWPropertyPathDefinition*> *propertyPathDefs;

@end

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
    //            NSLog(@"matched: %@",def.propertyPath.pathComponents);
    //            NSLog(@"matched args: %@",pathParams);
    MPWScriptedMethod *m=[def get];
    NSArray *params=[pathParams objectsForKeys:[def.propertyPath formalParameters] notFoundMarker:@""];
    //            NSLog(@"array aprams: %@",params);
    params = [params arrayByAddingObject:param.lastObject];
    id result=[m evaluateOnObject:target parameters:params];
    return result;
}


-(id)evaluateOnObject:(id)target parameters:(NSArray *)parameters
{
    id <MPWReferencing> ref=parameters.lastObject;
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

-declarationString
{
    return @"objectForReference:aReference";
}

-(void)dealloc
{
    [_propertyPathDefs release];
    [super dealloc];
}

@end
