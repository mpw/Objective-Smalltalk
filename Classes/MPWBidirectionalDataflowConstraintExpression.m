//
//  MPWBidirectionalDataflowConstraintExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 6/3/15.
//
//

#import "MPWBidirectionalDataflowConstraintExpression.h"
#import "STIdentifierExpression.h"
#import "STIdentifier.h"

@implementation MPWBidirectionalDataflowConstraintExpression

-(id)evaluateIn:(id <STEvaluation>)aContext
{
    id lhobject=[lhs evaluateIn:aContext];
    if ( [lhobject  respondsToSelector:@selector(setBinding:)]) {
        if ( [rhs isKindOfClass:[STIdentifierExpression class]] ) {
            STIdentifierExpression *r=(STIdentifierExpression*)rhs;
            MPWReference *b=[[r identifier] bindingWithContext:aContext];

            // check/ensure that RHS binding has a notification mechanism
            // check/ensure that LHS is hooked up to notification mechanism
            
            [lhobject setBinding:b];
            return b;
        } else {
            @throw [NSException exceptionWithName:@"bidiconstraint" reason:@"RHS must be an identifier expression" userInfo:nil];
        }
    } else {
        if ( true ) {
            id forward = [lhs syncToTarget:rhs inContext:aContext];
//            id backward = [rhs syncToTarget:lhs inContext:aContext];
            id constraints =  @{ @"forward": forward,
                                 // @"backward": backward
            };
            return constraints;
        } else {
            @throw [NSException exceptionWithName:@"bidiconstraint" reason:@"LHS must be bindable using setBinding:" userInfo:nil];
        }
        
    }
//    @throw [NSException exceptionWithName:@"bidiconstraint" reason:@"Shouldn't get here" userInfo:nil];

}

@end
