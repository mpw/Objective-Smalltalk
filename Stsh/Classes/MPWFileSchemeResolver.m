//
//  MPWFileSchemeResolver.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/7/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "MPWFileSchemeResolver.h"
#import "MPWFileBinding.h"

@implementation MPWFileSchemeResolver

-bindingForName:aName inContext:aContext
{
//	id binding = [MPWBinding bindingWithValue:[NSString stringWithContentsOfFile:aName]];
	id binding = [[[MPWFileBinding alloc] initWithPath:aName] autorelease];
	return binding;
}


@end
#import "MPWStsh.h"

@implementation MPWFileSchemeResolver(testing)


+(void)testGettingASimpleFile
{
	id shell=[[[MPWStsh alloc] init] autorelease];
	NSBundle* bundle = [NSBundle bundleForClass:self];
	id resourcesDirectory = [bundle resourcePath];
	id expr,result;
	[shell cd:resourcesDirectory];
	expr = [[shell evaluator] compile:@"file:testfile.txt ."];
	result = [[shell evaluator] executeShellExpression:expr];
	IDEXPECT( [result stringValue], @"this is a test file", @"result of file:testfile.txt");
}



+testSelectors
{
	return [NSArray arrayWithObjects:
			@"testGettingASimpleFile",
			nil];
}


@end

