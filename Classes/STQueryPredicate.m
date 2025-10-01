//
//  STQueryPredicate.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 23.09.25.
//

#import "STQueryPredicate.h"
#import "MPWMessageExpression.h"

@implementation STQueryPredicate

-(NSPredicate*)asNSPredicate
{
    MPWMessageExpression* expression=[self statements];
    NSString *selector = [expression nonMappedMessageName];
    NSString *receiverName = [[expression receiver] name];
    NSString *argument = [[[expression args] objectAtIndex:0] theLiteral];
    if ( [argument isKindOfClass:[NSString class]]) {
        if ( [selector isEqual:@"="]) {
            argument=[NSString stringWithFormat:@"\"%@\"",argument];
        } else if ( [selector isEqual:@"hasPrefix:"]) {
            argument=[NSString stringWithFormat:@"\"%@%%\"",argument];
            selector=@"LIKE";
        } else if ( [selector isEqual:@"isGreaterThan:"]) {
            argument=[NSString stringWithFormat:@"\"%@%%\"",argument];
            selector=@">";
        } else if ( [selector isEqual:@"isLessThan:"]) {
            argument=[NSString stringWithFormat:@"\"%@%%\"",argument];
            selector=@"<";
        } else {
            @throw [NSException exceptionWithName:@"unsupportedquery" reason:@"Unsupported Query" userInfo:@{}];
        }
    }
    NSString *sqlQuery = [NSString stringWithFormat:@"%@ %@ %@",receiverName,selector,argument];
    return [NSPredicate predicateWithFormat:sqlQuery];

}

-(id)runAgainstArray:(NSArray*)receiver inContext:aContext
{
    return [receiver filteredArrayUsingPredicate:[self asNSPredicate]];
}




@end


#import <MPWFoundation/DebugMacros.h>

@implementation STQueryPredicate(testing) 

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
