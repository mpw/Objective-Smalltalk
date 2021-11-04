//
//  MPWTreeNodeScheme.m
//  Arch-S
//
//  Created by Marcel Weiher on 11/23/11.
//  Copyright (c) 2012 Marcel Weiher. All rights reserved.
//

#import "MPWTreeNodeScheme.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWTreeNode.h"
#import "STCompiler.h"

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
    MPWTreeNode *node = [self nodeForReference:aReference];
    id content = [node content];
    return content;
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


-(BOOL)hasChildren:(MPWGenericReference *)aReference
{
    return [[self nodeForReference:aReference] hasChildren];
}

-(NSArray*)childrenOfReference:(MPWGenericReference*)aReference
{
    return [[[[[[self nodeForPath:[aReference relativePathComponents]] children] collect] path] collect] lastPathComponent];
}

-(void)traverse:(id <Streaming>)target
{
    [[self root] traverse:target];
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
    STCompiler *interpreter=[[STCompiler new] autorelease];
    [interpreter evaluateScriptString:@" site := MPWTreeNodeScheme scheme. scheme:cms := site."];
    return interpreter;
}

+(void)testRead
{
    STCompiler *interpreter=[self _testInterpreterWithCMSScheme];
    NSString *result=@"";
   [interpreter evaluateScriptString:@" site  root setContent:'Hello World'."];
    result = [interpreter evaluateScriptString:@"cms:/ "];
    IDEXPECT(result, @"Hello World", @"result of evaluating root");
    result = [interpreter evaluateScriptString:@"cms:/hi"];
    EXPECTNIL(result, @"cms:/hi should not exist");
}

+(void)testWrite
{
    STCompiler *interpreter=[self _testInterpreterWithCMSScheme];
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
    STCompiler *interpreter=[self _testInterpreterWithCMSScheme];
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

+_testInterpreterWithNestedContent
{
    STCompiler *interpreter=[self _testInterpreterWithCMSScheme];
    [interpreter evaluateScriptString:@"cms:/ := 'Hello World'"];
    [interpreter evaluateScriptString:@"cms:hi := 'Hi there!'"];
    [interpreter evaluateScriptString:@"cms:hi/answer := '42'"];

    return interpreter;
}

+(void)testNestedContent
{
    STCompiler *interpreter=[self _testInterpreterWithNestedContent];
    IDEXPECT(([interpreter evaluateScriptString:@" site root content "]), @"Hello World", @"result of evaluating root");
    IDEXPECT(([interpreter evaluateScriptString:@"cms:/hi"]), @"Hi there!", @"result of evaluating root");
    IDEXPECT(([interpreter evaluateScriptString:@"cms:/hi/answer"]), @"42", @"result of evaluating root");
}

+(void)testTraversal
{
    STCompiler *interpreter=[self _testInterpreterWithNestedContent];
    NSMutableArray *allRefs=[NSMutableArray array];
    [interpreter bindValue:allRefs toVariableNamed:@"allRefs"];
    [interpreter evaluateScriptString:@"site traverse:allRefs."];
    INTEXPECT( allRefs.count, 3,@"number of nodes");
    IDEXPECT( [[allRefs firstObject] path], @"/", @"root");
    IDEXPECT( [allRefs[1] path], @"/hi", @"/hi");
    IDEXPECT( [allRefs[2] path], @"/hi/answer", @"/hi/answer");
}

+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testRead",
            @"testWrite",
            @"testStripLeadingSlashesFromPathsInReadAndWrite",
            @"testLeafHasNoChildren",
            @"testNestedContent",
            @"testTraversal",
            nil];
}

@end
