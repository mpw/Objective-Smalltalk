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


-(MPWRESTVerb)restVerb
{
    return MPWRESTVerbPUT;
}

-declString
{
    return @"<void>at:aReference put:newValue";
}

-(int)numberOfExtraParameters
{
    return 2;
}



@end
