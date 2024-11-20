//
//  STQueryExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 19.11.24.
//

#import "STQueryExpression.h"

@implementation STQueryExpression

-(id)evaluateIn:(STEvaluator*)aContext
{
    NSArray* receiver = (NSArray*)[self.receiver evaluateIn:aContext];
    id predicateBlock = [self.predicate evaluateIn:aContext];
    id oldQ = [aContext schemeForName:@"q"];
    id oldDefault = [aContext schemeForName:@"default"];
    NSMutableArray *result=[NSMutableArray array];
    @try {
        MPWPropertyStore* qScheme = [MPWPropertyStore store];
        MPWSequentialStore *newDefault = [MPWSequentialStore storeWithStores:@[ oldDefault,qScheme]];
        [[aContext schemes] setSchemeHandler:newDefault forSchemeName:@"default"];
        for ( id anObject in receiver) {
            qScheme.baseObject = anObject;
            if ( [[predicateBlock value:anObject] intValue]) {
                [result addObject:anObject];
            }
        }
    } @finally {
        [[aContext schemes] setSchemeHandler:oldDefault forSchemeName:@"default"];
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
