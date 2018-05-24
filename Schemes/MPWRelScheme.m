//
//  MPWRelScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 5/10/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import "MPWRelScheme.h"
#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/MPWGenericReference.h>
#import "MPWIdentifier.h"
#import "MPWBinding.h"
#import "MPWGenericBinding.h"
#import "MPWVarScheme.h"

@implementation MPWRelScheme

objectAccessor( NSString, baseIdentifier, setBaseIdentifier )
objectAccessor( MPWBinding, baseRef, _setBaseRef)
idAccessor(storedContext, setStoredContext)

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
       to MPWBinding (and therefore all MPWBindings).
 
 
    Possibly need to go via the original binding (in case we have it, and some relative
    schemes will only work when done this way):  VAR-Ref has its context, with the context
    already used to get the base object (so it is this resolved base object that we need).
    So:  delegate to 
*/

-bindingWithIdentifier:anIdentifier withContext:aContext
{
    if ( !aContext ) {
        aContext=[self storedContext];
    }
    MPWBinding *binding=[super bindingWithIdentifier:anIdentifier withContext:aContext];
    [binding setScheme:[self source]];
    return binding;
}

-(NSString*)filteredPath:(NSString*)path
{
    return [[self baseIdentifier] stringByAppendingPathComponent:path];
}

-(MPWGenericReference*)filteredReference:(MPWGenericReference*)ref
{
    return [[ref class] referenceWithPath:[self filteredPath:[ref path]] ];
}

-bindingForName:anIdentifierName inContext:aContext
{
    if ( !aContext ) {
        aContext=[self storedContext];
    }
//    NSLog(@"combined name: '%@'",combinedPath);
    MPWIdentifier *newIdentifier=[MPWIdentifier identifierWithName:[self filteredPath:anIdentifierName]];
	return [[self source] bindingWithIdentifier:newIdentifier withContext:aContext];
}

-_baseBindingForBinding:(MPWGenericBinding*)aBinding
{
    //    NSLog(@"-[%@ valueForBinding: %@]",self,[aBinding path]);
    if (  [aBinding scheme] != [self source] ) {
        //        NSLog(@"modifying non var-scheme later");
        aBinding=(MPWGenericBinding*)[self bindingForName:[aBinding path] inContext:[aBinding defaultContext]];
    }
    //    MPWBinding *binding = [self bindingForName:[aBinding path] inContext:nil];
    return aBinding;
}

-(id)objectForReference:(id)aReference
{
    [[self source] objectForReference:[self filteredReference:aReference]];
//    return [[self _baseBindingForBinding:aBinding] value];
}

-(void)setObject:newValue forReference:aReference
{
    [[self source] setObject:newValue forReference:[self filteredReference:aReference]];
    //    NSLog(@"relative scheme valueForBinding: %@/%@ -> mapped binding: %@ -> value %@",
    //          aBinding,[aBinding name],aBinding,[aBinding value]);
}

-(void)setBaseRef:(MPWBinding *)aRef
{
    MPWBinding *resolved=[aRef bindNames];
	[self setSource:[resolved scheme]];
	[self setBaseIdentifier:[[resolved identifier] identifierName]];
    [self _setBaseRef:resolved];
}


-initWithBaseScheme:(MPWScheme*)aScheme baseURL:(NSString*)str
{
	self=[super init];
	[self setSource:aScheme];
	[self setBaseIdentifier:str];
	return self;
}

-initWithRef:(MPWBinding*)aBinding
{
    MPWBinding *resolved=[aBinding bindNames];
//    NSLog(@"initWithRef: %@",aBinding);
//    NSLog(@"binding value: %@",[aBinding value]);
    self = [self initWithBaseScheme:[resolved scheme] baseURL:[[resolved identifier] identifierName]];
    
    return self;
}

-(void)dealloc
{
	[baseIdentifier release];
    [baseRef release];
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

+(void)testWriteThrough
{
    MPWStCompiler *interpreter = [self _testSchemeInterpreter];
    IDEXPECT([interpreter evaluateScriptString:@"base:/"] , @"root", @"eval rel:/");
    IDEXPECT([interpreter evaluateScriptString:@"rel:/"] , @"root", @"eval rel:/");
    [interpreter evaluateScriptString:@"rel:/ := 'new root'"];
    IDEXPECT([interpreter evaluateScriptString:@"base:/"] , @"new root", @"eval base:/");
    IDEXPECT([interpreter evaluateScriptString:@"rel:/"] , @"new root", @"eval rel:/");
}

+(void)testRelativeWriteThrough
{
    MPWStCompiler *interpreter = [self _testSchemeInterpreter];
    [interpreter evaluateScriptString:@"scheme:rel setBaseIdentifier:'/subtree'"];
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
