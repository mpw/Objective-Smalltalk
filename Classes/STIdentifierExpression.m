//
//  MPWVariableExpression.m
//  Arch-S
//
//  Created by marcel on Mon Jul 02 2001.
//  Copyright (c) 2001 Marcel Weiher. All rights reserved.
//

#import "STIdentifierExpression.h"
#import "STEvaluator.h"
#import "MPWObjCGenerator.h"
#import "STIdentifier.h"

@implementation STIdentifierExpression

objectAccessor(STIdentifier*, identifier, setIdentifier )

-scheme
{
	return [[self identifier] schemeName];
}

-(BOOL)isSuper
{
    return [[self name] isEqual:@"super"];
}

-name
{
	return [[self identifier] identifierName];
}

-theLiteral
{
    return [self name];
}

-bindingWithContext:aContext
{
    return [[self identifier] bindingWithContext:aContext];
}

//-binding
//{
//    return [self bindingWithContext:[self evaluationEnvironment]];
//}
//

-evaluateIn:passedEnvironment
{
	//--- have identifier instead of name+scheme-string
	//--- pass to identifier...or pass to scheme..or pass to identifier which knows its sceme
	//---   var-identifier goes back to this
    id val=nil;
	//---   
	@try {
        val = [[self identifier] evaluateIn:passedEnvironment];
    } @catch (id exception) {
        @throw  [self handleOffsetsInException:exception];
    }
//	id val = [passedEnvironment valueOfVariableNamed:name withScheme:[self scheme]];
	return val;
}

-(void)addToVariablesRead:(NSMutableSet*)variablesRead
{
	[variablesRead addObject:[self identifier]];
}

-evaluateAssignmentOf:value in:aContext
{
    [aContext bindValue:value toVariableNamed:[[self identifier] evaluatedIdentifierNameInContext:aContext] withScheme:[self scheme]];
    return value;
    
}

-evaluatePostOf:value in:aContext
{
    NSString *variableName=[[self identifier] evaluatedIdentifierNameInContext:aContext];
    MPWScheme *scheme=[aContext schemeForName:[self scheme]];
    [scheme at:[scheme referenceForPath:variableName] post:value ];
    return value;
}

-description
{
	return [NSString stringWithFormat:@"<%@:%p: scheme: %@ name: %@>",[self class],self,[[self identifier] schemeName],[[self identifier] identifierName]];
}

-(void)dealloc
{
//	[name release];
//	[scheme release];
	[identifier release];
	[_evaluationEnvironment release];
	[super dealloc];
}

-(void)generateObjectiveCOn:aStream
{
    [aStream generateVariableWithName:[self name]];
}

@end


@implementation NSObject(isSuper)

-(BOOL)isSuper
{
    NSLog(@"isSuper sent to %@/%@, call-stack: %@",[self class],self,[NSThread callStackSymbols]);
    return NO;
}

@end
