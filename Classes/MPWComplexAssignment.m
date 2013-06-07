//
//  MPWComplexAssignment.m
//  MPWTalk
//
//  Created by Marcel Weiher on 7/11/12.
//
//

#import "MPWComplexAssignment.h"
#import "MPWEvaluator.h"
#import "MPWIdentifierExpression.h"
#import "MPWIdentifier.h"


@implementation MPWComplexAssignment

-(NSObject<MPWEvaluable>*)evaluateIn:(MPWEvaluator*)aContext
{
	id value = [aContext evaluate:[self rhs]];
    //	NSLog(@"rhs: %@ value: %@, varName: %@",[self rhs],value,varName);
	[aContext bindValue:value toVariableNamed:[[lhs identifier] evaluatedIdentifierNameInContext:aContext] withScheme:[lhs scheme]];
	return nil;
}



@end
