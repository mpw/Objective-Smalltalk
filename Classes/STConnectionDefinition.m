//
//  STConnectionDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 20.05.23.
//

#import "STConnectionDefinition.h"

@implementation STConnectionDefinition

-instanceVariableDescriptions
{
    return self.structureDefinition.fields;
}

-(void)dealloc
{
    [_name release];
    [_structureDefinition release];
    [_methods release];
    [_propertyPathDefinitions release];
   [super dealloc];
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation STConnectionDefinition(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
