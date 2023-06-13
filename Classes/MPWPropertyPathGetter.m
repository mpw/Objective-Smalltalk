//
//  MPWPropertyPathGetter.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/26/18.
//

#import "MPWPropertyPathGetter.h"
#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/MPWReferenceTemplate.h>
#import "MPWPropertyPathDefinition.h"
#import "MPWMethodHeader.h"

@interface MPWPropertyPathGetter()

@property (nonatomic, strong) MPWTemplateMatchingStore *store;

@end

@implementation MPWPropertyPathGetter

-(void)setupStoreWithPaths:(NSArray<MPWPropertyPathDefinition*>*)newPaths
{
    for ( MPWPropertyPathDefinition *def in newPaths) {
        if ( def.get ) {
            self.store[def.propertyPath] = def.get;
        }
    }
}


CONVENIENCEANDINIT(getter, WithPropertyPathDefinitions:newPaths)
{
    self=[super init];
    self.store = [MPWTemplateMatchingStore store];
    self.store.addRef = true;
    [self setupStoreWithPaths:newPaths];
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
    id ref=[parameters.lastObject name];        // the lastObject is an MPWIdentifier
    self.store.target = target;       // circular reference, FIXME (weak, ...?)
    NSLog(@"property path getter will evaluate: %@",ref);
    [self.store at:ref];
//    id <MPWReferencing> ref=parameters.lastObject;
//    for ( MPWPropertyPathDefinition *def in self.propertyPathDefs) {
//        NSDictionary *pathParams=[def.propertyPath bindingsForMatchedReference:ref];
//        if (pathParams) {
//            return [self evaluateFoundPropertyPath:def onTarget:target boundParams:pathParams additionalParams:parameters];
//        }
//    }
//    [NSException raise:@"undefined" format:@"undefined path: '%@' for object: %@",ref,target];
//    return nil;
}

-declarationString
{
    return @"at:aReference";
}

-(void)setContext:(id)newVar
{
    [super setContext:newVar];
    for ( MPWPropertyPathDefinition *p in self.propertyPathDefs) {
        [p.get setContext:newVar];
        [p.set setContext:newVar];
    }
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
    return YES;
}

@end
