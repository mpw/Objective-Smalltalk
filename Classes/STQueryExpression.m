//
//  STQueryExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 19.11.24.
//

#import "STQueryExpression.h"

@implementation STQueryExpression

-(id)evaluateIn:(id)aContext
{
    NSArray* receiver = (NSArray*)[self.receiver evaluateIn:aContext];
    id predicateBlock = [self.predicate evaluateIn:aContext];
    NSMutableArray *result=[NSMutableArray array];
    for ( id anObject in receiver) {
        if ( [[predicateBlock value:anObject] intValue]) {
            [result addObject:anObject];
        }
    }
    return result;
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation STQueryExpression(testing) 

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
