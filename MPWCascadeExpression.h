//
//  MPWCascadeExpression.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 12/1/14.
//
//

#import <ObjectiveSmalltalk/MPWExpression.h>

@interface MPWCascadeExpression : MPWExpression
{
    NSMutableArray *messageExpressions;
}

-(void)addMessageExpression:messageExpression;

@end
