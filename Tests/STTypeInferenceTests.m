//
//  STTypeInferenceTests.m
//  ObjectiveSmalltalk
//

#import "STTypeInferenceTests.h"
#import "STTypeInference.h"
#import "STScriptedMethod.h"
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
        @"testRuntimeProviderReportsPrimitiveReturnType",
        @"testRuntimeProviderReportsObjectReturnType",
        @"testRuntimeProviderReturnsNilForUnknownReceiverType",
    ];
}

@end
