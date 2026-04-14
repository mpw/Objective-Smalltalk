//
//  STMachOStructure.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.04.26.
//

#import "STMachOStructure.h"

@implementation STMachOStructure

-initWithStructure:(MPWStructureDefinition*)newDef values:(NSArray*)newValues
{
    self=[super init];
    self.definition=newDef;
    self.values=newValues;
    return self;
}

-(void)dealloc
{
    [_definition release];
    [_values release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STMachOStructure(testing) 

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
