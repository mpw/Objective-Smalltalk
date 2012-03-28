//
//  MPWBundleScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 5/28/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import "MPWBundleScheme.h"
#import "MPWStCompiler.h"
#import <MPWFoundation/AccessorMacros.h>

@implementation MPWBundleScheme

objectAccessor( NSBundle, bundle ,setBundle )

+schemeWithBundle:(NSBundle*)aBundle
{
	return [[[self alloc] initWithBundle:aBundle] autorelease];
}

+mainBundleScheme
{
	return [self schemeWithBundle:[NSBundle mainBundle]];
}

+classBundleScheme:(Class)aClass
{
	return [self schemeWithBundle:[NSBundle bundleForClass:aClass]];
}

-initWithBundle:(NSBundle*)aBundle
{
	self=[super init];
	[self setBundle:aBundle];
	return self;
}

-init
{
	return [self initWithBundle:[NSBundle bundleForClass:[self class]]];
}

-bindingForName:aName inContext:aContext
{
	NSString *path = [[self bundle] pathForResource:[aName stringByDeletingPathExtension] ofType:[aName pathExtension]];				  
	//	id binding = [MPWBinding bindingWithValue:[NSString stringWithContentsOfFile:aName]];
	return [super bindingForName:path inContext:aContext];
}



@end

@implementation MPWBundleScheme(testing)


+(void)testGettingASimpleFile
{
	chdir("/");
	IDEXPECT( [[MPWStCompiler evaluate:@"bundle:testfile.txt"] stringValue], @"this is a test file", @"geting testfile.txt");
}


+testSelectors
{
	return [NSArray arrayWithObjects:
			@"testGettingASimpleFile",
			nil];
}


@end
