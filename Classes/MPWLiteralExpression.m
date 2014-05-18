//
//  MPWLiteralExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/17/14.
//
//

#import "MPWLiteralExpression.h"

@implementation MPWLiteralExpression

idAccessor(theLiteral, setTheLiteral)

-(id)evaluateIn:(id)aContext
{
    return theLiteral;
}

-negated
{
    return [[self theLiteral] negated];
}

-(void)dealloc
{
    [theLiteral release];
    [super dealloc];
}

@end
