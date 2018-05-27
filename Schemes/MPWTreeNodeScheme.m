//
//  MPWTreeNodeScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/23/11.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "MPWTreeNodeScheme.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWTreeNode.h"
#import "MPWGenericBinding.h"
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

-nodeFoBinding:(MPWGenericBinding*)aBinding
{
    return [self nodeForPath:[[aBinding reference] relativePathComponents]];
}

-contentForPath:(NSArray*)array
{
	return [[self nodeForPath:array] content];
}

-(id)objectForReference:(MPWGenericReference*)aReference
{
    return [[self nodeForPath:[aReference relativePathComponents]] content];
}

-(void)setObject:newValue forReference:aReference
{
    NSArray *pathArray=[aReference relativePathComponents];
    MPWTreeNode *node=[self nodeForPath:pathArray];
    if ( !node ) {
        node = [[self root] mkdirs:[pathArray objectEnumerator]];
    }
    [node setContent:newValue];
}


-(BOOL)hasChildren:(MPWGenericBinding*)binding
{
    return [[self nodeFoBinding:binding] hasChildren];
}

-childWithName:(NSString*)name of:(MPWGenericBinding*)binding
{
    return [[self nodeFoBinding:binding] childWithName:name];
}

-(NSArray*)childrenOf:(MPWGenericBinding*)binding
{
    return [[self nodeFoBinding:binding] children];
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
    [interpreter evaluateScriptString:@" site := MPWTreeNodeScheme scheme."];
    [interpreter evaluateScriptString:@" scheme:cms := site "];
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

+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testRead",
            @"testWrite",
            @"testStripLeadingSlashesFromPathsInReadAndWrite",
            nil];
}

@end
