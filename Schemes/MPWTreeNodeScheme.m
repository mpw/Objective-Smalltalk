//
//  MPWTreeNodeScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/23/11.
//  Copyright (c) 2012 Marcel Weiher. All rights reserved.
//

#import "MPWTreeNodeScheme.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWTreeNode.h"
#import "MPWStCompiler.h"

@implementation MPWTreeNodeScheme

idAccessor( root, setRoot )

-init
{
	self = [super init];
	[self setRoot:[MPWTreeNode root]];
	return self;
}

-nodeForPath:(NSArray*)pathArray
{
    return [root nodeForPathEnumerator:[pathArray objectEnumerator]];
}

-nodeForReference:(MPWGenericReference*)aReference
{
    return [self nodeForPath:[aReference relativePathComponents]];
}

-(id)at:(MPWGenericReference*)aReference
{
    return [[self nodeForReference:aReference] content];
}

-(void)at:aReference put:newValue 
{
    NSArray *pathArray=[aReference relativePathComponents];
    MPWTreeNode *node=[self nodeForPath:pathArray];
    if ( !node ) {
        node = [[self root] mkdirs:[pathArray objectEnumerator]];
    }
    [node setContent:newValue];
}

-get:(NSString*)uriString parameters:uriParameters
{
    return [root nodeForPathComponent:uriString];
}


-(BOOL)isLeafReference:(MPWGenericReference *)aReference
{
    return ![[self nodeForReference:aReference] hasChildren];
}

-(NSArray*)childrenOfReference:(MPWGenericReference*)aReference
{
    return [[self nodeForPath:[aReference relativePathComponents]] children];
}

-(void)dealloc
{
	[root release];
	[super dealloc];
}

@end

@implementation MPWTreeNodeScheme(testing)

+_testInterpreterWithCMSScheme
{
    MPWStCompiler *interpreter=[[MPWStCompiler new] autorelease];
    [interpreter evaluateScriptString:@" site := MPWTreeNodeScheme scheme. scheme:cms := site."];
    return interpreter;
}

+(void)testRead
{
    MPWStCompiler *interpreter=[self _testInterpreterWithCMSScheme];
    NSString *result=@"";
   [interpreter evaluateScriptString:@" site  root setContent:'Hello World'."];
    result = [interpreter evaluateScriptString:@"cms:/ "];
    IDEXPECT(result, @"Hello World", @"result of evaluating root");
    result = [interpreter evaluateScriptString:@"cms:/hi"];
    EXPECTNIL(result, @"cms:/hi should not exist");
}

+(void)testWrite
{
    MPWStCompiler *interpreter=[self _testInterpreterWithCMSScheme];
    NSString *result=@"";
    [interpreter evaluateScriptString:@"cms:/ := 'Hello World'"];
    result = [interpreter evaluateScriptString:@" site root content "];
    IDEXPECT(result, @"Hello World", @"result of evaluating root");
    [interpreter evaluateScriptString:@"cms:hi := 'Hi there!'"];
    result = [interpreter evaluateScriptString:@"cms:/hi"];
    IDEXPECT(result, @"Hi there!", @"result of evaluating root");
}

+(void)testStripLeadingSlashesFromPathsInReadAndWrite
{
    MPWStCompiler *interpreter=[self _testInterpreterWithCMSScheme];
    [interpreter evaluateScriptString:@"cms:/hi := 'Hi there!'"];
    IDEXPECT([interpreter evaluateScriptString:@"cms:/hi"], @"Hi there!", @"result of evaluating /hi");
    IDEXPECT([interpreter evaluateScriptString:@"cms:hi"], @"Hi there!", @"result of evaluating hi");
    [interpreter evaluateScriptString:@"cms:hi := 'Hello there!'"];
    IDEXPECT([interpreter evaluateScriptString:@"cms:/hi"], @"Hello there!", @"result of evaluating /hi");
    IDEXPECT([interpreter evaluateScriptString:@"cms:hi"], @"Hello there!", @"result of evaluating hi");
}

+(void)testLeafHasNoChildren
{
    MPWTreeNodeScheme *site=[self store];
    id <MPWReferencing> ref=[site referenceForPath:@"hello"];
    site[ref]=@"world";
    MPWBinding *binding=[site bindingForReference:ref inContext:nil];
    IDEXPECT( ref, binding.reference, @"binding has same ref");
    IDEXPECT( site[ref], @"world", @"store get");
    IDEXPECT( [binding value], @"world", @"binding value");
    EXPECTFALSE([binding hasChildren], @"children of binding");
}



+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testRead",
            @"testWrite",
            @"testStripLeadingSlashesFromPathsInReadAndWrite",
            @"testLeafHasNoChildren",
            nil];
}

@end
