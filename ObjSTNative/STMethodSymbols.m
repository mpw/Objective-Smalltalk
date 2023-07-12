//
//  STMethodSymbols.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 12.07.23.
//

#import "STMethodSymbols.h"

@implementation STMethodSymbols

-(instancetype)init
{
    self=[super init];
    self.symbolNames=[NSMutableArray array];
    self.methodNames=[NSMutableArray array];
    self.methodTypes=[NSMutableArray array];
    return self;
}

-(void)dealloc
{
    [_methodNames release];
    [_methodTypes release];
    [_symbolNames release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STMethodSymbols(testing) 

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
