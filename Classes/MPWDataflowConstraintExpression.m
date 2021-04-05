//
//  MPWDataflowConstraintExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/31/15.
//
//

#import "MPWDataflowConstraintExpression.h"

@implementation MPWDataflowConstraintExpression

-(id)evaluateIn:(id)aContext
{
    @throw [NSException exceptionWithName:@"constraint" reason:@"Unidirectional constraints not implemented" userInfo:nil];
}

@end
