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
	id returnVal=nil;
	id executionContext = [self executionContext];
	id compiledMethod = [self compiledScript];
//	NSLog(@"will evaluate scripted method %x with context %x",self,executionContext);
    
    @try {
	returnVal = [executionContext evaluateScript:compiledMethod onObject:target formalParameters:[self formalParameters] parameters:parameters];
    } @catch (id exception) {
        NSException *newException;
        NSMutableDictionary *newUserInfo=[NSMutableDictionary dictionaryWithCapacity:2];
        [newUserInfo addEntriesFromDictionary:[exception userInfo]];
        newException=[NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:newUserInfo];
        [newException addScriptFrame:[NSString stringWithFormat:@"%@ >> %@",[target class],[self methodHeader]] ];
        NSLog(@"did add frame");
        NSLog(@"script stack trace: %@",[newException scriptStackTrace]);
        @throw newException;
    }
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
	MPWStCompiler* compiler = [MPWStCompiler compiler];
	id a=[[NSObject new] autorelease];
	id result;
	[compiler addScript:@"a:=nil. b:='2'. a isNil ifTrue:[ b:='335']. b." forClass:@"NSObject" methodHeaderString:@"xxxSimpleNilTestMethod"];
	result = [a xxxSimpleNilTestMethod];
	IDEXPECT( result, @"335", @"if nil is working");
}

+(void)testSimpleBacktrace
{
	MPWStCompiler* compiler = [MPWStCompiler compiler];
	id a=[[NSObject new] autorelease];
	[compiler addScript:@"self bozobozozo." forClass:@"NSObject" methodHeaderString:@"xxxSimpleMethodThatRaises"];
    @try {
        [a xxxSimpleMethodThatRaises];
    } @catch (id exception) {
        NSLog(@"exception: %@",exception);
        id trace=[exception scriptStackTrace];
        IDEXPECT([trace lastObject], @"NSObject >> xxxSimpleMethodThatRaises", @"stack trace");
        return ;
    }
    EXPECTTRUE(NO, @"should have raised");
    
}

+(void)testNestedBacktrace
{
	MPWStCompiler* compiler = [MPWStCompiler compiler];
	id a=[[NSObject new] autorelease];
	[compiler addScript:@"self bozobozozo." forClass:@"NSObject" methodHeaderString:@"xxxSimpleMethodThatRaises"];
	[compiler addScript:@"self xxxSimpleMethodThatRaises." forClass:@"NSObject" methodHeaderString:@"xxxSimpleMethodThatCallsMethodThatRaises"];
    @try {
        [a xxxSimpleMethodThatCallsMethodThatRaises];
    } @catch (id exception) {
        NSLog(@"exception: %@",exception);
        id trace=[exception scriptStackTrace];
        INTEXPECT([trace count], 2, @"shoud have 2 elements in script trace");
        IDEXPECT([trace lastObject], @"NSObject >> xxxSimpleMethodThatCallsMethodThatRaises", @"stack trace");
        IDEXPECT([trace objectAtIndex:0], @"NSObject >> xxxSimpleMethodThatRaises", @"stack trace");
        return ;
    }
    EXPECTTRUE(NO, @"should have raised");
    
}

+testSelectors
{
	return [NSArray arrayWithObjects:
            @"testLookupOfNilVariableInMethodWorks",
            @"testSimpleBacktrace",
            @"testNestedBacktrace",
		nil];
}

@end


@implementation NSException(scriptStackTrace)

dictAccessor(NSArray, scriptStackTrace, setScriptStackTrace, [self userInfo])

-(void)addScriptFrame:(NSString*)frame
{
    NSMutableArray *trace=[self scriptStackTrace];
    if (!trace) {
        trace=[NSMutableArray array];
        [self setScriptStackTrace:trace];
    }
    [trace addObject:frame];
}

@end


