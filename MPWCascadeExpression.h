//
//  MPWCascadeExpression.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 12/1/14.
//
//

#import <ObjectiveSmalltalk/STExpression.h>

@interface MPWCascadeExpression : STExpression
{
    NSMutableArray *messageExpressions;
}

-(void)addMessageExpression:messageExpression;

@end
