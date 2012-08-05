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

-(NSException*)handleException:exception target:target
{
    NSException *newException;
    NSMutableDictionary *newUserInfo=[NSMutableDictionary dictionaryWithCapacity:2];
    [newUserInfo addEntriesFromDictionary:[exception userInfo]];
    newException=[NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:newUserInfo];
    NSString *frameDescription=[NSString stringWithFormat:@"%@ >> %@",[target class],[self methodHeader]];
    [newException addScriptFrame: frameDescription];
    [newException addCombinedFrame:frameDescription previousTrace:[exception callStackSymbols]];
    NSLog(@"did add frame");
    NSLog(@"script stack trace: %@",[newException scriptStackTrace]);
    return newException;
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
        @throw [self handleException:exception target:target];
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

+_objectWithNestedMethodsThatThrow
{
	MPWStCompiler* compiler = [MPWStCompiler compiler];
	id a=[[NSObject new] autorelease];
	[compiler addScript:@"self bozobozozo." forClass:@"NSObject" methodHeaderString:@"xxxSimpleMethodThatRaises"];
	[compiler addScript:@"self xxxSimpleMethodThatRaises." forClass:@"NSObject" methodHeaderString:@"xxxSimpleMethodThatCallsMethodThatRaises"];
    return a;
}


+(void)testSimpleBacktrace
{
    id a = [self _objectWithNestedMethodsThatThrow];
    @try {
        [a xxxSimpleMethodThatRaises];
    } @catch (id exception) {
        id trace=[exception scriptStackTrace];
        IDEXPECT([trace lastObject], @"NSObject >> xxxSimpleMethodThatRaises", @"stack trace");
        return ;
    }
    EXPECTTRUE(NO, @"should have raised");
    
}

+(void)testNestedBacktrace
{
    id a = [self _objectWithNestedMethodsThatThrow];
    @try {
        [a xxxSimpleMethodThatCallsMethodThatRaises];
    } @catch (id exception) {
        id trace=[exception scriptStackTrace];
        INTEXPECT([trace count], 2, @"shoud have 2 elements in script trace");
        IDEXPECT([trace lastObject], @"NSObject >> xxxSimpleMethodThatCallsMethodThatRaises", @"stack trace");
        IDEXPECT([trace objectAtIndex:0], @"NSObject >> xxxSimpleMethodThatRaises", @"stack trace");
        return ;
    }
    EXPECTTRUE(NO, @"should have raised");
    
}

+(void)testCombinedScriptedAndNativeBacktrace
{
    id a = [self _objectWithNestedMethodsThatThrow];
    @try {
        [a xxxSimpleMethodThatCallsMethodThatRaises];
    } @catch (id exception) {
        id trace=[exception combinedStackTrace];
        
        IDEXPECT([trace objectAtIndex:4],@"4   Script                              ------------------  NSObject >> xxxSimpleMethodThatRaises", @"method that raises");
        IDEXPECT([trace objectAtIndex:14],@"14  Script                              ------------------  NSObject >> xxxSimpleMethodThatCallsMethodThatRaises", @"method that calls method that raises");
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
            @"testCombinedScriptedAndNativeBacktrace",
		nil];
}

@end


@implementation NSException(scriptStackTrace)

dictAccessor(NSMutableArray, scriptStackTrace, setScriptStackTrace, (NSMutableDictionary*)[self userInfo])

dictAccessor(NSMutableArray, combinedStackTrace, setCombinedStackTrace, (NSMutableDictionary*)[self userInfo])

-(void)cullTrace:(NSMutableArray*)trace withFrame:frame
{
    for (int i=0;i<[trace count]-3;i++) {
        int numLeft=[trace count]-i;
        NSString *cur=[trace objectAtIndex:i];
        if ( [cur rangeOfString:@"-[MPWScriptedMethod evaluateOnObject:parameters:]"].length>0) {
            NSString *formattedFrame=[NSString stringWithFormat:@"%-4dScript                              ------------------  %@",i,frame];
            
            [trace replaceObjectAtIndex:i withObject:formattedFrame];
            return ;
        }
        
    }
}

-(void)addCombinedFrame:(NSString*)frame previousTrace:previousTrace
{
    NSMutableArray *trace=[self combinedStackTrace];
    if (!trace) {
        trace=[[previousTrace mutableCopy] autorelease];
        [self setCombinedStackTrace:trace];
    }
    [self cullTrace:trace withFrame:frame];
}

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


