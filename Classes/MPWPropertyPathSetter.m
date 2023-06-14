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


-declarationString
{
    return @"<void>at:aReference put:newValue";
}

-(id)evaluateOnObject:(id)target parameters:(NSArray *)parameters
{
    id extraParameters[2];
    [parameters getObjects:extraParameters range:NSMakeRange(0,2)];
    id ref = extraParameters[0];
    return [self.store at:ref for:target with:extraParameters count:2];
}


@end
