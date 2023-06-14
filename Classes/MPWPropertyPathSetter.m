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

-(int)numberOfExtraParameters
{
    return 2;
}



@end
