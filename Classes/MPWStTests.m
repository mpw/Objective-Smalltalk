//
//  MPWStTests.m
//  MPWTalk
//
//  Created by Marcel Weiher on 14/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWStTests.h"
#import <ObjectiveSmalltalk/MPWExpression.h>
#import <ObjectiveSmalltalk/MPWAssignmentExpression.h>
#import <ObjectiveSmalltalk/MPWIdentifierExpression.h>
#import <ObjectiveSmalltalk/MPWAbstractInterpretedMethod.h>
#import "MPWMethodHeader.h"
#import "MPWInstanceVariable.h"
#import "NSObjectScripting.h"
#import "MPWIdentifierExpression.h"
#import <objc/runtime.h>
#import "MPWObjCGenerator.h"
#import <MPWFoundation/NSNil.h>
#import "MPWIdentifier.h"
#import "MPWScriptedMethod.h"
#import "MPWMethodHeader.h"
#import "MPWBlockExpression.h"
#import "MPWStatementList.h"
#import "MPWMessageExpression.h"
#import "MPWClassDefinition.h"
#import "MPWPropertyPathDefinition.h"
#import "MPWPropertyPath.h"

@interface NSString(methodsDynamicallyAddedDuringTesting)

-lengthMultipliedBy:aNumber;
-lengthMultipliedByInt:(int)anInt;
-lengthMultipliedBySomeIntTimes2:(int)anInt;
-(int)intLengthMultipliedByInt:(int)anInt;
-(int)lengthMultipliedByIntExternal:(int)anInt;
-variable1;
-setVariable1:newValue;
+(int)theAnswer;

@end


@protocol MessagesDefinedBySTinMPWStTestss
-dummy3;
-multiplyByNumber:aNumber;

@end

@implementation MPWStTests

#define TESTEXPR( expr, expected )\
{\
    id result=nil;\
    id expectedString;\
    @try { \
        result = (MPWExpression*)[self evaluate:expr];\
        result = [result stringValue];\
        expectedString=[expected stringValue];\
    } @catch (NSException *e) {\
        NSAssert3( 0, @"evaluating '%@' and expecting '%@' raised %@",expr,expectedString,e);\
    }\
    NSAssert3( result==expectedString || [result isEqual:expectedString], @"%@ doesn't evaluate to '%@' but to actual '%@'",expr,expected,result);\
}\


+(void)testexpr:expr expected:expected
{
	id result=nil;
	NS_DURING
    result = (MPWExpression*)[self evaluate:expr];
    result = [result stringValue];
    expected=[expected stringValue];
	NS_HANDLER
		NSAssert3( 0, @"evaluating '%@' and expecting '%@' raised %@",expr,expected,localException);
	NS_ENDHANDLER
    NSAssert3( result==expected || [result isEqual:expected], @"%@ doesn't evaluate to expected '%@' but to actual '%@'",expr,expected,result);
}




+(void)testThreePlusFour
{
    TESTEXPR(@"3+4",@"7");
//    [self testexpr:@"3+4" expected:@"7"];
}

+(void)testSevenMinus4
{
    [self testexpr:@"7-4" expected:@"3"];
}

+(void)stringConcat
{
    [self testexpr:@"'Hi ' stringByAppendingString:'there'." expected:@"Hi there"];
}

+(void)nestedArgStringConcat
{
    [self testexpr:@"'Hi ' stringByAppendingString:'there' uppercaseString." expected:@"Hi THERE"];
}

+(void)nestedReceiverStringConcat
{
    [self testexpr:@"'Hi 'uppercaseString stringByAppendingString:'there'." expected:@"HI there"];
}

+(void)stackedMappedConcat
{
    [self testexpr:@"'hi ' , 'there ' , 'to' uppercaseString" expected:@"hi there TO"];
}

+(void)mixedStackedMappedConcat
{
    [self testexpr:@"'hi ' uppercaseString , 'there ' , 'to' uppercaseString" expected:@"HI there TO"];
}

+(void)simpleLiteral
{
    [self testexpr:@"'Hi'" expected:@"Hi"];
}

+(void)arrayLiteral
{
    TESTEXPR(@"#(1, 2, 3)" , (@[@(1),@(2),@(3)]));
}

+(void)testSimpleLiteralDict
{
    TESTEXPR(@"#{ 'key': 'value' }" , (@{ @"key": @"value"}) );
}

+(void)testLiteralDictWithNumberKey
{
    TESTEXPR(@"#{ 1 : 'value' }" , (@{ @(1) : @"value"}) );
}

+(void)testTwoElementLiteralDict
{
    TESTEXPR(@"#{ 'key': 'value', 'hello': 'world' }" , (@{ @"key": @"value", @"hello": @"world"}));
}

+(void)collectArrayLiteral
{
    TESTEXPR(@"#(1, 2, 3) collect + 3" ,([NSMutableArray arrayWithObjects:@"4",@"5",@"6",nil]));
}

+(void)collectTwoArrayLiterals
{
    [self testexpr:@"#(1, 2, 3) collect + #(1, 2, 3) each" expected:[NSMutableArray arrayWithObjects:@"2",@"4",@"6",nil]];
}

+(void)testLocalVariables
{
	id a = @"hello world!";
	id expr = @"a uppercaseString.";
	id expected = @"HELLO WORLD!";
	id evaluator = [[[self alloc] init] autorelease];
	id result;
	[evaluator bindValue:a toVariableNamed:@"a"];
	result = [(MPWExpression*)[evaluator evaluateScriptString:expr] stringValue];
    NSAssert3( [result isEqual:expected], @"%@ doesn't evaluate to '%@' but to '%@'",expr,expected,result);
	
}

+(void)testAssignment
{
	id expr = @"a:='hello world'";
	id evaluator = [[[self alloc] init] autorelease];
	[evaluator evaluateScriptString:expr];
	IDEXPECT( [evaluator valueOfVariableNamed:@"a"], @"hello world", @"after assignment");
}

+(void)testFloatArithmetic
{
    [self testexpr:@"(3.2+4.4*10) intValue" expected:@"76"];
}

+(void)testAsFloat
{
    [self testexpr:@"3 floatValue / 2" expected:@"1.5"];
}

+(void)testUnknownSelector
{
	NSString *expr=@"3 a";
	id evaluator = [[[self alloc] init] autorelease];
	@try {
		[evaluator evaluateScriptString:expr];
		EXPECTTRUE( NO, @"expected exception" );
	}
	@catch (NSException * e) {
		// ok
	}
}

+(void)testNil
{
    [self testexpr:@"nil" expected:nil];
}


+(void)testAssignNil
{
	id expr1 = @"a:=3";
	id expr2 = @"a:=nil";
	id evaluator = [[[self alloc] init] autorelease];
	[evaluator evaluateScriptString:expr1];
	IDEXPECT( [evaluator valueOfVariableNamed:@"a"], [NSNumber numberWithInt:3], @"before nil assignment");
	[evaluator evaluateScriptString:expr2];
	IDEXPECT( [evaluator valueOfVariableNamed:@"a"], (id)nil, @"after nil assignment");
}

+(void)testMultipleStatments
{
    [self testexpr:@"a:=3. b:=4. a+b" expected:[NSNumber numberWithInt:7]];
}

+(void)testIfTrueIfFalse
{
    [self testexpr:@"true ifTrue: [ 3 ] ifFalse: [ 4 ]." expected:[NSNumber numberWithInt:3]];
}

+(void)testIfTrueIfFalseWithExpressionValue
{
    [self testexpr:@"true ifTrue: [ 3+4 ] ifFalse: [ 4 ]." expected:[NSNumber numberWithInt:7]];
}

+(void)testIfTrueIfFalseWithExpressionCondition
{
    [self testexpr:@"('hello world' hasPrefix:'hello') ifTrue: [ 3+4 ] ifFalse: [ 4 ]." expected:[NSNumber numberWithInt:7]];
}

+(void)testBasicWhileTrue
{
    [self testexpr:@"a:=2.[a<100] whileTrue:[a:=(2*a)]. a." expected:[NSNumber numberWithInt:128]];
}

+(void)testWhileTrueWithLongerBlock
{
    [self testexpr:@"a:=2.b:=1. [a<100] whileTrue:[a:=(2*a). b:=(b+1)]. b." expected:[NSNumber numberWithInt:7]];
}

+(void)testForLoop
{
    [self testexpr:@"a:=2. (1 to:10) do:[ :i | a:=(2*a).]. a." expected:[NSNumber numberWithInt:2048]];
}

+(void)testRecursiveInterpret
{
    [self testexpr:@"context evaluateScriptString:'3+4'" expected:[NSNumber numberWithInt:7]];
}

+(void)testScriptOnObjectKnowsSelf
{
	NSString *base=@"abcd";
	int result;
	result = [[base evaluateScript:@"self length."] intValue];
	INTEXPECT( result, 4, @"didn't get the string length expected" )
}

+(void)testAddingMethodToClass
{
	id evaluator=[[[self alloc] init] autorelease];
	int result;
	NSString* methodName=@"lengthTimes2";
	NSString* className=@"NSString";
	[evaluator addScript:@"self length*2." forClass:className methodHeaderString:methodName];
//	NSLog(@"will do evaluate with lengthTimes2");
	result = [[evaluator evaluateScriptString:@"'abcd' lengthTimes2."] intValue];
//	NSLog(@"did evaluate with lengthTimes2");
	INTEXPECT( result, 8, @"didn't get the string length expected" );
	result = [[evaluator evaluateScriptString:@"'tenletters' lengthTimes2."] intValue];
	INTEXPECT( result,20, @"didn't get the string length expected" )
}

+(void)testScriptWithParameters
{
	id evaluator=[[[self alloc] init] autorelease];
	int result;
	id scriptMul=@"a * b";
	id scriptAdd=@"a + b";
	id formalParametrList=[NSArray arrayWithObjects:@"a",@"b",nil];
	id actualParameters1 = [NSArray arrayWithObjects:[NSNumber numberWithInt:3],[NSNumber numberWithInt:4],nil];
	id actualParameters2 = [NSArray arrayWithObjects:[NSNumber numberWithInt:5],[NSNumber numberWithInt:7],nil];
	
	//	NSLog(@"will do evaluate with lengthTimes2");
	result = [[evaluator evaluate:scriptMul withFormalParameterList:formalParametrList actualParameters:actualParameters1] intValue];
	INTEXPECT( result,12 , @"didn't get first mul result expected" );
	result = [[evaluator evaluate:scriptMul withFormalParameterList:formalParametrList actualParameters:actualParameters2] intValue];
	INTEXPECT( result, 35 , @"didn't get second mul result expected" );
	result = [[evaluator evaluate:scriptAdd withFormalParameterList:formalParametrList actualParameters:actualParameters1] intValue];
	INTEXPECT( result, 7 , @"didn't get first add result expected" );
	result = [[evaluator evaluate:scriptAdd withFormalParameterList:formalParametrList actualParameters:actualParameters2] intValue];
	INTEXPECT( result, 12 , @"didn't get second add result expected" );
}

+(void)testMethodWithParameters
{
	id evaluator=[self compiler];
	int result;
	NSString* methodName=@"lengthMultipliedBy:a";
	NSString* className=@"NSString";
	[evaluator addScript:@"self length*a." forClass:className methodHeaderString:methodName];
	//	NSLog(@"will do evaluate with lengthTimes2");
	id arg = [NSNumber numberWithInt:2];
	id objresult = [@"abcd" lengthMultipliedBy:arg];
	result = [objresult intValue];
//		[[evaluator evaluateScriptString:@"'abcd' lengthTimes:2."] intValue];
	//	NSLog(@"did evaluate with lengthTimes2");
	INTEXPECT( result, 8, @"didn't get the string length expected" );
	result = [[@"tenletters" lengthMultipliedBy:[NSNumber numberWithInt:3]] intValue];
//	result = [[evaluator evaluateScriptString:@"'tenletters' lengthTimes:3."] intValue];
	INTEXPECT( result,30, @"didn't get the string length expected" );
}


+(void)testParseMethodSyntaxOneArg
{
    NSString *methodText=@"-lengthMultipliedBy:a  { self length * a. }";
    id compiler=[self compiler];
    MPWScriptedMethod *method=[compiler parseMethodDefinition:methodText];
    MPWMethodHeader *header=[method header];
    
    IDEXPECT( [header methodName], @"lengthMultipliedBy:", @"method name");
    INTEXPECT( [header numArguments], 1, @"number of args");
    IDEXPECT( [header argumentNameAtIndex:0], @"a", @"first arg");
    IDEXPECT( [header typeString], @"@@:@", @"type string");
    IDEXPECT( [header argumentTypeAtIndex:0], @"id", @"arg type");
    
}

+(void)testParseMethodSyntaxNoArgs
{
    NSString *methodText=@"-lengthMultipliedBy5  { self length * 5. }";
    id compiler=[self compiler];
    MPWScriptedMethod *method=[compiler parseMethodDefinition:methodText];
    MPWMethodHeader *header=[method header];
    
    IDEXPECT( [header methodName], @"lengthMultipliedBy5", @"method name");
    INTEXPECT( [header numArguments], 0, @"number of args");
    IDEXPECT( [header typeString], @"@@:", @"type string");
    IDEXPECT( [header returnTypeName], @"id", @"return type");
    EXPECTTRUE([[method methodBody] isKindOfClass:[MPWStatementList class]], @"body is a statement list.");
    MPWStatementList *statements=(MPWStatementList*)[method methodBody];
    INTEXPECT([[statements statements] count],1,@"number of statements");
    MPWMessageExpression *first=[[statements statements] firstObject];
    EXPECTTRUE([first isKindOfClass:[MPWMessageExpression class]], @"should be a message expression");
}

+(void)testNegativeLiteralComputation
{
    [self testexpr:@"context evaluateScriptString:4*-2" expected:[NSNumber numberWithInt:-8]];
}
+(void)testNegativeLiteral
{
    [self testexpr:@"-2" expected:[NSNumber numberWithInt:-2]];
}
+(void)testSelectHOM
{
    [self testexpr:@" #( 'Help', 'Hello World', 'Hello Marcel') select hasPrefix:'Hello' " expected:[NSArray arrayWithObjects:@"Hello World",@"Hello Marcel",nil]];
}

+(void)testNSRangeViaSubarray
{
    [self testexpr:@" #( 'Help' , 'Hello World', 'Hello Marcel') subarrayWithRange:( 1 to: 2) " expected:[NSArray arrayWithObjects:@"Hello World",@"Hello Marcel",nil]];
}

+(void)testNSPointViaString
{
    [self testexpr:@" '{1,2}' point " expected:[MPWPoint pointWithX:1 y:2]];
}

+(void)testNSSizeViaString
{
    [self testexpr:@" '{1,2}' asSize " expected:[MPWPoint pointWithX:1 y:2]];
}

+(void)testAddMethodWithIntArg
{
	id evaluator=[[[self alloc] init] autorelease];
	int result;
	NSString* methodName=@"lengthMultipliedByInt:<int>a";
	NSString* className=@"NSString";
	[evaluator addScript:@"self length*a." forClass:className methodHeaderString:methodName];
	//	NSLog(@"will do evaluate with lengthTimes2");
	result = [[@"abcd" lengthMultipliedByInt:2] intValue];
	//		[[evaluator evaluate:@"'abcd' lengthTimes:2."] intValue];
	//	NSLog(@"did evaluate with lengthTimes2");
	INTEXPECT( result, 8, @"didn't get the string length expected" );
	result = [[@"tenletters" lengthMultipliedByInt:3] intValue];
	//	result = [[evaluator evaluate:@"'tenletters' lengthTimes:3."] intValue];
	INTEXPECT( result,30, @"didn't get the string length expected" );
		
}
+(void)testAddMethodWithIntArgAndReturn
{
	id evaluator=[[[self alloc] init] autorelease];
	int result;
	NSString* methodName=@"<int>intLengthMultipliedByInt:<int>a";
	NSString* className=@"NSString";
	[evaluator addScript:@"self length*a." forClass:className methodHeaderString:methodName];
	//	NSLog(@"will do evaluate with lengthTimes2");
	result = [@"abcd" intLengthMultipliedByInt:2];
	//		[[evaluator evaluate:@"'abcd' lengthTimes:2."] intValue];
	//	NSLog(@"did evaluate with lengthTimes2");
	INTEXPECT( result, 8, @"didn't get the string length expected" );
	result = [@"tenletters" intLengthMultipliedByInt:3];
	//	result = [[evaluator evaluate:@"'tenletters' lengthTimes:3."] intValue];
	INTEXPECT( result,30, @"didn't get the string length expected" );
		
}


+(void)testRedefiningMethod
{
	id evaluator=[[[self alloc] init] autorelease];
	int result;
	NSString* className=@"NSString";
	[evaluator addScript:@"self length*a." forClass:className methodHeaderString:@"lengthMultipliedBySomeIntTimes2:<int>a"];
	result = [[@"abcd" lengthMultipliedBySomeIntTimes2:2] intValue];
	INTEXPECT( result, 8, @"didn't get the string length expected" );
	[evaluator addScript:@"self length*a*2." forClass:className methodHeaderString:@"lengthMultipliedBySomeIntTimes2:<int>a"];
	result = [[@"abcd" lengthMultipliedBySomeIntTimes2:2] intValue];
	INTEXPECT( result, 16, @"didn't get the string length expected" );
}

+(void)testAddMethodWithIntArgViaMethodHeader
{
	id evaluator=[[[self alloc] init] autorelease];
	int result;
	NSString* className=@"NSString";
	[evaluator addScript:@"self length*a." forClass:className methodHeaderString:@"lengthMultipliedByInt:<int>a"];
	result = [[@"abcd" lengthMultipliedByInt:2] intValue];
	INTEXPECT( result, 8, @"didn't get the string length expected" );
}

+(void)testAllClassesWithScripts
{
	id evaluator=[[[self alloc] init] autorelease];
	INTEXPECT( [[evaluator classesWithScripts] count], 0 , @"haven't defined any classes with scripts yet");
	[evaluator addScript:@"self length*a." forClass:@"NSString" methodHeaderString:@"lengthMultipliedByInt:<int>a"];
	INTEXPECT( [[evaluator classesWithScripts] count], 1 , @"number of classes with scripts");
	IDEXPECT( [[evaluator classesWithScripts] lastObject], @"NSString" , @"class with script");
}


+(void)testScriptNamesForClass
{
	id evaluator=[[[self alloc] init] autorelease];
	[evaluator addScript:@"self length*a." forClass:@"NSString" methodHeaderString:@"lengthMultipliedByInt:<int>a"];
//	id methodNames = [evaluator methodNamesForClassName:@"NSString"];
	
	INTEXPECT( [[evaluator methodNamesForClassName:@"NSString"] count], 1 , @"number of methods in NSString");
	IDEXPECT( [[evaluator methodNamesForClassName:@"NSString"] lastObject], @"lengthMultipliedByInt:" , @"method defined on NSString");
}

+(void)testExternalDictForDefinedMethods
{
	NSString *originalMethodHeader = @"lengthMultipliedByInt:<int>a";
	NSString *originalScript = @"self length*a.";
	NSDictionary *externalDict;
	NSDictionary *methodDict;
	NSString *externalizedMethodHeader;
	id evaluator=[[[self alloc] init] autorelease];
	[evaluator addScript:originalScript forClass:@"NSString" methodHeaderString:originalMethodHeader];
	externalDict = [evaluator externalScriptDict];
	INTEXPECT( [externalDict count] , 1 , @"one class in external script dict" );
	methodDict = [[externalDict objectForKey:@"NSString"] objectForKey:@"instanceMethods"];
	INTEXPECT( [methodDict count] , 1 , @"one method in external script dict" );
	externalizedMethodHeader= [[methodDict allKeys] lastObject];
	IDEXPECT( externalizedMethodHeader , originalMethodHeader , @"externalized method header" );
	IDEXPECT( [methodDict objectForKey:externalizedMethodHeader] , originalScript, @"externalized method body" );
}

//+(void)testDefinedMethodsForExternalDict   // disabled
//{
//    id evaluator=[[[self alloc] init] autorelease];
//    id externalDictString = @"{ NSString = { \"<int>lengthMultipliedByIntExternal:<int>a\" = \"self length*a.\"; }; }";
//    NSDictionary *externalDict=[externalDictString propertyList];
//    INTEXPECT( [[evaluator classesWithScripts] count], 0 , @"before defining external script dict" );
//    [evaluator defineMethodsInExternalDict:externalDict];
//    INTEXPECT( [[evaluator classesWithScripts] count], 1 , @"after defining external script dict" );
//    IDEXPECT( [[evaluator classesWithScripts] lastObject], @"NSString" , @"class with scripts" );
//    INTEXPECT( [[evaluator methodDictionaryForClassNamed:@"NSString" ] count], 1 , @"1 method defined" );
//    IDEXPECT( [[[evaluator methodForClass:@"NSString" name:@"lengthMultipliedByIntExternal:"] header] headerString], @"<int>lengthMultipliedByIntExternal:<int>a" , @"defined method header" );
//    INTEXPECT( [@"someString" lengthMultipliedByIntExternal:3], 30, @"method actually defined and usable" );
//
//}

+(void)testDefineMethodInUnknownClassDoesntCrash
{
	id evaluator=[[[self alloc] init] autorelease];
	[evaluator addScript:@"3." forClass:@"__ClassThatHopefullyDoesntExist" methodHeaderString:@"<int>count"];
}

+(void)testRespondsToSelectorWorksFromScript
{
    [self testexpr:@"NSObject new respondsToSelector:'class'." expected:@"1"];
	NS_DURING
    [self testexpr:@"NSObject new respondsToSelector:'_bozo_hopefully_not_defined'." expected:@"0"];
	NSAssert( 0, @"testRespondsToSelectorWorksFromScript should have raised an error");
	NS_HANDLER
//		NSLog(@"got an error?");
	NS_ENDHANDLER
}

-(void)_checkExpectedVariablesRead:(NSArray*)readVars written:(NSArray*)writtenVars inExpression:expr
{
	id expr1 = [self compile:expr];
	id readMsg=[NSString stringWithFormat:@"variables read in '%@'",expr];
	id writeMsg=[NSString stringWithFormat:@"variables written in '%@'",expr];
	IDEXPECT( [expr1 variableNamesRead], [NSSet setWithArray:readVars],readMsg);
	IDEXPECT( [expr1 variableNamesWritten] , [NSSet setWithArray:writtenVars]  ,writeMsg);
}

+(void)testVariableDataFlowAnalysis
{
	id evaluator=[[[self alloc] init] autorelease];
	[evaluator _checkExpectedVariablesRead:[NSArray arrayWithObject:@"a"] 
								   written:[NSArray array]
							  inExpression:@"a"];
	[evaluator _checkExpectedVariablesRead:[NSArray array] 
								   written:[NSArray arrayWithObject:@"a"]
							  inExpression:@"a:=0"];
	[evaluator _checkExpectedVariablesRead:[NSArray arrayWithObject:@"b"] 
								   written:[NSArray arrayWithObject:@"a"]
							  inExpression:@"a:=b"];
	[evaluator _checkExpectedVariablesRead:[NSArray arrayWithObjects:@"b",@"c",nil] 
								   written:[NSArray arrayWithObject:@"a"]
							  inExpression:@"a:=(b + c)"];
	[evaluator _checkExpectedVariablesRead:[NSArray arrayWithObjects:@"b",@"c",nil] 
								   written:[NSArray arrayWithObject:@"a"]
							  inExpression:@"a:=(c + b)"];
	[evaluator _checkExpectedVariablesRead:[NSArray arrayWithObjects:@"b",@"c",@"d",@"a",nil] 
								   written:[NSArray arrayWithObjects:@"a",@"b",nil]
							  inExpression:@"a:=(c + b). b:=(d - a)."];
	[evaluator _checkExpectedVariablesRead:[NSArray arrayWithObjects:@"b",nil] 
								   written:[NSArray arrayWithObjects:@"a",nil]
							  inExpression:@"(1 to:10) do:[a:=b]. "];
	
}

+(void)testCreateSubclass
{
    NSString *className = @"__TempCreatedTestClass";
    Class aClass = NSClassFromString( className );
    IDEXPECT( aClass, nil, @"class shouldn't exist yet");
    [NSString createSubclassWithName:className];
    aClass = NSClassFromString( className );
    IDEXPECT( NSStringFromClass(aClass), className, @"class should exist and be named as expected");
}

+(void)testCreateSubclassWithInstanceVariables
{
    NSString *className = @"__TempCreatedTestClassWithIVars";
    Class aClass = NSClassFromString( className );
	id variableDescriptions;
    IDEXPECT( aClass, nil, @"class shouldn't exist yet");
    [NSString createSubclassWithName:className instanceVariables:@"variable1 variable2"];
    aClass = NSClassFromString( className );
    IDEXPECT( NSStringFromClass(aClass), className, @"class should exist and be named as expected");
//    INTEXPECT(  aClass->instance_size, [NSString class]->instance_size+2 * sizeof(id), @"new class should have space for 2 id variables");
	variableDescriptions = [aClass instanceVariables];
	INTEXPECT( [variableDescriptions count], 3, @"number of instance variables" );
	INTEXPECT( [[variableDescriptions objectAtIndex:0] offset], 0, @"offset of isa" );
	INTEXPECT( [[variableDescriptions objectAtIndex:1] offset],sizeof(id), @"offset of first new var" );
	INTEXPECT( [[variableDescriptions objectAtIndex:2] offset], sizeof(id)*2, @"offset of first new var" );
	IDEXPECT( [[variableDescriptions objectAtIndex:0] name], @"isa", @"isa varname" );
	IDEXPECT( [[variableDescriptions objectAtIndex:1] name], @"variable1", @"first varname" );
	IDEXPECT( [[variableDescriptions objectAtIndex:2] name], @"variable2", @"2nd varname" );
//	IDEXPECT( [[variableDescriptions objectAtIndex:0] type], @"@", @"isa type" );   '#' under Leopard, '@' under Tiger?
	IDEXPECT( [[variableDescriptions objectAtIndex:1] type], @"@", @"1st type" );
	IDEXPECT( [[variableDescriptions objectAtIndex:2] type], @"@", @"2nd type" );
}

+(void)testAccessingInstanceVariablesOfCreatedClass
{
    NSString *className = @"__AnotherTempCreatedTestClassWithIVars";
	id variableDescription;
	id testValue = @"someTestValue";
	id testValue2 = @"anotherTestValue";
	id variableName = @"variable1";
	id instance;
	Class aClass;
    [NSString createSubclassWithName:className instanceVariables:variableName];
    aClass = NSClassFromString( className );
	variableDescription = [[aClass instanceVariables] lastObject];
	instance = [[aClass new] autorelease];
	IDEXPECT( [instance valueForKey:variableName], nil, @"initial state of instance variable");
	[instance setValue:testValue forKey:variableName];
	IDEXPECT( [instance valueForKey:variableName], testValue, @"after KVC setting instance variable");
	[variableDescription setValue:testValue2 inContext:instance];
	IDEXPECT( [instance valueForKey:variableName], testValue2, @"after setting via variable");
//	NSLog(@"did get valueForKey:");
	IDEXPECT( [variableDescription valueInContext:instance], testValue2, @"getting via variable");
//	NSLog(@"did get via valueInContext:");
	[aClass generateAccessorsFor:variableName];
//	NSLog(@"will get via message send");
	IDEXPECT( [instance variable1], testValue2, @"getting variable via direct accessor");
//	NSLog(@"did get via message send, will set via message send");
	[instance setVariable1:testValue];
//	NSLog(@"did set via message send");
	IDEXPECT( [instance variable1], testValue, @"after setting via direct accessor");
}	

+(void)testParseSubclassWithInstanceVariablesUsingSyntax
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    MPWClassDefinition *classDef=[compiler parseClassDefinitionFromString:@"class __TestClassWithIVarsFromSyntax { var myIvar.  var ivar2. } "];
    
    MPWInstanceVariable *variableDescription = [[classDef instanceVariableDescriptions] firstObject];
    //    INTEXPECT( [variableDescription offset], sizeof(id), @"offset of variable" );
    IDEXPECT( [variableDescription name], @"myIvar", @"name of ivar" );
    IDEXPECT( [variableDescription type], @"id", @"type of ivar" );
    MPWInstanceVariable *ivar2 = [[classDef instanceVariableDescriptions] lastObject];
    //    INTEXPECT( [variableDescription offset], sizeof(id), @"offset of variable" );
    IDEXPECT( [ivar2 name], @"ivar2", @"name of ivar" );
    IDEXPECT( [ivar2 type], @"id", @"type of ivar" );
}

+(void)testCreateSubclassWithInstanceVariablesUsingSyntax
{
    id a=[self evaluate:@"class __TestClassWithIVarsFromSyntax { var myIvar.  var ivar2. } "];
    NSLog(@"a=%@",a);
    Class aClass = NSClassFromString( @"__TestClassWithIVarsFromSyntax" );
    EXPECTNOTNIL(aClass, @"defined the class");
    NSArray <MPWInstanceVariable*>* variableDescriptions = [aClass instanceVariables];
    MPWInstanceVariable *variableDescription = variableDescriptions[1];
    //    INTEXPECT( [variableDescription offset], sizeof(id), @"offset of variable" );
    IDEXPECT( [variableDescription name], @"myIvar", @"name of ivar" );
    IDEXPECT( [variableDescription type], @"@", @"type of ivar" );
    MPWInstanceVariable *ivar2 = [variableDescriptions lastObject];
    //    INTEXPECT( [variableDescription offset], sizeof(id), @"offset of variable" );
    IDEXPECT( [ivar2 name], @"ivar2", @"name of ivar" );
    IDEXPECT( [ivar2 type], @"@", @"type of ivar" );
    MPWStCompiler *testCompiler=[MPWStCompiler compiler];
    [testCompiler evaluateScriptString:@"testInstance := __TestClassWithIVarsFromSyntax new.  "];
    [testCompiler evaluateScriptString:@"var:testInstance/myIvar := 'hi'. "];
    IDEXPECT([testCompiler evaluateScriptString:@"testInstance myIvar."],@"hi",@"accessor ");
    IDEXPECT([testCompiler evaluateScriptString:@"var:testInstance/myIvar "],@"hi",@"accessor via pi syntax");
    [testCompiler evaluateScriptString:@"testInstance setMyIvar:'2nd value'. "];
    IDEXPECT([testCompiler evaluateScriptString:@"testInstance myIvar."],@"2nd value",@" set and get viaaccessor ");
}



+(void)testGetInstanceVarNames
{
	id varNames = [[[NSString instanceVariables] collect] name];
	INTEXPECT( [varNames count], 1 ,@"NSString should have exactly 1 instance var");
	IDEXPECT( [varNames lastObject], @"isa" ,@"NSString's sole instance variable");
}

+(void)testGetInstanceVarDefByName
{
	id ivardef = [NSString ivarForName:@"isa"];
	IDEXPECT( [ivardef name], @"isa" ,@"name of isa");
//	IDEXPECT( [ivardef type], @"@" ,@"type of isa");
	IDEXPECT( [ivardef type], @"#" ,@"type of isa");
	INTEXPECT( [ivardef offset], 0 ,@"offset of isa");

}

+(void)testCreateObjectiveCForVariable
{
    id compiler = [[[self alloc] init] autorelease];
    id parsed = [@"a" compileIn:compiler];
    id objcCode = [MPWObjCGenerator process:parsed];
    IDEXPECT( objcCode, @"a", @"generating Objective-C didn't work");
}

+(void)testCreateObjectiveCForConstants
{
    id compiler = [[[self alloc] init] autorelease];
    id parsedNumber = [@"1" compileIn:compiler];
    id objcNumber = [parsedNumber evaluateIn:compiler] ;
    IDEXPECT( objcNumber, @(1), @"generating Objective-C for constant didn't work");
    id parsedString = [@"'hello'" compileIn:compiler];
    id objcString = [MPWObjCGenerator process:parsedString];
    IDEXPECT( objcString, @"@\"hello\"", @"generating Objective-C for constant string didn't work");
}

+(void)testCreateObjectiveCForUnaryMessageSend
{
    id compiler = [[[self alloc] init] autorelease];
    id parsed = [@"a class." compileIn:compiler];
    id objcCode = [MPWObjCGenerator process:parsed];
    IDEXPECT( objcCode, @"[a class]", @"generating Objective-C didn't work for unary message send");
}

+(void)testCreateObjectiveCForMessageSendWithArg
{
    id compiler = [self compiler];
    id parsed = [@"NSString stringWithString:'hello world!'." compileIn:compiler];
    id objcCode = [MPWObjCGenerator process:parsed];
    IDEXPECT( objcCode, @"[NSString stringWithString:@\"hello world!\"]", @"generating Objective-C didn't work");
}

+(void)testBlockArgs
{
    [self testexpr:@"{ :i | i } value: 2." expected:@"2"];
}

+(void)testParseBlockArgs
{
    MPWBlockExpression *block= [self evaluate:@" { :a | a * 2. } block."];
    IDEXPECT( [block arguments], @[@"a"], @"single parameter 'a'");
}

+(void)testParseImplicitBlockArgs
{
    MPWBlockExpression *block= [self evaluate:@" { $0 * 2. } block."];
    IDEXPECT( [block arguments], @[ @"$0"],@"single implicit argument");
}

+(void)testMethodVarsHaveLocalScope
{

	[self testexpr:@"a:=1. context addScript:'a:=2. a*2.' forClass:'NSString' methodHeaderString:'dummyMethodThatSetsA'. '' dummyMethodThatSetsA. a." expected:@"1"];
}


+(void)testToDo
{
	[self testexpr:@"a:=1. 1 to:10 do: [ :i | a:=(a+1) ]. a." expected:@"11"];
}

+(void)testBinarySelectorPrecedenceOverKeyword
{
	[self testexpr:@"(1+3 to:3+8) to." expected:@"11"];
}

+(void)testIntervalBlockCollect
{
	[self testexpr:@"((1 to:3) collect:[ :i | i+2]) lastObject" expected:@"5"];
}

+(void)testArrayBlockCollect
{
	TESTEXPR(@"( #( 1, 2, 7 ) collect:[ :i | i*2]) lastObject" ,@"14");
}

+(void)testNegativeDecimalFractions
{
	[self testexpr:@"(-1.2  * 10) intValue stringValue" expected:@"-12"];
	[self testexpr:@"(1.2 negated * 10) intValue stringValue" expected:@"-12"];
}

+(void)testCommaSelector
{
	[self testexpr:@"'Hello ','World!'" expected:@"Hello World!"];
	[self testexpr:@" #() , 'a', '2'" expected:[NSArray arrayWithObjects:@"a",[NSNumber numberWithInt:2],nil]];
}


+(void)testVariableReferenceWithURISchemeWorks
{
	[self testexpr:@"a:=1. var:a" expected:@"1"];
}

+(void)testVariableAssignmentWithURISchemeWorks
{
	[self testexpr:@"var:a := 1. a." expected:@"1"];
}


+(void)testVariableKnowsScheme
{
    id compiler = [[[self alloc] init] autorelease];
	IDEXPECT( [[@"var:a" compileIn:compiler] scheme], @"var", @"scheme of variable ref");
	IDEXPECT( [[@"file:hello" compileIn:compiler] scheme], @"file", @"scheme of file ref");
}

+(void)testURIVariableCanHaveURISyntax
{
    id compiler = [[[self alloc] init] autorelease];
	id fileExpr = [@"file:hello.st" compileIn:compiler];
	IDEXPECT( [fileExpr class], [MPWIdentifierExpression class], @"class of complex file ref");
	IDEXPECT( [[@"http://www.metaobject.com/Blog/" compileIn:compiler] name], @"//www.metaobject.com/Blog/", @"scheme of http identifier");
}

+(void)testUnknownSchemeDoesntDefaultToVar
{
	id result=nil;
	NS_DURING
	result = [self evaluate:@"a:=3. bozo:a"];
	NS_HANDLER
		return;
	NS_ENDHANDLER
	EXPECTTRUE( NO, @"unknown handler should have raised");
}

+(void)testClassScheme
{
	INTEXPECT( [self evaluate:@"class:NSString"], [NSString class], @"class NSString");
}

+(void)testVarSchemeWithKeyValuePath
{
	[self testexpr:@" objs:= #( 'obj1', 'obj2' ). keys := #( 'key1' , 'key2' ). dict := NSDictionary dictionaryWithObjects: objs forKeys:keys.  var:dict/key1" expected:@"obj1"];
}

+(void)testRefSchemeAccessesBinding
{
	[self testexpr:@" a:='42'.  b := ref:a . b value. " expected:@"42"];
}

+(void)testRefSchemeWorksOnTopOfOtherScheme
{
	[self testexpr:@" a:='42'.  b := ref:var:a . b value. " expected:@"42"];
}

+(void)testDotAllowedInIdentifiers
{
	[self testexpr:@" a.b := '42'. a.b " expected:@"42"];
}

+(void)testHttpArgWithLeadingZero
{
	NSString *testString = @"var://www.livescribe.com/cgi-bin/WebObjects/LDApp.woa/wa/flashXML?xml=0000C0A8011700003A9B943B0000012A1F327D6595DF6E07";
	MPWStCompiler *compiler=[[[MPWStCompiler alloc] init] autorelease];
	id compiled = [testString compileIn:compiler];
	id identifer=[compiled identifier];
	IDEXPECT( [identifer identifierName], @"//www.livescribe.com/cgi-bin/WebObjects/LDApp.woa/wa/flashXML?xml=0000C0A8011700003A9B943B0000012A1F327D6595DF6E07",@"identifier with leading zeros" );
}

+(void)testStringToBinding
{
	[self testexpr:@" a := '42'. b := context bindingForString:'a'. b value. " expected:@"42"];
}

+(void)testBinarySelectorPriorityOverKeyword
{
	[self testexpr:@" ( 2@3 extent:10@20 ) origin y  " expected:@"3"];
}

+(void)testRelScheme
{
	id defScheme = @" a := NSMutableDictionary dictionary. a setObject:'there' forKey:'hi'. scheme:my := MPWRelScheme alloc initWithBaseScheme: scheme:var baseURL:'a'. ";
	id useScheme = @" my:hi ";
	id evaluator = [[[self alloc] init] autorelease];
	[evaluator evaluateScriptString:defScheme];
	IDEXPECT( [evaluator evaluateScriptString:useScheme], @"there", @"evaluating scheme");
}

+(void)testIdentifierInterpolation
{
	[self testexpr:@" a:=42. c:=43. b:='a'. var:{b} " expected:@"42"];
}


+(void)testIdentifierInterpolationWorksAsAssignmentTarget
{
	[self testexpr:@" a:=42. c:=43. b:='a'. var:{b} := 45. a. " expected:@"45"];
}

+(void)testGetReasonableCompilerErrorOnMissingBinaryArgument
{
    NSString *exprWithSyntaxError=@"a:=4.  a + ";
	MPWStCompiler *compiler=[[[MPWStCompiler alloc] init] autorelease];
    @try {
        [compiler compile:exprWithSyntaxError];
        EXPECTTRUE(NO, @"should have gotten an exception here");
    }
    @catch (NSException *exception) {
        NSLog(@"exception: %@",exception);
        IDEXPECT([exception name], @"argument missing", @"exception ");
        NSLog(@"token: %@",[[exception userInfo] objectForKey:@"token"]);
        IDEXPECT([[exception userInfo] objectForKey:@"token"], @"+", @"last token");
    }
}

+(void)testNestedLiteralArrays
{
    id result = [self evaluate: @"#( 1, 2, #( 2, 3 ) )"];
    INTEXPECT([result count], 3, @"top level elements");
}

+(void)testPeriodAtEndOfIdentifierAndStatementTreatedAsStatementEnd
{
    id result=[self evaluate:@"a:=3. b:=4. var:a. "];  
    INTEXPECT([result intValue], 3, @"value of identifier without terminating period, space follows");
}

+(void)testPeriodAtEndOfIdentifierAndStatementAndEOFTreatedAsStatementEnd
{
    id result=[self evaluate:@"a:=3. b:=4. var:a."];  
    INTEXPECT([result intValue], 3, @"value of identifier without terminating period, space follows");
}

+(void)testBracketsTerminateIdentifier
{
    id result=[self evaluate:@"a:=3. b:=4. (var:a)."];  
    INTEXPECT([result intValue], 3, @"value of identifier without terminating period, space follows");
}

+(void)testLeftArrowWorksLikeAssignment
{
    id result=[self evaluate:@"a <- 3. b <- 4. a"];  
    INTEXPECT([result intValue], 3, @"left arrow didn't do assignment");
}

+(void)testPipeForTemporaryVariablesAllowed
{
    id result=[self evaluate:@"| a b | a := 3+4. a"];
    INTEXPECT([result intValue], 7, @"3+4");
}


+(void)testSingleCharUnicodeIdentifiersAllowed
{
    unichar pichar=960;
    NSString *script=[NSString stringWithFormat:@"%C := 314 . %C * 2.",pichar,pichar];
    id result=[self evaluate:script];
    INTEXPECT([result intValue], 628, @"2 * pi * 100");
}

+(void)testSmalltalkCascade
{
    NSArray *result=[self evaluate:@" a:= NSMutableArray array. a addObject:'hi'; addObject:'there'. a."];
    INTEXPECT([result count], 2, @"after cascade should have 2 elements");
    IDEXPECT([result firstObject], @"hi", @"first object");
    IDEXPECT([result lastObject], @"there", @"last object");
}


+(void)testCompositionViaPipe
{
    NSString *result=[self evaluate:@"'a' stringByAppendingString:'b' | stringByAppendingString:'c'."];
    IDEXPECT(result, @"abc", @"concated");
}


+(void)testCompositionViaPipeDoesntBlockFurtherEval
{
    NSString *result=[self evaluate:@"'a' stringByAppendingString:'b' | stringByAppendingString:'c'. 'hello'"];
    IDEXPECT(result, @"hello", @"after");
}



+(void)testCurlyBracesAllowedForBlocks
{
    [self testexpr:@"a:=2. (1 to:10) do:{ :i | a:=(2*a).}. a." expected:[NSNumber numberWithInt:2048]];
}

+(void)testDefineClassMethod
{
    id evaluator = [[[self alloc] init] autorelease];

    [evaluator addScript:@"42." forMetaClass:@"NSString" methodHeaderString:@"<int>theAnswer"];
    INTEXPECT([NSString theAnswer], 42, @"class method");
//    EXPECTTRUE(false, @"implemented");
}

+(void)testPipeEqualsCompilesButDoesSameAsAssignment
{
    [self testexpr:@"a |= 2.  a." expected:[NSNumber numberWithInt:2]];
}

+(void)testSimpleBindingsAreUniquedInCompile
{
    MPWStCompiler *compiler = [MPWStCompiler compiler];
    MPWAssignmentExpression *e=[compiler compile:@"a:=a"];
    MPWIdentifierExpression *lhs=[e lhs];
    MPWIdentifierExpression *rhs=[e rhs];
    EXPECTTRUE([lhs isKindOfClass:[MPWIdentifierExpression class]], @"lhs is identifer expression")
    EXPECTTRUE([rhs isKindOfClass:[MPWIdentifierExpression class]], @"rhs is identifer expression")
    
    EXPECTTRUE( lhs == rhs, @"lhs should be identical to rhs");
    
}

+(void)testComplexBindingsAreUniquedInCompile
{
    MPWStCompiler *compiler = [MPWStCompiler compiler];
    MPWAssignmentExpression *e=[compiler compile:@"var:a := var:a"];
    MPWIdentifierExpression *lhs=[e lhs];
    MPWIdentifierExpression *rhs=[e rhs];
    EXPECTTRUE([lhs isKindOfClass:[MPWIdentifierExpression class]], @"lhs is identifer expression")
    EXPECTTRUE([rhs isKindOfClass:[MPWIdentifierExpression class]], @"rhs is identifer expression")
    
    EXPECTTRUE( lhs == rhs, @"lhs should be identical to rhs");
    
}

+(void)testLiteralArrayWithSpecifiedClass
{
    NSMutableArray* result=[self evaluate:@"#NSMutableArray(1, 2, 3)"];
    INTEXPECT( result.count, 3, @"elements in array");
    @try {
        [result addObject:@"@(4)"];
    } @catch (NSException *e) {
        EXPECTTRUE(false,@"exception thrown");
    }
    INTEXPECT(result.count, 4, @"should have added an element");
}

+(void)testLiteralDictWithSpecifiedClass
{
    NSMutableDictionary* result=[self evaluate:@"#NSMutableDictionary{ 1 : 2, 2 : 4, 3 : 'world' }"];
    INTEXPECT( result.count, 3, @"elements in count");
    @try {
        result[@"hello"]=@"world!";
    } @catch (NSException *e) {
        EXPECTTRUE(false,@"exception thrown");
    }
    INTEXPECT(result.count, 4, @"should have added an element");
}

+(void)testLiteralSet
{
    NSSet* result=[self evaluate:@"#NSSet(1,1, 2, 3,3 )"];
    INTEXPECT( result.count, 3, @"elements in set");
    
    EXPECTTRUE( [result member:@1], @"result responds to set messages");
    
}


+(void)testClassDefSyntax
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    MPWClassDefinition *classDef=[compiler parseClassDefinitionFromString:@"class ObjStTestsMyNumberSubclass : NSNumber { -multiplyByNumber:num { self * num. }}"];
    EXPECTNOTNIL(classDef,@"should have a class definition object");
    
    IDEXPECT(classDef.name,@"ObjStTestsMyNumberSubclass",@"name of class" );
    IDEXPECT(classDef.superclassName,@"NSNumber",@"name of superclass" );
    NSArray *methods=classDef.methods;
    INTEXPECT( methods.count,1 , @"number of methods");
    MPWScriptedMethod *method=methods.firstObject;
    MPWMethodHeader *header=method.methodHeader;
    IDEXPECT( header.methodName, @"multiplyByNumber:", @"method name");
    IDEXPECT( header.parameterNames, @[@"num"], @"param name");
    IDEXPECT( [header parameterTypes], @[@"id"], @"param type");
    IDEXPECT( [header typeString], @"@@:@", @"method typestring");
}

+(void)testCreateSubclassUsingSnytax
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    MPWClassDefinition *classDef=[compiler parseClassDefinitionFromString:@"class ObjStTestsMyNumberSubclass : MPWInteger { -multiplyByNumber:num { self * num. }}"];

    Class aClass = NSClassFromString( @"ObjStTestsMyNumberSubclass" );
    Class superClass = NSClassFromString( classDef.superclassName);
    EXPECTNIL(aClass, @"shouldn't exist before I create it");
    EXPECTNOTNIL(superClass, @"superclass should exist");
    
    aClass=(Class)[classDef evaluateIn:compiler];
    EXPECTNOTNIL(aClass, @"superclass should exist");
    IDEXPECT(aClass, NSClassFromString( @"ObjStTestsMyNumberSubclass" ),@"class created and accessible");
    
    id mynumber=[aClass numberWithInt:23];
    id result=[mynumber multiplyByNumber:[MPWInteger integer:10]];
    INTEXPECT([result intValue], 230, @"result of multiplying");
}

+(void)testClassDefWithoutExplicitSuperclassIsNSObjectSubclass
{
    Class definedClass=NSClassFromString(@"ObjSTNSObjectSubclass");
    EXPECTNIL(definedClass ,@"should not exist yet");
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    [compiler evaluateScriptString:@"class ObjSTNSObjectSubclass  { -multiplyBySeven:num { 7 * num. }}"];
    definedClass=NSClassFromString(@"ObjSTNSObjectSubclass");
    EXPECTNOTNIL( definedClass,@"should now exist");
    IDEXPECT( [definedClass superclass], [NSObject class],@"should be an NSObject subclass");
    id result=[compiler evaluateScriptString:@"ObjSTNSObjectSubclass new autorelease multiplyBySeven:5."];
    IDEXPECT(result,@(35),@"method was successfully defined");
}

+(void)testClassDefWithExistingClassIsClassExtension
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    [compiler evaluateScriptString:@"class NSObject  { -st_extend_multiplyByEight:num { 8 * num. }}"];
    id result=[compiler evaluateScriptString:@"NSObject new autorelease st_extend_multiplyByEight:5."];
    IDEXPECT(result,@(40),@"method was successfully defined");
}

+(void)testNestedVarExprWithPath
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    [compiler evaluateScriptString:@"a := #{ 'key1' : 'key2' }."];
    [compiler evaluateScriptString:@"b := #{ 'key2' : 42 }."];
    id result=[compiler evaluateScriptString:@"var:b/{var:a/key1}"];
    IDEXPECT( result, @42, @"nested expr result");
}

+(void)testSimpleFilterDefSyntax
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    [compiler evaluateScriptString:@"filter MyFilter |{  self forward:object uppercaseString. }"];
    id result=[[compiler evaluateScriptString:@" MyFilter process:'lowercase world'."] firstObject];
    IDEXPECT( result, @"LOWERCASE WORLD", @"nested expr result");
}

+(void)testFilterDefWithNormalMethods
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    [compiler evaluateScriptString:@"filter LowerFilter { -writeObject:object {  self forward:object lowercaseString. }}"];
    id result=[[compiler evaluateScriptString:@" LowerFilter process:'SHOULD BE LOWER'."] firstObject];
    IDEXPECT( result, @"should be lower", @"nested expr result");
}

+(void)testParseSimpleProperty
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    MPWClassDefinition *def=[compiler compile:@"class PropertyTestClass {  /property { |= {  3. }}}"];
    INTEXPECT( [[def propertyPathDefinitions] count], 1, @"number of prop defs");
    IDEXPECT( [[[[def propertyPathDefinitions] firstObject] propertyPath] name], @"property", @"name of prop def");
}

+(void)testParsePropertyPathWithTwoComponents
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    MPWClassDefinition *def=[compiler compile:@"class PropertyTestClass { /property/path { |= {  3. }}}"];
    INTEXPECT( [[def propertyPathDefinitions] count], 1, @"number of prop defs");
    IDEXPECT( [[[[def propertyPathDefinitions] firstObject] propertyPath] name], @"property/path", @"name of prop def");
}

+(void)testParseTwoPropertyPaths
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    MPWClassDefinition *def=[compiler compile:@"class PropertyTestClass { /property/path1 { |= {  3. }} /property/path2 { |= {  5. }}}"];
    INTEXPECT( [[def propertyPathDefinitions] count], 2, @"number of prop defs");
    IDEXPECT( [[[[def propertyPathDefinitions] firstObject] propertyPath] name], @"property/path1", @"name of prop def");
    IDEXPECT( [[[[def propertyPathDefinitions] lastObject] propertyPath] name], @"property/path2", @"name of prop def");
}

+(void)testParsePropertyPathWithArg
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    MPWClassDefinition *def=[compiler compile:@"class PropertyTestClass { /property/:arg { |= {  arg+4. }}} "];
    INTEXPECT( [[def propertyPathDefinitions] count], 1, @"number of prop defs");
    IDEXPECT( [[[[def propertyPathDefinitions] firstObject] propertyPath] name], @"property/:arg", @"name of prop def");
}

+(void)testParsePropertyPathSetter
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    MPWClassDefinition *def=[compiler compile:@"class PropertyTestClass { /property/:arg { =| {  arg+4. }}} "];
    INTEXPECT( [[def propertyPathDefinitions] count], 1, @"number of prop defs");
    IDEXPECT( [[[[def propertyPathDefinitions] firstObject] propertyPath] name], @"property/:arg", @"name of prop def");
}

+(void)testParsePropertyPathWithWildcard
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    MPWClassDefinition *def=[compiler compile:@"class PropertyTestClass { /property/* { |= {  3.}  }}"];
    INTEXPECT( [[def propertyPathDefinitions] count], 1, @"number of prop defs");
    IDEXPECT( [[[[def propertyPathDefinitions] firstObject] propertyPath] name], @"property/*", @"name of prop def");
}

+(void)testParsePropertyPathWithWildcardAndParameter
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    MPWClassDefinition *def=[compiler compile:@"class PropertyTestClass { /property/*:path { |= {  path. }  }}"];
    INTEXPECT( [[def propertyPathDefinitions] count], 1, @"number of prop defs");
    IDEXPECT( [[[[def propertyPathDefinitions] firstObject] propertyPath] name], @"property/*:path", @"name of prop def");
}

+(void)testEvaluateSimplePropertyPathGetter
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    [compiler evaluateScriptString:@"class PropertyTestClass1 : MPWScheme { /property { |= {  3.}  }}."];
    id result = [compiler evaluateScriptString:@"a := PropertyTestClass1 new. scheme:p := a. p:property."];
    IDEXPECT(result,@(3),@"evaluating a simple property");
}

+(NSArray*)testSelectors
{
    return @[
		@"testLocalVariables",
		@"testThreePlusFour",
		@"stringConcat",
		@"nestedArgStringConcat",
        @"nestedReceiverStringConcat",@"simpleLiteral",
        @"stackedMappedConcat",@"mixedStackedMappedConcat",
        @"arrayLiteral",
        @"collectArrayLiteral",@"collectTwoArrayLiterals",
		@"testAssignment",
		@"testFloatArithmetic",
		@"testAsFloat",
		@"testUnknownSelector",
		@"testNil",
		@"testAssignNil",
		@"testMultipleStatments",
		@"testIfTrueIfFalse",
		@"testIfTrueIfFalseWithExpressionValue",
		@"testIfTrueIfFalseWithExpressionCondition",
		@"testBasicWhileTrue",
		@"testWhileTrueWithLongerBlock",
		@"testForLoop",
		@"testRecursiveInterpret",
		@"testSevenMinus4",
		@"testScriptOnObjectKnowsSelf",
		@"testAddingMethodToClass",
		@"testNegativeLiteral",
		@"testNegativeLiteralComputation",
		@"testSelectHOM",
		@"testScriptWithParameters",
		@"testNSRangeViaSubarray",
		@"testNSPointViaString",
		@"testNSSizeViaString",
		@"testAddMethodWithIntArg",
		@"testAddMethodWithIntArgAndReturn",
		@"testAddMethodWithIntArgViaMethodHeader",
		@"testAllClassesWithScripts",
		@"testScriptNamesForClass",
		@"testExternalDictForDefinedMethods",
//		@"testDefinedMethodsForExternalDict",
		@"testDefineMethodInUnknownClassDoesntCrash",
        @"testRespondsToSelectorWorksFromScript",
		@"testVariableDataFlowAnalysis",
        @"testCreateSubclass",
        @"testCreateSubclassWithInstanceVariables",
        @"testParseSubclassWithInstanceVariablesUsingSyntax",
        @"testCreateSubclassWithInstanceVariablesUsingSyntax",
        @"testGetInstanceVarNames",
        @"testCreateObjectiveCForVariable",
        @"testCreateObjectiveCForConstants",
        @"testCreateObjectiveCForUnaryMessageSend",
        @"testCreateObjectiveCForMessageSendWithArg",
		@"testGetInstanceVarDefByName",
        @"testBlockArgs",
        @"testParseBlockArgs",
        @"testParseImplicitBlockArgs",
        @"testMethodVarsHaveLocalScope",
        @"testToDo",
        @"testBinarySelectorPrecedenceOverKeyword",
        @"testIntervalBlockCollect",
        @"testArrayBlockCollect",
        @"testNegativeDecimalFractions",
		@"testCommaSelector",
		@"testVariableReferenceWithURISchemeWorks",
		@"testVariableAssignmentWithURISchemeWorks",
		@"testVariableKnowsScheme",
		@"testURIVariableCanHaveURISyntax",
		@"testUnknownSchemeDoesntDefaultToVar",
		@"testClassScheme",
		@"testAccessingInstanceVariablesOfCreatedClass",
		@"testVarSchemeWithKeyValuePath",
		@"testRefSchemeAccessesBinding",
		@"testRefSchemeWorksOnTopOfOtherScheme",
		@"testDotAllowedInIdentifiers",
		@"testMethodWithParameters",
		@"testRedefiningMethod",
			@"testHttpArgWithLeadingZero",
			@"testStringToBinding",
			@"testBinarySelectorPriorityOverKeyword",
			@"testRelScheme",
			@"testIdentifierInterpolation",
			@"testGetReasonableCompilerErrorOnMissingBinaryArgument",
            @"testNestedLiteralArrays",
            @"testPeriodAtEndOfIdentifierAndStatementTreatedAsStatementEnd",
            @"testPeriodAtEndOfIdentifierAndStatementAndEOFTreatedAsStatementEnd",
            @"testBracketsTerminateIdentifier",
            @"testLeftArrowWorksLikeAssignment",
            @"testPipeForTemporaryVariablesAllowed",
            @"testSingleCharUnicodeIdentifiersAllowed",
            
            @"testSmalltalkCascade",
            @"testCompositionViaPipe",
            @"testCompositionViaPipeDoesntBlockFurtherEval",
            @"testCurlyBracesAllowedForBlocks",
            @"testDefineClassMethod",
            @"testPipeEqualsCompilesButDoesSameAsAssignment",
            @"testSimpleBindingsAreUniquedInCompile",
            @"testComplexBindingsAreUniquedInCompile",
            @"testParseMethodSyntaxOneArg",
        @"testParseMethodSyntaxNoArgs",
        @"testSimpleLiteralDict",
        @"testLiteralDictWithNumberKey",
            @"testTwoElementLiteralDict",
            @"testLiteralArrayWithSpecifiedClass",
        @"testLiteralSet",
        @"testLiteralDictWithSpecifiedClass",
        @"testClassDefSyntax",
        @"testCreateSubclassUsingSnytax",
        @"testClassDefWithoutExplicitSuperclassIsNSObjectSubclass",
        @"testClassDefWithExistingClassIsClassExtension",
        @"testNestedVarExprWithPath",
        @"testSimpleFilterDefSyntax",
        @"testFilterDefWithNormalMethods",
        @"testParseSimpleProperty",
        @"testParsePropertyPathWithTwoComponents",
        @"testParseTwoPropertyPaths",
        @"testParsePropertyPathWithArg",
        @"testParsePropertyPathSetter",
        @"testParsePropertyPathWithWildcard",
        @"testParsePropertyPathWithWildcardAndParameter",
        @"testEvaluateSimplePropertyPathGetter",
        ];
}

//			@"testIdentifierInterpolationWorksAsAssignmentTarget",

@end
