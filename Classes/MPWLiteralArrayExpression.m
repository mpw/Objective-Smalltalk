//
//  MPWLiteralArrayExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 1/22/17.
//
//

#import "MPWLiteralArrayExpression.h"

@implementation MPWLiteralArrayExpression

-evaluateIn:aContext
{
//    NSLog(@"will evaluate literarl array: %@",[self objects]);
    NSMutableArray *result=[NSMutableArray arrayWithCapacity:self.objects.count];
    for ( MPWExpression *e in self.objects) {
        [result addObject:[e evaluateIn:aContext]];
    }
//    NSLog(@"evaluated literal array :%@",result);
    return result;
}

-(void)dealloc
{
    [_objects release];
    [super dealloc];
}

@end
