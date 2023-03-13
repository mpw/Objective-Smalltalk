//
//  MPWStPropertyPathTests.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 19.11.20.
//

#import "MPWStPropertyPathTests.h"
#import "MPWPropertyPathDefinition.h"
#import "MPWPropertyPath.h"
#import "MPWClassDefinition.h"
#import "MPWStTests.h"

@implementation MPWStPropertyPathTests

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWStPropertyPathTests(testing) 


+(void)testParseSimpleProperty
{
    STCompiler *compiler=[STCompiler compiler];
    MPWClassDefinition *def=[compiler compile:@"class PropertyTestClass {  /property { |= {  3. }}}"];
    INTEXPECT( [[def propertyPathDefinitions] count], 1, @"number of prop defs");
    IDEXPECT( [[[[def propertyPathDefinitions] firstObject] propertyPath] name], @"property", @"name of prop def");
}

+(void)testParsePropertyPathWithTwoComponents
{
    STCompiler *compiler=[STCompiler compiler];
    MPWClassDefinition *def=[compiler compile:@"class PropertyTestClass { /property/path { |= {  3. }}}"];
    INTEXPECT( [[def propertyPathDefinitions] count], 1, @"number of prop defs");
    IDEXPECT( [[[[def propertyPathDefinitions] firstObject] propertyPath] name], @"property/path", @"name of prop def");
}

+(void)testParseTwoPropertyPaths
{
    STCompiler *compiler=[STCompiler compiler];
    MPWClassDefinition *def=[compiler compile:@"class PropertyTestClass { /property/path1 { |= {  3. }} /property/path2 { |= {  5. }}}"];
    INTEXPECT( [[def propertyPathDefinitions] count], 2, @"number of prop defs");
    IDEXPECT( [[[[def propertyPathDefinitions] firstObject] propertyPath] name], @"property/path1", @"name of prop def");
    IDEXPECT( [[[[def propertyPathDefinitions] lastObject] propertyPath] name], @"property/path2", @"name of prop def");
}

+(void)testParsePropertyPathWithArg
{
    STCompiler *compiler=[STCompiler compiler];
    MPWClassDefinition *def=[compiler compile:@"class PropertyTestClass { /property/:arg { |= {  arg+4. }}} "];
    INTEXPECT( [[def propertyPathDefinitions] count], 1, @"number of prop defs");
    IDEXPECT( [[[[def propertyPathDefinitions] firstObject] propertyPath] name], @"property/:arg", @"name of prop def");
}

+(void)testParsePropertyPathSetter
{
    STCompiler *compiler=[STCompiler compiler];
    MPWClassDefinition *def=[compiler compile:@"class PropertyTestClass { /property/:arg { =| {  arg+4. }}} "];
    INTEXPECT( [[def propertyPathDefinitions] count], 1, @"number of prop defs");
    IDEXPECT( [[[[def propertyPathDefinitions] firstObject] propertyPath] name], @"property/:arg", @"name of prop def");
}

+(void)testParsePropertyPathWithWildcard
{
    STCompiler *compiler=[STCompiler compiler];
    MPWClassDefinition *def=[compiler compile:@"class PropertyTestClass { /property/* { |= {  3.}  }}"];
    INTEXPECT( [[def propertyPathDefinitions] count], 1, @"number of prop defs");
    IDEXPECT( [[[[def propertyPathDefinitions] firstObject] propertyPath] name], @"property/*", @"name of prop def");
}

+(void)testParsePropertyPathWithWildcardAndParameter
{
    STCompiler *compiler=[STCompiler compiler];
    MPWClassDefinition *def=[compiler compile:@"class PropertyTestClass { /property/*:path { |= {  path. }  }}"];
    INTEXPECT( [[def propertyPathDefinitions] count], 1, @"number of prop defs");
    IDEXPECT( [[[[def propertyPathDefinitions] firstObject] propertyPath] name], @"property/*:path", @"name of prop def");
}

+(void)testEvaluateSimplePropertyPathGetter
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"class PropertyTestClass1 : MPWScheme { /property { |= {  42.}  }}."];
    id result = [compiler evaluateScriptString:@"a := PropertyTestClass1 new. scheme:p := a. p:property."];
    IDEXPECT(result,@(42),@"evaluating a simple property");
}

+(void)testEvaluateSimplePropertyPathGetterHasRef
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"class PropertyTestClass1 : MPWScheme { /property { |= {  theRef.}  }}."];
    id result = [compiler evaluateScriptString:@"a := PropertyTestClass1 new. scheme:p := a. p:property."];
    id ref = [compiler evaluateScriptString:@"ref:p:property reference."];
    IDEXPECT(result,ref,@"evaluating a simple property");
}

+(void)testEvaluatePropertyPathGettersWithArg
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"class PropertyTestClass2 : MPWScheme { /propertyA/:arg1 { |= {  arg1 intValue * 100.  }} /propertyB/:arg2 { |= { arg2 , ' world'.} }} "];
    id result1 = [compiler evaluateScriptString:@"a := PropertyTestClass2 new. scheme:p := a. p:propertyA/3."];
    IDEXPECT(result1,@(300),@"evaluating a property with 1 arg");
    id result2 = [compiler evaluateScriptString:@"p:propertyB/Hello."];
    IDEXPECT(result2,@"Hello world",@"evaluating a property with 1 arg");
}

+(void)testEvaluatePropertyPathGettersWithSeveralArgs
{
    TESTEXPR( @"class PropertyTestClass3 : MPWScheme { /propertyA/:arg1/:arg2/:arg3 { |= {  (arg1 intValue * 100) + (arg2 intValue * 10) + (arg3 intValue).  }}}. a := PropertyTestClass3 scheme. scheme:p := a. p:propertyA/3/4/5.", @(345) );
}

+(void)testEvaluatePropertyPathGetterWithWildcard
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"class PropertyTestClass4 : MPWScheme { /propertyA/*:path { |= {  path   reverseObjectEnumerator allObjects componentsJoinedByString:':'. }}} "];
    id result1 = [compiler evaluateScriptString:@"a := PropertyTestClass4 scheme. scheme:p := a. p:propertyA/a/b/c."];
    IDEXPECT(result1,@"c:b:a",@"evaluating a wildcard property with 3 args");
}

+(void)testSimplePropertyPathSetter
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"class PropertyTestClass5 : MPWDictStore { /propertyA { =| {  self dict setObject:(newValue + 10)  forKey:'variantOfPropertyA'. }}} "];
    [compiler evaluateScriptString:@"a := PropertyTestClass5 scheme. scheme:p := a. p:propertyA := 5 ."];
    id oldKeyValue = [compiler evaluateScriptString:@"a dict objectForKey:'propertyA'."];

    id result1=[compiler evaluateScriptString:@"a dict objectForKey:'variantOfPropertyA'."];
    IDEXPECT(result1,@(15),@"did set properly");
    EXPECTFALSE([oldKeyValue isNotNil],@"nil or NSNil");
}

+(void)testConstantPropertyPathGetterWorksWithPlainClass
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"class PropertyTestClass6  { /propertyA { |= {  33.  }}} "];
    id result1 = [compiler evaluateScriptString:@"a := PropertyTestClass6 new autorelease. var:a/propertyA."];
    IDEXPECT(result1,@(33),@"evaluating constant property");
}

+(void)testPropertyPathGetterWithArgsWorksWithPlainClass
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"class PropertyTestClass7  { /propertyA/:arg1/:arg2 { |= {  arg1 intValue + arg2 intValue.  }}} "];
    id result1 = [compiler evaluateScriptString:@"a := PropertyTestClass7 new autorelease. var:a/propertyA/20/12."];
    IDEXPECT(result1,@(32),@"evaluating property with args on non-scheme class");
}

+(void)testSimplePropertyPathSetterWorksWithPlainClass
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"class PropertyTestClass8  { var tester. /propertyA { =| {  self setTester:newValue. }}} "];
    [compiler evaluateScriptString:@" a := PropertyTestClass8 new autorelease. a setTester:'not set'. var:a/propertyA := 'was set correctly'.  "];
    id result1 = [compiler evaluateScriptString:@"a tester. "];
    IDEXPECT(result1,@"was set correctly",@"result of property setters");
}

+(void)testDefiningNoPropertyPathGettersAllowsSuperclassDefinitionToPrevail
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"scheme PropertyTestClass9 : MPWMappingStore {  /propertyA { =| { 3. }}} "];
    [compiler evaluateScriptString:@"scheme:d := MPWDictStore store."];
    [compiler evaluateScriptString:@"scheme:m := PropertyTestClass9 storeWithSource: scheme:d."];
    [compiler evaluateScriptString:@"d:a := 3."];
    IDEXPECT( [compiler evaluateScriptString:@"m:a"],@(3),@"dict via mapping store subclass that doesn't define getter");


}

+(NSArray*)testSelectors
{
   return @[
       @"testParseSimpleProperty",
       @"testParsePropertyPathWithTwoComponents",
       @"testParseTwoPropertyPaths",
       @"testParsePropertyPathWithArg",
       @"testParsePropertyPathSetter",
       @"testParsePropertyPathWithWildcard",
       @"testParsePropertyPathWithWildcardAndParameter",
       @"testEvaluateSimplePropertyPathGetter",
       @"testEvaluateSimplePropertyPathGetterHasRef",
       @"testEvaluatePropertyPathGettersWithArg",
       @"testEvaluatePropertyPathGettersWithSeveralArgs",
       @"testEvaluatePropertyPathGetterWithWildcard",
       @"testIdentifierInterpolationWorksAsAssignmentTarget",
       @"testSimplePropertyPathSetter",
       @"testConstantPropertyPathGetterWorksWithPlainClass",
       @"testPropertyPathGetterWithArgsWorksWithPlainClass",
       @"testSimplePropertyPathSetterWorksWithPlainClass",
       @"testDefiningNoPropertyPathGettersAllowsSuperclassDefinitionToPrevail",

			];
}

@end
