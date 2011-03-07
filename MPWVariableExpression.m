//
//  MPWVariableExpression.m
//  MPWTalk
//
//  Created by marcel on Mon Jul 02 2001.
//  Copyright (c) 2001 Marcel Weiher. All rights reserved.
//

#import "MPWVariableExpression.h"
#import "MPWEvaluator.h"
#import "MPWObjCGenerator.h"

@implementation MPWVariableExpression

idAccessor( name, setName )
idAccessor( scheme, setScheme )
idAccessor( evaluationEnvironment, setEvaluationEnvironment )

-evaluateIn:passedEnvironment
{
	id val = [passedEnvironment valueOfVariableNamed:name withScheme:[self scheme]];
	return val;
}

-(void)addToVariablesRead:(NSMutableSet*)variablesRead
{
	[variablesRead addObject:name];
}

-description
{
	return [NSString stringWithFormat:@"<%@:%x: scheme: %@ name: %@>",[self class],self,scheme,name];
}

-(void)dealloc
{
	[name release];
	[scheme release];
	[evaluationEnvironment release];
	[super dealloc];
}

-(void)generateObjectiveCOn:aStream
{
    [aStream generateVariableWithName:[self name]];
}

@end
