//
//  MPWScriptedMethod.m
//  Arch-S
//
//  Created by Marcel Weiher on 12/09/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWScriptedMethod.h"
#import "MPWEvaluator.h"
#import "STCompiler.h"
#import "MPWMethodHeader.h"
#import "MPWVarScheme.h"
#import "MPWSchemeScheme.h"

@interface NSObject(MethodServeraddException)

+(void)addException:(NSException*)newException;

@end


@implementation MPWScriptedMethod


objectAccessor(MPWExpression*, methodBody, setMethodBody )
objectAccessor(NSArray*, localVars, setLocalVars )
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
//            [[self context] resetSymbolTable];
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
//  FIXME!!
//  Linking with parent means we don't have local vars
//  (they are inherited from parent), not linking means
//  schemes are not inherited (and can't be modified)

//    NSLog(@"==== freshExecutionContextForRealLocalVars ===");

	MPWEvaluator *evaluator = [[[STCompiler alloc] initWithParent:nil] autorelease];
//    if ( self.classOfMethod == nil) {
//        [NSException raise:@"nilcontextclass" format:@"classOfMethod is nil in scripted method"];
//    }
    [evaluator setContextClass:self.classOfMethod];
//    NSLog(@"compiled-in schemes: %@",[[self compiledInExecutionContext] schemes]);
    MPWSchemeScheme *newSchemes=[[[self compiledInExecutionContext] schemes] copy];
    MPWVarScheme *newVarScheme=[MPWVarScheme store];
    [newVarScheme setContext:evaluator];
    [newSchemes setSchemeHandler:newVarScheme forSchemeName:@"var"];
    [newSchemes setSchemeHandler:newVarScheme forSchemeName:@"default"];
    [evaluator setSchemes:newSchemes];
    [newSchemes release];

    return evaluator;

 //   return [[[[self contextClass] alloc] initWithParent:[self compiledInExecutionContext]] autorelease];
}

-compiledInExecutionContext
{
	return [self context];
}

-executionContext
{
//    NSLog(@"executionContext");
	return [self freshExecutionContextForRealLocalVars];
}

-(NSException*)handleException:exception target:target
{
    NSLog(@"post-process exception: %@",exception);
    NSException *newException;
    NSMutableDictionary *newUserInfo=[NSMutableDictionary dictionaryWithCapacity:2];
    [newUserInfo addEntriesFromDictionary:[exception userInfo]];
    newException=[NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:newUserInfo];
    Class targetClass = [target class];
    int exceptionSourceOffset=[[[exception userInfo] objectForKey:@"offset"] intValue];
    NSString *frameDescription=[NSString stringWithFormat:@"%s[%@ %@] + %d",targetClass==target?"+":"-",targetClass,[self methodHeader],exceptionSourceOffset];
    [newException addScriptFrame: frameDescription];
    NSString *myselfInTrace=    @"-[MPWScriptedMethod evaluateOnObject:parameters:]";    
    NSLog(@"addCombinedFrame: %@",frameDescription);
    [newException addCombinedFrame:frameDescription frameToReplace:myselfInTrace previousTrace:[exception callStackSymbols]];
    NSLog(@"exception: %@/%@ in %@ with backtrace: %@",[exception name],[exception reason],frameDescription,[newException combinedStackTrace]);
    return newException;
}


-evaluateOnObject:target parameters:(NSArray*)parameters
{
	id returnVal=nil;
	MPWEvaluator* executionContext = [self executionContext];
    [executionContext bindValue:self toVariableNamed:@"self"];
    [[executionContext schemes] setSchemeHandler:[MPWPropertyStore storeWithObject:target] forSchemeName:@"this"];
    if ( ![[[self methodHeader] methodName] isEqual:@"schemeNames"]) {
        for ( NSString *schemeName in [target schemeNames]) {
            id <MPWStorage> store=[target valueForKey:schemeName];
            if ( store ) {
                [[executionContext schemes] setSchemeHandler:store forSchemeName:schemeName];
            }
        }
    }
//    NSLog(@"evalute scripted method %@",[self header]);
//    NSLog(@"methodBody %@",[self methodBody]);
	id compiledMethod = [self compiledScript];
//	NSLog(@"will evaluate scripted method %@ with context %p",[self methodHeader],executionContext);
    @autoreleasepool {

    @try {
	returnVal = [executionContext evaluateScript:compiledMethod onObject:target formalParameters:[self formalParameters] parameters:parameters];
    } @catch (id exception) {
//        NSLog(@"exception evaluating scripted method: %@",[self methodHeader]);
        id newException = [self handleException:exception target:target];
#if 1
        NSLog(@"exception: %@ at %@",newException,[newException combinedStackTrace]);
        Class c=NSClassFromString(@"MethodServer");
        [c addException:newException];
        NSLog(@"added exception to %@",c);
#else
        @throw newException;
#endif
    }
        [returnVal retain];
//	NSLog(@"did evaluate scripted method %@ with context %p",[self methodHeader],executionContext);
    }
	return [returnVal autorelease];
}

-(NSString *)stringValue
{
    return [NSString stringWithFormat:@"%@\n%@",
            [[self methodHeader] headerString],
            [self script] ? [[self script] stringValue] : [methodBody description]];
}

-description
{
    return [self stringValue];
}

//-(void)encodeWithCoder:aCoder
//{
//    id scriptData = [script dataUsingEncoding:NSUTF8StringEncoding];
//    [super encodeWithCoder:aCoder];
//    encodeVar( aCoder, scriptData );
//}
//
//-initWithCoder:aCoder
//{
//    id scriptData=nil;
//    self = [super initWithCoder:aCoder];
//    decodeVar( aCoder, scriptData );
//    [self setScript:[scriptData stringValue]];
//    [scriptData release];
//    return self;
//}

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
-xxxSimpleMethodThatRaises;
-xxxSimpleMethodThatCallsMethodThatRaises;
-getTheText;
-(void)setText:someText;
@end

@implementation NSObject(schemeNames)

-schemeNames { return @[]; }

@end


@implementation MPWScriptedMethod(testing)

+(void)testLookupOfNilVariableInMethodWorks
{
	STCompiler* compiler = [STCompiler compiler];
	id a=[[NSObject new] autorelease];
	id result;
	[compiler addScript:@"a:=nil. b:='2'. a isNil ifTrue:{ b:='335'. }. b." forClass:@"NSObject" methodHeaderString:@"xxxSimpleNilTestMethod"];
	result = [a xxxSimpleNilTestMethod];
	IDEXPECT( result, @"335", @"if nil is working");
}

+_objectWithNestedMethodsThatThrow
{
	STCompiler* compiler = [STCompiler compiler];
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
        IDEXPECT([trace lastObject], @"-[NSObject xxxSimpleMethodThatRaises] + 15", @"stack trace");
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
        IDEXPECT([trace lastObject], @"-[NSObject xxxSimpleMethodThatCallsMethodThatRaises] + 15", @"stack trace");
        IDEXPECT([trace objectAtIndex:0], @"-[NSObject xxxSimpleMethodThatRaises] + 15", @"stack trace");
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
        
        EXPECTTRUE([[trace objectAtIndex:4] rangeOfString:@"xxxSimpleMethodThatRaises"].length>0, @"method that raises present");
        EXPECTTRUE([[trace objectAtIndex:14] rangeOfString:@"xxxSimpleMethodThatCallsMethodThatRaises"].length>0,@"method that calls method that raises present");
        return ;
    }
    EXPECTTRUE(NO, @"should have raised");
}


+(void)testThisSchemeReadsObject
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"extension MPWScriptedMethod { -getTheText { this:script. } }." ];
    MPWScriptedMethod *tester=[MPWScriptedMethod new];
    tester.script=@"The Answer";
    NSString *result=[tester getTheText];
    IDEXPECT( result, @"The Answer",@"property via self: property-scheme");
}

+(void)testThisSchemeWritesObject
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"extension MPWScriptedMethod { -<void>setText:someText { this:script := someText. } }." ];
    MPWScriptedMethod *tester=[MPWScriptedMethod new];
    [tester setText:@"some script text"];
    IDEXPECT( [tester script] , @"some script text",@"property via self: property-scheme");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
            @"testLookupOfNilVariableInMethodWorks",
            @"testThisSchemeReadsObject",
            @"testThisSchemeWritesObject",
//            @"testSimpleBacktrace",                       // FIXME:  exceptions are currently swallowed
//            @"testNestedBacktrace",
//            @"testCombinedScriptedAndNativeBacktrace",
		nil];
}

@end


@implementation NSException(scriptStackTrace)

dictAccessor(NSMutableArray, scriptStackTrace, setScriptStackTrace, (NSMutableDictionary*)[self userInfo])

dictAccessor(NSMutableArray, combinedStackTrace, setCombinedStackTrace, (NSMutableDictionary*)[self userInfo])

-(void)cullTrace:(NSMutableArray*)trace replacingOriginal:original withFrame:frame
{
    for (int i=0;i<[trace count]-3;i++) {
//        int numLeft=[trace count]-i;
        NSString *cur=[trace objectAtIndex:i];
        if ( [cur rangeOfString:original].length>0) {
            NSString *address=nil;
#if TARGET_OS_IPHONE
            address=@"0x00000000";
#else
            address=@"0x0000000000000000";
#endif
            
            NSString *formattedFrame=[NSString stringWithFormat:@"%-4dScript                              %@  %@",i,address,frame];
            
            [trace replaceObjectAtIndex:i withObject:formattedFrame];
            return ;
        }
        
    }
}


-(void)addCombinedFrame:(NSString*)frame frameToReplace:original previousTrace:previousTrace
{
    NSLog(@"addCombinedTrace");
    NSMutableArray *trace=[self combinedStackTrace];
    if (!trace) {
        trace=[[previousTrace mutableCopy] autorelease];
        if (trace) {
            [self setCombinedStackTrace:trace];
        }
    }
    if (trace && original && frame) {
        [self cullTrace:trace replacingOriginal:original withFrame:frame];
    }
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

