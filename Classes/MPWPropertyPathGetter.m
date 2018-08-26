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
    self.methodHeader=[MPWMethodHeader methodHeaderWithString:@"objectForReference:aReference"];
    return self;
}

-(id)evaluateOnObject:(id)target parameters:(NSArray *)parameters
{
    id <MPWReferencing> ref=parameters[0];
    NSLog(@"reference: %@",ref);
    for ( MPWPropertyPathDefinition *def in self.propertyPathDefs) {
        NSDictionary *pathParams=[def.propertyPath bindingsForMatchedReference:ref];
        if (pathParams) {
            NSLog(@"matched: %@",def.propertyPath.pathComponents);
            NSLog(@"matched args: %@",pathParams);
            MPWScriptedMethod *m=[def get];
            NSArray *params=[pathParams objectsForKeys:[def.propertyPath formalParameters] notFoundMarker:@""];
            NSLog(@"array aprams: %@",params);
            id result=[m evaluateOnObject:target parameters:params];
            return result;
        }
    }
    NSLog(@"no match for %@",ref);
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
