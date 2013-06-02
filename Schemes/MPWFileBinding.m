//
//  MPWFileBinding.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/11/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "MPWFileBinding.h"
#import <MPWFoundation/AccessorMacros.h>
#import "MPWURLBinding.h"
#import "MPWResource.h"

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

-(NSString*)fileSystemPath
{
	return [[self url] path];
}

-path
{
    return [self fileSystemPath];
}

-(BOOL)existsAndIsDirectory:(BOOL*)isDirectory
{
	NSFileManager *manager=[NSFileManager defaultManager];
	return [manager fileExistsAtPath:[self fileSystemPath] isDirectory:isDirectory];;
}

-(BOOL)isBound
{
	return [self existsAndIsDirectory:NULL];;
}

-(BOOL)isDirectory
{
	BOOL isDirectory = NO;
	return [self existsAndIsDirectory:&isDirectory] && isDirectory;
}

-(BOOL)hasChildren
{
    return [self isDirectory];
}

-(NSArray*)directoryContents
{
	return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self fileSystemPath] error:nil];
    
}

-childWithName:(NSString*)name
{
    return [[[[self class] alloc] initWithPath:[[self fileSystemPath] stringByAppendingPathComponent:name]] autorelease];
}

-(NSArray*)children
{
    if ( [self hasChildren] ) {
        NSArray *childNames = [self directoryContents];
        return [[self collect] childWithName:[childNames each]];
    } else {
        return [NSArray array];
    }
}

-(NSArray*)childNames
{
    return [self directoryContents];
}

-_valueWithDataURL:(NSURL*)aURL
{
    NSError *error=nil;
	NSData *rawData = [NSData dataWithContentsOfURL:aURL  options:NSDataReadingMappedAlways error:&error];
	MPWResource *result=[[[MPWResource alloc] init] autorelease];
	[result setSource:aURL];
	[result setRawData:rawData];
    [result setError:error];
	return result;
}


-_valueWithURL:(NSURL*)aURL
{
    if ( [self hasChildren] ) {
        return [self directoryContents];
    } else {
        return [self _valueWithDataURL:aURL];
    }
}

-_value
{
	return [self _valueWithURL:[self url]];
}

-(void)_setValue:newValue
{
 	if ( [newValue isKindOfClass:[MPWBinding class]] ) {
        newValue=[newValue fileSystemValue];
	}
    [[self parent] mkdir];
	[newValue writeToURL:[self url] atomically:YES];
}

-(BOOL)writeToURL:(NSURL*)targetURL atomically:(BOOL)atomically
{
    NSString *sourcePath=[self fileSystemPath];
    NSString *targetPath = [targetURL path];
    if ( sourcePath && targetPath ) {
        symlink([sourcePath fileSystemRepresentation], [targetPath fileSystemRepresentation]);
    }
    return YES;
}

-fileSystemValue
{
    return self;
}

-(MPWFileBinding*)with:otherPath
{
	NSString *selfPath = [self fileSystemPath];
	NSString *newPath = nil;
	if ( [self isDirectory] ) {
		if ( selfPath && otherPath ) {
			if ( [otherPath isEqual:@".."] ) {
				newPath=[selfPath stringByDeletingLastPathComponent];
			} else {
				newPath=[selfPath stringByAppendingPathComponent:otherPath];
			}
			return [[[self class] alloc] initWithPath:newPath];
		}
	}
	return nil;
}

-parent
{
    return [[[[self class] alloc] initWithPath:[[self fileSystemPath] stringByDeletingLastPathComponent]] autorelease];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"file:%@",[self fileSystemPath]];
}

-(void)mkdir
{
	if ( ![self isBound] ) {
        [[self parent] mkdir];
		[[NSFileManager defaultManager] createDirectoryAtPath:[self fileSystemPath] withIntermediateDirectories:YES attributes:nil error:nil];
	}
}

-(void)dealloc
{
	[url release];			// FIXME:  this should be released, but that causes a double-release crash
	[super dealloc];
}


@end
