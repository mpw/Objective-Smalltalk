//
//  STTypeInferenceTests.m
//  ObjectiveSmalltalk
//

#import "STTypeInferenceTests.h"
#import "STTypeInference.h"
#import "STScriptedMethod.h"
#import "MPWMessageExpression.h"
#import "MPWAssignmentExpression.h"
#import "STVariableDefinition.h"
#import "MPWStatementList.h"
#import <MPWFoundation/MPWTypeDefinition.h>

@implementation STTypeInferenceTests

+(id)parseExpr:(NSString*)source
{
    id parsed=[source compileIn:[self compiler]];
    return [parsed respondsToSelector:@selector(statements)] ? [[parsed statements] firstObject] : parsed;
}

+(NSString*)inferredTypeNameFor:(NSString*)source in:(STTypeContext*)context
{
    return [[[self parseExpr:source] resultTypeIn:context] name];
}

#pragma mark - literals

+(void)testStringLiteralInfersNSString
{
    IDEXPECT( [self inferredTypeNameFor:@"'hello'" in:nil], @"NSString", @"string literal type");
}

+(void)testNumberLiteralInfersNSNumber
{
    IDEXPECT( [self inferredTypeNameFor:@"42" in:nil], @"NSNumber", @"number literal type");
}

#pragma mark - identifiers

+(void)testUnknownIdentifierInfersId
{
    IDEXPECT( [self inferredTypeNameFor:@"undeclaredThing" in:[STTypeContext context]], @"id", @"unknown identifier defaults to id");
}

+(void)testDeclaredIdentifierInfersDeclaredType
{
    STTypeContext *context=[STTypeContext context];
    [context declareName:@"x" type:[MPWTypeDefinition descriptorForTypeName:@"int"]];
    IDEXPECT( [self inferredTypeNameFor:@"x" in:context], @"int", @"declared identifier type");
}

#pragma mark - assignment

+(void)testAssignmentInfersRightHandSideType
{
    IDEXPECT( [self inferredTypeNameFor:@"y := 'hello'" in:[STTypeContext context]], @"NSString", @"assignment yields rhs type");
}

#pragma mark - variable definitions

+(void)testVariableDefinitionResultTypeIsDeclaredType
{
    IDEXPECT( [self inferredTypeNameFor:@"var j:int." in:nil], @"int", @"var def result type");
}

#pragma mark - typing context seeded from a method

+(void)testMethodArgumentSeededIntoContext
{
    STScriptedMethod *method=[[self compiler] parseMethodDefinition:@"-scaleBy: n:int { n. }"];
    STTypeContext *context=[STTypeContext contextForMethod:method];
    IDEXPECT( [[context typeForName:@"n"] name], @"int", @"argument seeded into context");
}

+(void)testLocalVariableDefinitionSeededIntoContext
{
    STScriptedMethod *method=[[self compiler] parseMethodDefinition:@"-compute { var k:int. k. }"];
    STTypeContext *context=[STTypeContext contextForMethod:method];
    IDEXPECT( [[context typeForName:@"k"] name], @"int", @"local var def seeded into context");
}

#pragma mark - message-send return-type inference

+(STTypeContext*)contextWithIntNamed:(NSString*)name
{
    STTypeContext *context=[STTypeContext context];
    [context declareName:name type:[MPWTypeDefinition descriptorForTypeName:@"int"]];
    return context;
}

+(void)testArithmeticOnPrimitiveReceiverInfersPrimitive
{
    IDEXPECT( [self inferredTypeNameFor:@"a + 4" in:[self contextWithIntNamed:@"a"]], @"int", @"int + literal infers int");
}

+(void)testComparisonOnPrimitiveReceiverInfersBool
{
    IDEXPECT( [self inferredTypeNameFor:@"a < 4" in:[self contextWithIntNamed:@"a"]], @"bool", @"int comparison infers bool");
}

+(void)testArithmeticOnObjectReceiverInfersId
{
    IDEXPECT( [self inferredTypeNameFor:@"3 + 4" in:[STTypeContext context]], @"id", @"NSNumber arithmetic stays an object");
}

+(void)testComparisonOnObjectReceiverInfersBool
{
    IDEXPECT( [self inferredTypeNameFor:@"3 < 4" in:[STTypeContext context]], @"bool", @"object comparison infers bool");
}

+(void)testMessageReturningObjectInfersId
{
    IDEXPECT( [self inferredTypeNameFor:@"'hello' uppercaseString" in:[STTypeContext context]], @"id", @"uppercaseString returns an object");
}

+(void)testMessageReturningPrimitiveInfersPrimitive
{
    IDEXPECT( [self inferredTypeNameFor:@"'hello' length" in:[STTypeContext context]], @"long", @"length returns an integer");
}

+(void)testPrimitiveExtractorOnUnknownReceiverInfersPrimitive
{
    IDEXPECT( [self inferredTypeNameFor:@"anObject intValue" in:[STTypeContext context]], @"int", @"intValue infers int even for an id receiver");
}

+(void)testUnknownSelectorOnUnknownReceiverInfersId
{
    IDEXPECT( [self inferredTypeNameFor:@"anObject frobnicate" in:[STTypeContext context]], @"id", @"unknown selector on id falls back to id");
}

#pragma mark - binding resolution + coercion (the annotation pass)

+(STTypeContext*)contextWithInts:(NSArray*)names
{
    STTypeContext *context=[STTypeContext context];
    for ( NSString *name in names ) {
        [context declareName:name type:[MPWTypeDefinition descriptorForTypeName:@"int"]];
    }
    return context;
}

+(id)annotate:(NSString*)source in:(STTypeContext*)context
{
    return [[self parseExpr:source] typeAnnotateIn:context];
}

+(void)testPrimitiveArithmeticResolvesToEarlyBoundMessage
{
    id annotated=[self annotate:@"a + b" in:[self contextWithInts:@[@"a", @"b"]]];
    EXPECTTRUE( [annotated isKindOfClass:[STPrimitiveMessageExpression class]], @"int + int is early-bound");
    IDEXPECT( [[annotated primitiveResultType] name], @"int", @"early-bound result type");
}

+(void)testPrimitiveComparisonResolvesToEarlyBoundBool
{
    id annotated=[self annotate:@"a < b" in:[self contextWithInts:@[@"a", @"b"]]];
    EXPECTTRUE( [annotated isKindOfClass:[STPrimitiveMessageExpression class]], @"int < int is early-bound");
    IDEXPECT( [[annotated primitiveResultType] name], @"bool", @"comparison result is bool");
}

+(void)testObjectArithmeticStaysLateBound
{
    id annotated=[self annotate:@"3 + 4" in:[STTypeContext context]];
    EXPECTFALSE( [annotated isKindOfClass:[STPrimitiveMessageExpression class]], @"NSNumber arithmetic stays a normal send");
    EXPECTTRUE( [annotated isKindOfClass:[MPWMessageExpression class]], @"still a message expression");
}

+(void)testMessagingAPrimitiveBoxesTheReceiver
{
    MPWMessageExpression *annotated=[self annotate:@"a printString" in:[self contextWithInts:@[@"a"]]];
    EXPECTTRUE( [[annotated receiver] isKindOfClass:[STCoerce class]], @"primitive receiver is boxed to be messaged");
    EXPECTTRUE( [(STCoerce*)[annotated receiver] isBoxing], @"the coercion is a box");
}

+(void)testAssignmentToPrimitiveVariableUnboxesObjectValue
{
    STTypeContext *context=[self contextWithInts:@[@"x"]];
    MPWAssignmentExpression *annotated=[self annotate:@"x := 3" in:context];
    EXPECTTRUE( [annotated.rhs isKindOfClass:[STCoerce class]], @"object rhs is coerced to the primitive lhs");
    EXPECTTRUE( [(STCoerce*)annotated.rhs isUnboxing], @"the coercion is an unbox");
}

+(void)testAssignmentToUntypedVariableIsNotCoerced
{
    MPWAssignmentExpression *annotated=[self annotate:@"y := 3" in:[STTypeContext context]];
    EXPECTFALSE( [annotated.rhs isKindOfClass:[STCoerce class]], @"no coercion without a declared primitive type");
}

+(void)testVariableDefinitionInitializerIsCoerced
{
    STVariableDefinition *annotated=[self annotate:@"var n:int := 3." in:[STTypeContext context]];
    EXPECTTRUE( [annotated.initializer isKindOfClass:[STCoerce class]], @"initializer coerced to declared type");
    EXPECTTRUE( [(STCoerce*)annotated.initializer isUnboxing], @"object literal unboxed to int");
}

+(void)testStatementListPropagatesLocalTypesToEarlyBinding
{
    id list=[@"var k:int. k + k." compileIn:[self compiler]];
    list=[list typeAnnotateIn:[STTypeContext context]];
    id secondStatement=[[list statements] objectAtIndex:1];
    EXPECTTRUE( [secondStatement isKindOfClass:[STPrimitiveMessageExpression class]], @"k+k early-bound via local var type");
}

#pragma mark - typechecking (send compatibility)

+(NSArray*)diagnosticsFor:(NSString*)source
{
    return [STTypeChecker diagnosticsFor:[self parseExpr:source] in:[STTypeContext context]];
}

+(void)testUnknownSelectorOnKnownTypeIsFlagged
{
    NSArray *diagnostics=[self diagnosticsFor:@"'hello' bogusSelector"];
    INTEXPECT( diagnostics.count, 1, @"one diagnostic for an unknown selector");
    EXPECTTRUE( [[diagnostics firstObject] containsString:@"bogusSelector"], @"diagnostic names the selector");
    EXPECTTRUE( [[diagnostics firstObject] containsString:@"NSString"], @"diagnostic names the receiver type");
}

+(void)testKnownSelectorOnKnownTypeIsNotFlagged
{
    INTEXPECT( [[self diagnosticsFor:@"'hello' uppercaseString"] count], 0, @"a valid send is not flagged");
}

+(void)testSelectorOnDynamicReceiverIsNotFlagged
{
    INTEXPECT( [[self diagnosticsFor:@"anObject bogusSelector"] count], 0, @"an id receiver is checked dynamically, not flagged");
}

+(void)testDiagnosticInArgumentPositionIsFound
{
    NSArray *diagnostics=[self diagnosticsFor:@"'hello' stringByAppendingString:('x' bogusSelector)"];
    INTEXPECT( diagnostics.count, 1, @"the checker recurses into arguments");
    EXPECTTRUE( [[diagnostics firstObject] containsString:@"bogusSelector"], @"the argument's bad send is reported");
}

#pragma mark - interpreter consistency (the annotated tree evaluates the same)

+(void)testInterpreterEvaluatesEarlyBoundArithmeticConsistently
{
    id evaluator=[[[self alloc] init] autorelease];
    [evaluator bindValue:@(3) toVariableNamed:@"a"];
    [evaluator bindValue:@(4) toVariableNamed:@"b"];
    id rawResult=[[self parseExpr:@"a + b"] evaluateIn:evaluator];
    id annotated=[[self parseExpr:@"a + b"] typeAnnotateIn:[self contextWithInts:@[@"a", @"b"]]];
    EXPECTTRUE( [annotated isKindOfClass:[STPrimitiveMessageExpression class]], @"resolved to an early-bound node");
    id annotatedResult=[annotated evaluateIn:evaluator];
    IDEXPECT( annotatedResult, rawResult, @"early-bound node evaluates identically to the raw send");
    IDEXPECT( annotatedResult, @(7), @"...and to the expected value");
}

+(void)testInterpreterEvaluatesCoercionAsPassThrough
{
    id evaluator=[[[self alloc] init] autorelease];
    [evaluator bindValue:@(42) toVariableNamed:@"n"];
    STCoerce *coerce=[STCoerce coerce:[self parseExpr:@"n"]
                                  from:[MPWTypeDefinition idType]
                                    to:[MPWTypeDefinition descriptorForTypeName:@"int"]];
    IDEXPECT( [coerce evaluateIn:evaluator], @(42), @"a coercion is a pass-through in the all-boxed interpreter");
}

#pragma mark - runtime type provider

+(void)testRuntimeProviderReportsPrimitiveReturnType
{
    STRuntimeTypeProvider *provider=[STRuntimeTypeProvider provider];
    MPWTypeDefinition *nsstring=[MPWTypeDefinition descriptorForTypeName:@"NSString"];
    MPWTypeDefinition *lengthType=[provider returnTypeForSelector:@selector(length) receiverType:nsstring];
    IDEXPECT( lengthType.name, @"long", @"-[NSString length] has an integer return type");
}

+(void)testRuntimeProviderReportsObjectReturnType
{
    STRuntimeTypeProvider *provider=[STRuntimeTypeProvider provider];
    MPWTypeDefinition *nsstring=[MPWTypeDefinition descriptorForTypeName:@"NSString"];
    MPWTypeDefinition *upperType=[provider returnTypeForSelector:@selector(uppercaseString) receiverType:nsstring];
    IDEXPECT( upperType.name, @"id", @"-[NSString uppercaseString] returns an object");
}

+(void)testRuntimeProviderReturnsNilForUnknownReceiverType
{
    STRuntimeTypeProvider *provider=[STRuntimeTypeProvider provider];
    MPWTypeDefinition *result=[provider returnTypeForSelector:@selector(length) receiverType:nil];
    EXPECTNIL( result, @"no receiver type means no answer");
}

+(NSArray*)testSelectors
{
    return @[
        @"testStringLiteralInfersNSString",
        @"testNumberLiteralInfersNSNumber",
        @"testUnknownIdentifierInfersId",
        @"testDeclaredIdentifierInfersDeclaredType",
        @"testAssignmentInfersRightHandSideType",
        @"testVariableDefinitionResultTypeIsDeclaredType",
        @"testMethodArgumentSeededIntoContext",
        @"testLocalVariableDefinitionSeededIntoContext",
        @"testArithmeticOnPrimitiveReceiverInfersPrimitive",
        @"testComparisonOnPrimitiveReceiverInfersBool",
        @"testArithmeticOnObjectReceiverInfersId",
        @"testComparisonOnObjectReceiverInfersBool",
        @"testMessageReturningObjectInfersId",
        @"testMessageReturningPrimitiveInfersPrimitive",
        @"testPrimitiveExtractorOnUnknownReceiverInfersPrimitive",
        @"testUnknownSelectorOnUnknownReceiverInfersId",
        @"testPrimitiveArithmeticResolvesToEarlyBoundMessage",
        @"testPrimitiveComparisonResolvesToEarlyBoundBool",
        @"testObjectArithmeticStaysLateBound",
        @"testMessagingAPrimitiveBoxesTheReceiver",
        @"testAssignmentToPrimitiveVariableUnboxesObjectValue",
        @"testAssignmentToUntypedVariableIsNotCoerced",
        @"testVariableDefinitionInitializerIsCoerced",
        @"testStatementListPropagatesLocalTypesToEarlyBinding",
        @"testUnknownSelectorOnKnownTypeIsFlagged",
        @"testKnownSelectorOnKnownTypeIsNotFlagged",
        @"testSelectorOnDynamicReceiverIsNotFlagged",
        @"testDiagnosticInArgumentPositionIsFound",
        @"testInterpreterEvaluatesEarlyBoundArithmeticConsistently",
        @"testInterpreterEvaluatesCoercionAsPassThrough",
        @"testRuntimeProviderReportsPrimitiveReturnType",
        @"testRuntimeProviderReportsObjectReturnType",
        @"testRuntimeProviderReturnsNilForUnknownReceiverType",
    ];
}

@end
