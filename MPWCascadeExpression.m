//
//  MPWCascadeExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 12/1/14.
//
//

#import "MPWCascadeExpression.h"

@implementation MPWCascadeExpression

objectAccessor(NSMutableArray*, messageExpressions, setMessageExpressions)


-(instancetype)init
{
    self=[super init];
    [self setMessageExpressions:[NSMutableArray array]];
    return self;
}

-(id)evaluateIn:(id)aContext
{
    id result=nil;
    for ( id expr in messageExpressions) {
        result=[expr evaluateIn:aContext];
    }
    return result;
}

-(void)addMessageExpression:messageExpression
{
    [messageExpressions addObject:messageExpression];
}

@end
