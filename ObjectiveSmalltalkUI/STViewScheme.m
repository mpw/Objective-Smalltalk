//
//  STViewScheme.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 06.04.21.
//

#import "STViewScheme.h"

@implementation STViewScheme

-(NSArray*)subviewNames
{
    return nil;
}


-(id)at:(id<MPWReferencing>)aReference
{
    return nil;
}

-(NSArray<MPWReference *> *)childrenOfReference:(id<MPWReferencing>)aReference
{
    return nil;

}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation STViewScheme(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end
