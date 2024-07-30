//
//  MPWRelScheme.m
//  Arch-S
//
//  Created by Marcel Weiher on 5/10/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import "MPWRelScheme.h"
#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/MPWGenericIdentifier.h>
#import "STIdentifier.h"
#import "MPWBindingLegacy.h"
#import "MPWVarScheme.h"

@implementation MPWRelScheme


-initWithBaseScheme:(MPWScheme*)aScheme baseURL:(NSString*)str
{
    return [super initWithSource:aScheme reference:[self referenceForPath:str]];
}

-initWithRef:(MPWReference*)aBinding
{
    return [self initWithSource:[aBinding store] reference:[aBinding reference]];
}

@end

#import "STCompiler.h"

@implementation MPWRelScheme(testing)

+_testSchemeInterpreter:(NSString*)baseRef
{
    STCompiler *interpreter=[[[STCompiler alloc] init] autorelease];
    [interpreter evaluateScriptString:@"scheme:base := MPWTreeNodeScheme scheme."];
    [interpreter bindValue:baseRef toVariableNamed:@"baseRef"];
    [interpreter evaluateScriptString:@"scheme:rel := MPWRelScheme alloc initWithBaseScheme: scheme:base baseURL:baseRef."];
    [interpreter evaluateScriptString:@"base:/ := 'root' "];
    [interpreter evaluateScriptString:@"base:/subtree := 'subtree-content' "];
    return interpreter;
}

+(void)testBasicLookup
{
    STCompiler *interpreter = [self _testSchemeInterpreter:@"/"];
    IDEXPECT([interpreter evaluateScriptString:@"base:/"] , @"root", @"eval rel:/");
    IDEXPECT([interpreter evaluateScriptString:@"rel:/"] , @"root", @"eval rel:/");
}

+(void)testRelativeLookup
{
    STCompiler *interpreter = [self _testSchemeInterpreter:@"/subtree"];
//    [interpreter evaluateScriptString:@"scheme:rel setBaseIdentifier:'/subtree'"];
    IDEXPECT([interpreter evaluateScriptString:@"rel:/"] , @"subtree-content", @"eval rel:/");
}

+(void)testRelativeFileScheme
{
    STCompiler *interpreter=[[[STCompiler alloc] init] autorelease];
    NSString *path = @"/tmp/relativeSchemeTests.txt";
    [@"hello world!" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    [interpreter evaluateScriptString:@"scheme:rel := MPWRelScheme alloc initWithBaseScheme: scheme:file baseURL:'/tmp'."];
    IDEXPECT([interpreter evaluateScriptString:@"rel:/relativeSchemeTests.txt stringValue"] , @"hello world!", @"eval rel:/relativeSchemeTests.txt");
}

+(void)testRelativeFileSchemeGET
{
    STCompiler *interpreter=[[[STCompiler alloc] init] autorelease];
    NSString *path = @"/tmp/relativeSchemeTests.txt";
    [@"hello world!" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    id rel=[interpreter evaluateScriptString:@"MPWRelScheme alloc initWithBaseScheme: scheme:file baseURL:'/tmp'."];
    IDEXPECT([[rel get:@"/relativeSchemeTests.txt" parameters:nil] stringValue] , @"hello world!", @"eval rel:/relativeSchemeTests.txt");
}

+(void)testRelativeFileSchemeGETViaEvaluatedRef
{
    STCompiler *interpreter=[[[STCompiler alloc] init] autorelease];
    NSString *path = @"/tmp/relativeSchemeTests.txt";
    [@"hello world!" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    [interpreter evaluateScriptString:@"env:a :='tmp'. rel := ref:file:/{env:a} asScheme."];
    IDEXPECT([interpreter evaluateScriptString:@"(rel get:'/relativeSchemeTests.txt' parameters:nil) stringValue"] , @"hello world!", @"eval rel:/relativeSchemeTests.txt");
}

+(void)testWriteThrough
{
    STCompiler *interpreter = [self _testSchemeInterpreter:@"/"];
    IDEXPECT([interpreter evaluateScriptString:@"base:/"] , @"root", @"eval rel:/");
    IDEXPECT([interpreter evaluateScriptString:@"rel:/"] , @"root", @"eval rel:/");
    [interpreter evaluateScriptString:@"rel:/ := 'new root'"];
    IDEXPECT([interpreter evaluateScriptString:@"base:/"] , @"new root", @"eval base:/");
    IDEXPECT([interpreter evaluateScriptString:@"rel:/"] , @"new root", @"eval rel:/");
}

+(void)testRelativeWriteThrough
{
    STCompiler *interpreter = [self _testSchemeInterpreter:@"/subtree"];
//    [interpreter evaluateScriptString:@"scheme:rel setBaseIdentifier:'/subtree'"];
    IDEXPECT([interpreter evaluateScriptString:@"rel:/"] , @"subtree-content", @"eval rel:/");
    [interpreter evaluateScriptString:@"rel:/ := 'new subtree'"];
    IDEXPECT([interpreter evaluateScriptString:@"rel:/"] , @"new subtree", @"eval rel:/");
    IDEXPECT([interpreter evaluateScriptString:@"base:/subtree"] , @"new subtree", @"eval rel:/");
}

+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testBasicLookup",
            @"testRelativeLookup",
            @"testRelativeFileScheme",
            @"testRelativeFileSchemeGET",
            @"testWriteThrough",
            @"testRelativeWriteThrough",
//            @"testRelativeFileSchemeGETViaEvaluatedRef",
            nil];
}

@end
