//
//  MPWComplexAssignment.m
//  MPWTalk
//
//  Created by Marcel Weiher on 7/11/12.
//
//

#import "MPWComplexAssignment.h"

@implementation MPWComplexAssignment

-(NSObject<MPWEvaluable>*)evaluateIn:aContext
{
	id value = [aContext evaluate:[self rhs]];
    //	NSLog(@"rhs: %@ value: %@, varName: %@",[self rhs],value,varName);
	[aContext bindValue:value toVariableNamed:[[lhs identifier] evaluatedIdentifierNameInContext:aContext] withScheme:[lhs scheme]];
	return nil;
}



@end
