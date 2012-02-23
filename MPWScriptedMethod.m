//
//  MPWScriptedMethod.m
//  MPWTalk
//
//  Created by Marcel Weiher on 12/09/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWScriptedMethod.h"
#import "MPWEvaluator.h"
#import "MPWStCompiler.h"

@implementation MPWScriptedMethod


objectAccessor( MPWExpression, methodBody, setMethodBody )
objectAccessor( NSArray, localVars, setLocalVars )
idAccessor( script, _setScript )
//idAccessor( _contextClass, setContextClass )

-(void)setScript:newScript
{
	[self setMethodBody:nil];
//    NSLog(@"setScript: '%@'",newScript);
	[self _setScript:newScript];
}


-compiledScript
{
	if ( ![self methodBody] ) {
		if ( [self context] ) {
			[self setMethodBody:[[self script] compileIn:[self context]]];
		} else {
			[self setMethodBody:[self script]];
		}
	}
	return [self methodBody];
}

-contextClass
{
	id localContextClass=[[self context] class];
	if ( !localContextClass) {
		localContextClass=[MPWEvaluator class];
	}
	return localContextClass;
}


-freshExecutionContextForRealLocalVars
{
//	NSLog(@"creating new context from context: %@",[self context]);
	return [[[[self contextClass] alloc] initWithParent:[self context]] autorelease];
}

-compiledInExecutionContext
{
	return [self context];
}

-executionContext
{
	return [self freshExecutionContextForRealLocalVars];
}

-evaluateOnObject:target parameters:parameters
{
	id returnVal;
	id executionContext = [self executionContext];
	id compiledMethod = [self compiledScript];
//	NSLog(@"will evaluate scripted method %x with context %x",self,executionContext);
	returnVal = [executionContext evaluateScript:compiledMethod onObject:target formalParameters:[self formalParameters] parameters:parameters];
//	NSLog(@"did evaluate scripted method %x with context %x",self,executionContext);
	return returnVal;
}

-(NSString *)stringValue
{
    return [NSString stringWithFormat:@"%@\n%@",
            [[self methodHeader] headerString],
            [[self script] stringValue]];
}

-(void)encodeWithCoder:aCoder
{
	id scriptData = [script dataUsingEncoding:NSUTF8StringEncoding];
	[super encodeWithCoder:aCoder];
	encodeVar( aCoder, scriptData );
}

-initWithCoder:aCoder
{
	id scriptData=nil;
	self = [super initWithCoder:aCoder];
	decodeVar( aCoder, scriptData );
	[self setScript:[scriptData stringValue]];
	[scriptData release];
	return self;
}

-(void)dealloc 
{
	[localVars release];
	[methodBody release];
	[script release];
	[super dealloc];
}

@end

@interface MPWScriptedMethod(fakeTestingInterfaces)

-xxxSimpleNilTestMethod;

@end


@implementation MPWScriptedMethod(testing)

+(void)testLookupOfNilVariableInMethodWorks
{
	MPWStCompiler* compiler = [[[MPWStCompiler alloc] init] autorelease];
	id a=[[NSObject new] autorelease];
	id result;
	[compiler addScript:@"a:=nil. b:='2'. a isNil ifTrue:[ b:='1']. b." forClass:@"NSObject" methodHeaderString:@"xxxSimpleNilTestMethod"];
	result = [a xxxSimpleNilTestMethod];
	IDEXPECT( result, @"1", @"if nil is working");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
//		@"testLookupOfNilVariableInMethodWorks",
		nil];
}

@end
