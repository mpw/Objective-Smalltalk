//
//  MPWRelScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 5/10/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import "MPWRelScheme.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWIdentifier.h"
#import "MPWBinding.h"
#import "MPWGenericBinding.h"
#import "MPWVarScheme.h"

@implementation MPWRelScheme

objectAccessor( MPWScheme, baseScheme, setBaseScheme )
objectAccessor( NSString, baseIdentifier, setBaseIdentifier )

/*
   FIXME!!
 
   Different kinds of source schemes/bindings need to be adjusted at different times.
 
   GenericBindings only start evaluating their identifiers at valueForBinding: time,
   so the path adjustment needs to be done then.  (Or rather:  some other scheme
   may have created the binding, in which case we only find out about it at valueForBinding:
   time and thus didn't have the opportunity to adjust the path during creation).
 
   However, that's too late for var: bindings and evaluation of embedded expressions
     (for example  {env:HOME} because at valueForBinding: time there is no context,
     and the context is required to evaluat these.
 
   Not entirely sure how to fix this (might go away if I do away with GenericBindings?)
   Alternatively:   keep the context around for later.

 
   Also:  this problem only started manifesting itself when I added storing the scheme
       to MPWBinding (and therefore all MPWBindings).  That probably 
*/

-bindingWithIdentifier:anIdentifier withContext:aContext
{
    MPWBinding *binding=[super bindingWithIdentifier:anIdentifier withContext:aContext];
    [binding setScheme:[self baseScheme]];
    return binding;
}
    
-bindingForName:anIdentifierName inContext:aContext
{
    NSString *combinedPath= [[self baseIdentifier] stringByAppendingPathComponent:anIdentifierName];
//    NSLog(@"combined name: '%@'",combinedPath);
    MPWIdentifier *newIdentifier=[[[MPWIdentifier alloc] init] autorelease];
    [newIdentifier setSchemeName:nil];
    [newIdentifier setIdentifierName:combinedPath];
	return [[self baseScheme] bindingWithIdentifier:newIdentifier withContext:aContext];
}

//  FIXME
-valueForBinding:aBinding
{
//    NSLog(@"-[%@ valueForBinding: %@]",self,[aBinding path]);
    if (  [aBinding scheme] != [self baseScheme] ) {
//        NSLog(@"modifying non var-scheme later");
        aBinding=[self bindingForName:[aBinding path] inContext:[aBinding defaultContext]];
    }
//    MPWBinding *binding = [self bindingForName:[aBinding path] inContext:nil];
//    NSLog(@"relative scheme valueForBinding: %@/%@ -> mapped binding: %@ -> value %@",
//          aBinding,[aBinding name],aBinding,[aBinding value]);
    return [aBinding value];
}

-initWithBaseScheme:(MPWScheme*)aScheme baseURL:(NSString*)str
{
	self=[super init];
	[self setBaseScheme:aScheme];
	[self setBaseIdentifier:str];
	return self;
}

-initWithRef:(MPWBinding*)aBinding
{
    MPWBinding *resolved=[aBinding bindNames];
    return [self initWithBaseScheme:[resolved scheme] baseURL:[[resolved identifier] identifierName]];
}

-(void)dealloc
{
	[baseScheme release];
	[baseIdentifier release];
	[super dealloc];
}

@end

#import "MPWStCompiler.h"

@implementation MPWRelScheme(testing)

+_testSchemeInterpreter
{
    MPWStCompiler *interpreter=[[[MPWStCompiler alloc] init] autorelease];
    [interpreter evaluateScriptString:@"scheme:base := MPWTreeNodeScheme scheme."];
    [interpreter evaluateScriptString:@"scheme:rel := MPWRelScheme alloc initWithBaseScheme: scheme:base baseURL:'/'."];
    [interpreter evaluateScriptString:@"base:/ := 'root' "];
    [interpreter evaluateScriptString:@"base:/subtree := 'subtree-content' "];
    return interpreter;
}

+(void)testBasicLookup
{
    MPWStCompiler *interpreter = [self _testSchemeInterpreter];
    IDEXPECT([interpreter evaluateScriptString:@"base:/"] , @"root", @"eval rel:/");
    IDEXPECT([interpreter evaluateScriptString:@"rel:/"] , @"root", @"eval rel:/");
}

+(void)testRelativeLookup
{
    MPWStCompiler *interpreter = [self _testSchemeInterpreter];
    [interpreter evaluateScriptString:@"scheme:rel setBaseIdentifier:'/subtree'"];
    IDEXPECT([interpreter evaluateScriptString:@"rel:/"] , @"subtree-content", @"eval rel:/");
}

+(void)testRelativeFileScheme
{
    MPWStCompiler *interpreter=[[[MPWStCompiler alloc] init] autorelease];
    NSString *path = @"/tmp/relativeSchemeTests.txt";
    [@"hello world!" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [interpreter evaluateScriptString:@"scheme:rel := MPWRelScheme alloc initWithBaseScheme: scheme:file baseURL:'/tmp'."];
    IDEXPECT([interpreter evaluateScriptString:@"rel:/relativeSchemeTests.txt stringValue"] , @"hello world!", @"eval rel:/relativeSchemeTests.txt");
}

+(void)testRelativeFileSchemeGET
{
    MPWStCompiler *interpreter=[[[MPWStCompiler alloc] init] autorelease];
    NSString *path = @"/tmp/relativeSchemeTests.txt";
    [@"hello world!" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    id rel=[interpreter evaluateScriptString:@"MPWRelScheme alloc initWithBaseScheme: scheme:file baseURL:'/tmp'."];
    IDEXPECT([[rel get:@"/relativeSchemeTests.txt" parameters:nil] stringValue] , @"hello world!", @"eval rel:/relativeSchemeTests.txt");
}

+(void)testRelativeFileSchemeGETViaEvaluatedRef
{
    MPWStCompiler *interpreter=[[[MPWStCompiler alloc] init] autorelease];
    NSString *path = @"/tmp/relativeSchemeTests.txt";
    [@"hello world!" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [interpreter evaluateScriptString:@"env:a :='tmp'. rel := ref:file:/{env:a} asScheme."];
    IDEXPECT([interpreter evaluateScriptString:@"(rel get:'/relativeSchemeTests.txt' parameters:nil) stringValue"] , @"hello world!", @"eval rel:/relativeSchemeTests.txt");
}


+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testBasicLookup",
            @"testRelativeLookup",
            @"testRelativeFileScheme",
            @"testRelativeFileSchemeGET",
//            @"testRelativeFileSchemeGETViaEvaluatedRef",
            nil];
}

@end