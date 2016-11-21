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
#import "MPWDirectoryBinding.h"

@interface NSObject (workspaceMBethods)

+sharedWorkspace;
-(void)openURL:(NSURL*)url;

@end

@implementation MPWFileBinding

idAccessor( url , setUrl )


-(NSTimeInterval)lastWritten
{
    return lastWritten;
}

-(NSTimeInterval)lastRead
{
    return lastRead;
}

-(BOOL)modifiedSinceLastWritten
{
    return [self lastModifiedTime] > [self lastWritten];
}

-(BOOL)modifiedSinceLastRead
{
    return [self lastModifiedTime] > [self lastRead];
}

-initWithURL:(NSURL*)newURL
{
	self=[super initWithValue:nil];
	[self setUrl:newURL];
	return self;
}

-(void)startWatching
{
    [[self scheme] startWatching:self];
}

-(void)stopWatching
{
    
}

-(void)setDelegate:aDelegate
{
    [super setDelegate:aDelegate];
    if ( aDelegate ) {
        [self startWatching];
    } else {
        [self stopWatching];
    }
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

-childWithName:(NSString*)newName
{
    return [[[[self class] alloc] initWithPath:[[self fileSystemPath] stringByAppendingPathComponent:newName]] autorelease];
}

-(NSArray*)children
{
    NSArray *childEntries=nil;
    if ( [self hasChildren] ) {
        NSArray *childNames = [self directoryContents];
        childEntries = [[self collect] childWithName:[childNames each]];
    } else {
        childEntries = [NSArray array];
    }
    return childEntries;
}

-(NSArray*)childNames
{
    return [self directoryContents];
}

-_valueWithDataURL:(NSURL*)aURL
{
    NSError *error=nil;
	NSData *rawData = [NSData dataWithContentsOfURL:aURL  options:NSDataReadingMapped error:&error];
	MPWResource *result=[[[MPWResource alloc] init] autorelease];
	[result setSource:aURL];
	[result setRawData:rawData];
    [result setError:error];
    lastRead=[NSDate timeIntervalSinceReferenceDate];
	return result;
}


-_valueWithURL:(NSURL*)aURL
{
    lastRead=[NSDate timeIntervalSinceReferenceDate];
    if ( [self hasChildren] ) {
        MPWDirectoryBinding * result = [[[MPWDirectoryBinding alloc] initWithContents:[self children]] autorelease];
        [result setIdentifier:[self identifier]];
        return result;
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
    lastWritten=[NSDate timeIntervalSinceReferenceDate];
}

-(NSDate *)lastModifiedDate
{
    NSDictionary *attributes=[[NSFileManager defaultManager] attributesOfItemAtPath:[self path] error:nil];
    return attributes[NSFileModificationDate];
}

-(NSTimeInterval)lastModifiedTime
{
    return [[self lastModifiedDate] timeIntervalSinceReferenceDate];
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
			return [[[[self class] alloc] initWithPath:newPath] autorelease];
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

-(void)open
{
    [[NSClassFromString(@"NSWorkspace") sharedWorkspace] openURL:[self url]];
}


-(void)didChange
{
    if ( !ignoreChanges) {
        ignoreChanges=YES;
        if (delegate) {
            NSLog(@"%@ sending changed: to delegate:%p/%@/%@",[self class],delegate,[delegate class],delegate);
            [delegate changed:self];
            NSLog(@"did send changed to delegate: %@",delegate);
        }
        ignoreChanges=NO;
    }
}


-(void)dealloc
{
	[url release];
	[super dealloc];
}


@end

