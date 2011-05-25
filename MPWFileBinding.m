//
//  MPWFileBinding.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/11/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "MPWFileBinding.h"
#import <MPWFoundation/AccessorMacros.h>

@implementation MPWFileBinding

idAccessor( url , setUrl )

-initWithURL:(NSURL*)newURL
{
	self=[super initWithValue:nil];
	[self setUrl:newURL];
	return self;
}

-initWithPath:(NSString*)path
{
	return [self initWithURL:[NSURL fileURLWithPath:path]];
}

-initWithURLString:(NSString*)urlString
{
	return [self initWithURL:[NSURL URLWithString:urlString]];
}


-(BOOL)isBound
{
	return YES;
}

-_valueWithURL:(NSURL*)aURL
{
	NSFileManager *manager=[NSFileManager defaultManager];
	NSString *path=[aURL path];
	BOOL isDirectory=NO;
	if (  [manager fileExistsAtPath:path isDirectory:&isDirectory]) {
		if ( isDirectory ) {
			return [manager contentsOfDirectoryAtPath:path error:nil];
		} else {
			return [NSData dataWithContentsOfURL:aURL];
		}
	}
	return nil;
}

-_value
{
	return [self _valueWithURL:[self url]];
}

-(void)_setValue:newValue
{
	if ( [newValue isKindOfClass:[MPWBinding class]] ) {
		newValue=[newValue value];
	}
	[newValue writeToURL:[self url] atomically:YES];
}

-(void)dealloc
{
//	[url release];			// FIXME:  this should be released, but that causes a double-release crash
	[super dealloc];
}


@end
