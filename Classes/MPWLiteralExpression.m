//
//  MPWLiteralExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/17/14.
//
//

#import "MPWLiteralExpression.h"
#import "STEvaluator.h"
#import <MPWFoundation/MPWByteStream.h>
#import "MPWScheme.h"
#import "MPWStScanner.h"

@implementation MPWLiteralExpression

idAccessor(theLiteral, setTheLiteral)

-(id)evaluateIn:(id)aContext
{
//    NSLog(@"literalExpression '%@' evaluatIn: %@",theLiteral,aContext);
//    NSLog(@"aContext var scheme: %@",[aContext schemeForName:@"var"]);
    id result=theLiteral;
    if ( [result isKindOfClass:[MPWStringLiteral class]] ) {
        MPWStringLiteral *s=(MPWStringLiteral*)result;
        if (![s hasSingleQuotes]) {
//            NSLog(@"==will interpolate===");
            result=[NSMutableString string];
            MPWByteStream *stream=[MPWByteStream streamWithTarget:result];
//            NSLog(@"interpolating string %@ with context: %@",theLiteral,aContext);
            [stream writeInterpolatedString:theLiteral withEnvironment:(MPWAbstractStore*)aContext];
//            NSLog(@"result: %@",result);
        } else {
            result=[s realString];
        }
    }
    return result;
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
