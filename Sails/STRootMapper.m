//
//  STRootMapper.m
//  Sails
//
//  Created by Marcel Weiher on 05.03.24.
//

#import "STRootMapper.h"

@implementation STRootMapper

-(id<MPWReferencing>)mapReference:(id<MPWReferencing>)ref
{
    if ( [ref.path isEqual:@""] ) {
        ref = [MPWGenericReference referenceWithPath:@"/"];
    }
    return ref;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STRootMapper(testing) 

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
