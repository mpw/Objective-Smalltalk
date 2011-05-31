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
#import "MPWStCompiler.h"

@implementation MPWFileSchemeResolver(testing)


+(void)testGettingASimpleFile
{
	NSString *tempUrlString = @"file:/tmp/fileSchemeTest.txt";
	NSString *textString = @"hello world!";
	[textString writeToURL:[NSURL URLWithString:tempUrlString] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	IDEXPECT([[MPWStCompiler evaluate:tempUrlString] stringValue],textString, @"get test file");
}


+testSelectors
{
	return [NSArray arrayWithObjects:
			@"testGettingASimpleFile",
			nil];
}


@end

