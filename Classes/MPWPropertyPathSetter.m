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

-(id)evaluateOnObject:(id)target parameters:(NSArray *)parameters
{
    id ref=[parameters.firstObject name];        // the lastObject is an MPWIdentifier
    NSLog(@"setter: %@",ref);
    self.store.target = target;                 // should pass as parameter not method
    self.store.additionalParam = parameters.lastObject;
    return [self.store at:ref];         // this returns nil when there's no match, previous threw exception?
}


@end
