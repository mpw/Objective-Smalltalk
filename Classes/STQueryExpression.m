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
    return [receiver evaluateQuery:self inContext:aContext];
}

-(id)runAgainstArray:(NSArray*)receiver inContext:aContext
{
    id predicateBlock = [self.predicate evaluateIn:aContext];
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


@implementation NSArray(querying)

-(NSArray*)evaluateQuery:(STQueryExpression*)query inContext:aContext
{
    return [query runAgainstArray:self inContext:aContext];
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

#import "MPWMessageExpression.h"

@implementation MPWSQLiteTable(query)

-(NSArray*)evaluateQuery:(STQueryExpression*)query inContext:aContext
{
//    NSLog(@"table %@ evaluate query: %@",self.name, query);
//    NSLog(@"predicate: %@",query.predicate);
    MPWMessageExpression* expression=[query.predicate statements];
    NSString *selector = [expression nonMappedMessageName];
    NSString *receiverName = [[expression receiver] name];
    NSString *argument = [[[expression args] objectAtIndex:0] theLiteral];
    if ( [argument isKindOfClass:[NSString class]]) {
        argument=[NSString stringWithFormat:@"\"%@\"",argument];
    }
    NSString *sqlQuery = [NSString stringWithFormat:@"%@ %@ %@",receiverName,selector,argument];
    return [self selectWhere:sqlQuery];
}


@end
