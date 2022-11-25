//
//  STVariableDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 01.07.21.
//

#import "STVariableDefinition.h"

@implementation STVariableDefinition

-initWithName:(NSString*)newName type:(STTypeDescriptor*)newType
{
    self=[super init];
    [self setName:newName];
    [self setType:newType];
    return self;
}

-(void)accumulateLocalVars:(NSMutableArray*)vars
{
    [vars addObject:self.name];
}

-(void)dealloc
{
    [_name release];
    [_type release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STVariableDefinition(testing) 

+(void)someTest
{
//	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
