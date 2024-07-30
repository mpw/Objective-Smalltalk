//
//  MPWBidirectionalDataflowConstraintExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 6/3/15.
//
//

#import "MPWBidirectionalDataflowConstraintExpression.h"
#import "MPWIdentifierExpression.h"
#import "STIdentifier.h"

@implementation MPWBidirectionalDataflowConstraintExpression

-(id)evaluateIn:(id)aContext
{
    id lhobject=[lhs evaluateIn:aContext];
    if ( [lhobject  respondsToSelector:@selector(setBinding:)]) {
        if ( [rhs isKindOfClass:[MPWIdentifierExpression class]] ) {
            MPWIdentifierExpression *r=(MPWIdentifierExpression*)rhs;
            MPWBinding *b=[[r identifier] bindingWithContext:aContext];

            // check/ensure that RHS binding has a notification mechanism
            // check/ensure that LHS is hooked up to notification mechanism
            
            [lhobject setBinding:b];
            return b;
        } else {
            @throw [NSException exceptionWithName:@"bidiconstraint" reason:@"RHS must be an identifier expression" userInfo:nil];
        }
    } else {
        @throw [NSException exceptionWithName:@"bidiconstraint" reason:@"LHS can't be bound" userInfo:nil];
    }
//    @throw [NSException exceptionWithName:@"bidiconstraint" reason:@"Shouldn't get here" userInfo:nil];

}

@end
