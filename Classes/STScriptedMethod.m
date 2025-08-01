//
//  STScriptedMethod.m
//  Arch-S
//
//  Created by Marcel Weiher on 12/09/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "STScriptedMethod.h"
#import "STEvaluator.h"
#import "STCompiler.h"
#import "MPWMethodHeader.h"
#import "MPWVarScheme.h"
#import "MPWSchemeScheme.h"
#import "MPWBlockExpression.h"
#import "STJittableData.h"

@interface NSObject(MethodServeraddException)

+(void)addException:(NSException*)newException;

@end


@implementation STScriptedMethod
{
    NSArray <MPWBlockExpression*>* blocks;
}


objectAccessor(STExpression*, methodBody, setMethodBody )
lazyAccessor(NSArray*, localVars, setLocalVars, computeLocalVars )
idAccessor( script, _setScript )
//idAccessor( _contextClass, setContextClass )

-(void)setScript:newScript
{
	[self setMethodBody:nil];
//    NSLog(@"setScript: '%@'",newScript);
	[self _setScript:newScript];
}

-computeLocalVars
{
    NSMutableArray *localVars=[NSMutableArray array];
    [self.methodBody accumulateLocalVars:localVars];
    return localVars;
}

-(NSArray <MPWBlockExpression*>*)findBlocks
{
    NSMutableArray *blocks=[NSMutableArray array];
    [self.methodBody accumulateBlocks:blocks];
    for ( MPWBlockExpression *block in blocks ) {
        block.method = self;
    }
    return blocks;
}

lazyAccessor( NSArray <MPWBlockExpression*>* , blocks, _setBlocks, findBlocks)


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
		localContextClass=[STEvaluator class];
	}
	return localContextClass;
}


-freshExecutionContextForRealLocalVars
{
//  FIXME!
//  Linking with parent means we don't have local vars
//  (they are inherited from parent), not linking means
//  schemes are not inherited (and can't be modified)

//    NSLog(@"==== freshExecutionContextForRealLocalVars ===");

	STEvaluator *evaluator = [[[STCompiler alloc] initWithParent:nil] autorelease];
    
    // HACK:  make stdout available to method if it is present in the
    //        context that defined the method.  This is a hard-coded
    //        version of dynamic scope / environment / context
    //        (see also:  https://openjdk.org/jeps/446 )
    
    
    id parentStdout = [context valueOfVariableNamed:@"stdout"];
    if ( parentStdout ) {
        [evaluator bindValue:parentStdout toVariableNamed:@"stdout"];
    }
    id parentStdline = [context valueOfVariableNamed:@"stdline"];
    if ( parentStdout ) {
        [evaluator bindValue:parentStdline toVariableNamed:@"stdline"];
    }
//    if ( self.classOfMethod == nil) {
//        [NSException raise:@"nilcontextclass" format:@"classOfMethod is nil in scripted method"];
//    }
    [evaluator setContextClass:self.classOfMethod];
//    NSLog(@"compiled-in schemes: %@",[[self compiledInExecutionContext] schemes]);
    MPWSchemeScheme *newSchemes=[[[self compiledInExecutionContext] schemes] copy];
    [newSchemes setSchemeHandler:newSchemes forSchemeName:@"scheme"];
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
    NSLog(@"post-process exception: %@ with raw trace: %@",exception,[exception callStackSymbols]);
    NSException *newException;
    NSMutableDictionary *newUserInfo=[NSMutableDictionary dictionaryWithCapacity:2];
    [newUserInfo addEntriesFromDictionary:[exception userInfo]];
    newException=[NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:newUserInfo];
    Class targetClass = [target class];
    int exceptionSourceOffset=[[[exception userInfo] objectForKey:@"offset"] intValue];
    NSString *frameDescription=[NSString stringWithFormat:@"%s[%@ %@] + %d",targetClass==target?"+":"-",targetClass,[self methodHeader],exceptionSourceOffset];
    [newException addScriptFrame: frameDescription];
    NSString *myselfInTrace=    @"-[STScriptedMethod evaluateOnObject:parameters:]";    
    NSLog(@"addCombinedFrame: %@",frameDescription);
    [newException addCombinedFrame:frameDescription frameToReplace:myselfInTrace previousTrace:[exception callStackSymbols]];
    NSLog(@"exception: %@/%@ in %@ with backtrace: %@",[exception name],[exception reason],frameDescription,[newException combinedStackTrace]);
    return newException;
}


-evaluateOnObject:target parameters:(NSArray*)parameters
{
    id returnVal=nil;
   @autoreleasepool {
    id compiledMethod = [self compiledScript];
	STEvaluator* executionContext = [self executionContext];
//    NSLog(@"compiledExecutionContext: %@ schemes: %@",[self compiledInExecutionContext],[[self compiledInExecutionContext] schemes]);
    [executionContext bindValue:self toVariableNamed:@"thisMethod"];
    [executionContext bindValue:self toVariableNamed:@"thisMethod"];
    [executionContext bindValue:executionContext toVariableNamed:@"thisContext"];
    [[executionContext schemes] setSchemeHandler:[MPWPropertyStore storeWithObject:target] forSchemeName:@"this"];
    if ( [target conformsToProtocol:@protocol(MPWStorage)]) {
           [[executionContext schemes] setSchemeHandler:target forSchemeName:@"self"];
       }
    if ( ![[[self methodHeader] methodName] isEqual:@"schemeNames"]) {
//        NSLog(@"for %@, getting schemeNames: %@",[[self methodHeader] methodName],[target schemeNames]);
        for ( NSString *schemeName in [target schemeNames]) {
//            NSLog(@"install: %@",schemeName);
            id <MPWStorage> store=[target valueForKey:schemeName];
//            NSLog(@"install scheme: %@ in executionContext %p schemes: %p",store,executionContext,[executionContext schemes]);
            if ( store ) {
                [[executionContext schemes] setSchemeHandler:store forSchemeName:schemeName];
            }
        }
    }
//    NSLog(@"context %p/%@ schemes: %@",executionContext,[executionContext class],[executionContext schemes]);
//    NSLog(@"evalute scripted method %@",[self header]);
//    NSLog(@"methodBody %@",[self methodBody]);
//	NSLog(@"will evaluate scripted method %@ with context %p",[self methodHeader],executionContext);
    @autoreleasepool {

    @try {
	returnVal = [executionContext evaluateScript:compiledMethod onObject:target formalParameters:[self formalParameters] parameters:parameters];
    } @catch (id exception) {
//        NSLog(@"exception evaluating scripted method: %@",[self methodHeader]);
        id newException = [self handleException:exception target:target];
        NSLog(@"exception: %@ at %@",newException,[newException combinedStackTrace]);
        Class c=NSClassFromString(@"MethodServer");
        [c addException:newException];
        NSLog(@"added exception to %@",c);
        @throw newException;
    }
        [returnVal retain];
//	NSLog(@"did evaluate scripted method %@ with context %p",[self methodHeader],executionContext);
    }
       [executionContext setSchemes:nil];           // manualy break cycle, fixes leak
                                                    // less than ideal... FIXME
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

-(void)installNativeCode
{
    NSAssert( _nativeCode != nil, @"must have native code to install it");
    NSAssert( _classOfMethod != nil , @"must have class to install into");
    NSAssert1(self.header.selector!=NULL , @"No selector for: %@", self);
    NSAssert1(self.header.typeSignature!=NULL , @"No type signature for: %@", NSStringFromSelector(self.header.selector));
    [_classOfMethod addMethod:self.nativeCode.bytes forSelector:self.header.selector types:self.header.typeSignature];
}

-(BOOL)isNativeCodeActive
{
    IMP theImp=[self.classOfMethod instanceMethodForSelector:[self.methodHeader selector]];
    return (theImp != nil) && (self.nativeCode.bytes != nil) && theImp == self.nativeCode.bytes;
}

-(void)dealloc
{
    [localVars release];
	[methodBody release];
	[script release];
    [_nativeCode release];
	[super dealloc];
}

@end

@interface STScriptedMethod(fakeTestingInterfaces)

-xxxSimpleNilTestMethod;
-xxxSimpleMethodThatRaises;
-xxxSimpleMethodThatCallsMethodThatRaises;
-getTheText;
-(void)setText:someText;
@end

@implementation NSObject(schemeNames)

-schemeNames { return @[]; }

@end

#import "STClassDefinition.h"

@implementation STScriptedMethod(testing)

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
    [compiler evaluateScriptString:@"extension STScriptedMethod { -getTheText { this:script. } }." ];
    STScriptedMethod *tester=[STScriptedMethod new];
    tester.script=@"The Answer";
    NSString *result=[tester getTheText];
    IDEXPECT( result, @"The Answer",@"property via self: property-scheme");
}

+(void)testThisSchemeWritesObject
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"extension STScriptedMethod { -<void>setText:someText { this:script := someText. } }." ];
    STScriptedMethod *tester=[STScriptedMethod new];
    [tester setText:@"some script text"];
    IDEXPECT( [tester script] , @"some script text",@"property via self: property-scheme");
}

+(void)testComputeLocalVars
{
    STCompiler *compiler=[STCompiler compiler];
    STClassDefinition *classDef = [compiler compile:@"class TestClass { -<void>setText:someText { var a. var b. 3. } }" ];
    STScriptedMethod *method=classDef.methods.firstObject;
    NSArray *localVarNames = [method localVars];
    INTEXPECT(localVarNames.count, 2, @"number of local vars");
}

+testSelectors
{
	return @[
#if !GNUSTEP
            @"testLookupOfNilVariableInMethodWorks",
#endif
            @"testThisSchemeReadsObject",
            @"testThisSchemeWritesObject",
            @"testComputeLocalVars",
//            @"testSimpleBacktrace",                       // FIXME:  exceptions are currently swallowed
//            @"testNestedBacktrace",
//            @"testCombinedScriptedAndNativeBacktrace",
		];
}

@end


@implementation NSException(scriptStackTrace)

dictAccessor(NSMutableArray*, scriptStackTrace, setScriptStackTrace, (NSMutableDictionary*)[self userInfo])

dictAccessor(NSMutableArray*, combinedStackTrace, setCombinedStackTrace, (NSMutableDictionary*)[self userInfo])

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

