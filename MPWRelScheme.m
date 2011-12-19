//
//  MPWRelScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 5/10/11.
//  Copyright 2011 metaobject ltd. All rights reserved.
//

#import "MPWRelScheme.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWIdentifier.h"
#import "MPWBinding.h"

@implementation MPWRelScheme

objectAccessor( MPWScheme, baseScheme, setBaseScheme )
objectAccessor( NSString, baseIdentifier, setBaseIdentifier )

-bindingForName:anIdentifierName inContext:aContext
{
	return [[self baseScheme] bindingForName:[[self baseIdentifier] stringByAppendingPathComponent:anIdentifierName] inContext:aContext];
}

//  FIXME
-valueForBinding:aBinding
{
    MPWBinding *binding = [self bindingForName:[aBinding path] inContext:nil];
//    NSLog(@"relative scheme valueForBinding: %@/%@ -> mapped binding: %@/%@ -> value %@",
  //        aBinding,[aBinding path],binding,[binding path],[binding value]);
    return [binding value];
}

-initWithBaseScheme:(MPWScheme*)aScheme baseURL:(NSString*)str
{
	self=[super init];
	[self setBaseScheme:aScheme];
	[self setBaseIdentifier:str];
	return self;
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


+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testBasicLookup",
            @"testRelativeLookup",
            @"testRelativeFileScheme",
            nil];
}

@end