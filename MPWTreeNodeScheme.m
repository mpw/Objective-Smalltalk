//
//  MPWTreeNodeScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/23/11.
//  Copyright (c) 2011 metaobject ltd. All rights reserved.
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

-(NSArray*)pathArrayForPathString:(NSString*)uri
{
	NSArray *pathArray = [super pathArrayForPathString:uri];
    if ( [pathArray count] > 1 && [[pathArray objectAtIndex:0] length] == 0 ) {
        pathArray=[pathArray subarrayWithRange:NSMakeRange(1, [pathArray count]-1)];
    }
    return pathArray;
}


-nodeForPath:(NSArray*)pathArray
{
    return [root nodeForPathEnumerator:[pathArray objectEnumerator]];
}

-contentForPath:(NSArray*)array
{
	return [[self nodeForPath:array] content];
}


-valueForBinding:(MPWGenericBinding*)aBinding
{
    NSString *uri=[aBinding name];
    return [self contentForURI:uri];
}

-(void)setValue:newValue forBinding:(MPWGenericBinding*)aBinding
{
    NSArray *pathArray=[self pathArrayForPathString:[aBinding name]];
    MPWTreeNode *node=[self nodeForPath:pathArray];
    if ( !node ) {
        node = [[self root] mkdirs:[pathArray objectEnumerator]];
    }
    [node setContent:newValue];
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
    NSString *result=@"";
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
    NSString *result=@"";
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
