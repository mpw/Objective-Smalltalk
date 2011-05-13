//
//  MPWAssignmentExpression.m
//  MPWTalk
//
//  Created by marcel on Mon Jul 02 2001.
//  Copyright (c) 2001 Marcel Weiher. All rights reserved.
//

#import "MPWAssignmentExpression.h"
#import "MPWStCompiler.h"


@implementation MPWAssignmentExpression

idAccessor( rhs, setRhs )
idAccessor( lhs, setLhs )

-(void)addToVariablesWritten:(NSMutableSet*)variablesWritten
{
	[variablesWritten addObject:[lhs name]];
}

-(void)addToVariablesRead:(NSMutableSet*)variablesRead
{
	[rhs addToVariablesRead:variablesRead];
}

-(void)doAssign:other
{
	[NSException raise:@"abstract" format:@"doAssign: is only here to satisfy the compiler/SEL mapping"];
}

-(NSObject<MPWEvaluable>*)evaluateIn:aContext
{
	id value = [aContext evaluate:[self rhs]];
//	NSLog(@"rhs: %@ value: %@, varName: %@",[self rhs],value,varName);
	[aContext bindValue:value toVariableNamed:[[lhs identifier] evaluatedIdentifierNameInContext:aContext] withScheme:[lhs scheme]];
	return value;
}



-(void)dealloc
{
	[lhs release];
	[rhs release];
	[super dealloc];
}

@end
