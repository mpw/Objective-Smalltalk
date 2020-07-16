//
//  MPWLiteralExpression.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/17/14.
//
//

#import <ObjectiveSmalltalk/MPWExpression.h>

@interface MPWLiteralExpression : MPWExpression
{
    id  theLiteral;
}

idAccessor_h(theLiteral, setTheLiteral)

@property (nonatomic, strong) NSString *className;

@end
