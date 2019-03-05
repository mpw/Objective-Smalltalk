//
//  MPWPropertyPathDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import "MPWPropertyPathDefinition.h"

@implementation MPWPropertyPathDefinition


-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: propertyPath: %@>",[self class],self,[self propertyPath]];
}

-(void)dealloc
{
    [_propertyPath release];
    [_get release];
    [_set release];
    [super dealloc];
}

@end
