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
#import <MPWFoundation/MPWFoundation.h>
#import <unistd.h>

@interface NSObject (workspaceMBethods)

+sharedWorkspace;
-(void)openURL:(NSURL*)url;

@end

@implementation MPWFileBinding


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

//-(void)startWatching
//{
//    [[self store] startWatching:self];
//}
//
//-(void)stopWatching
//{
//    
//}
//
//-(void)setDelegate:aDelegate
//{
//    [super setDelegate:aDelegate];
//    if ( aDelegate ) {
//        [self startWatching];
//    } else {
//        [self stopWatching];
//    }
//}



-(BOOL)existsAndIsDirectory:(BOOL*)isDirectory
{
	NSFileManager *manager=[NSFileManager defaultManager];
	return [manager fileExistsAtPath:[self path] isDirectory:isDirectory];;
}

-(BOOL)isBound
{
	return [self existsAndIsDirectory:NULL];;
}


-(NSDate *)lastModifiedDate
{
    NSDictionary *attributes=[[NSFileManager defaultManager] attributesOfItemAtPath:[self path] error:NULL];
    return attributes[NSFileModificationDate];
}

-(NSTimeInterval)lastModifiedTime
{
    return [[self lastModifiedDate] timeIntervalSinceReferenceDate];
}

-(BOOL)writeToURL:(NSURL*)targetURL atomically:(BOOL)atomically
{
    NSString *sourcePath=[self path];
    NSString *targetPath = [targetURL path];
    if ( sourcePath && targetPath ) {
        symlink([sourcePath fileSystemRepresentation], [targetPath fileSystemRepresentation]);
    }
    return YES;
}

-(NSString*)fancyPath
{
    if ( [self parentPath]) {
        long parentLength=[[self parentPath] length];
        if ( parentLength > 1 && ![[self parentPath] hasSuffix:@"/"]) {
            parentLength++;
        }
        return [[self path] substringFromIndex:parentLength];
    } else {
        return [[self path] lastPathComponent];
    }
}

-fileSystemValue
{
    return self;
}

-(id)value
{
//    NSLog(@"store: %@ ref: %@",self.store,self.reference);
    id value=[super value];
//    NSLog(@"value: %p, %@: %@",value,[value class],value);
    return value;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"file:%@",[self path]];
}

//-(void)mkdir          --- don't have -parent, so no sense to keep this
//{
//    if ( ![self isBound] ) {
//        [[self parent] mkdir];
//        [[NSFileManager defaultManager] createDirectoryAtPath:[self path] withIntermediateDirectories:YES attributes:nil error:nil];
//    }
//}

-(void)open
{
    [[NSClassFromString(@"NSWorkspace") sharedWorkspace] openURL:[self URL]];
}

// FIXME:  change notification should probably be delegated to the store/scheme handler

//-(void)didChange
//{
//    if ( !ignoreChanges) {
//        ignoreChanges=YES;
//        if (delegate && [self modifiedSinceLastWritten]) {
////            NSLog(@"%@ sending changed: to delegate:%p/%@/%@",[self class],delegate,[delegate class],delegate);
//            [[delegate onMainThread] changed:self];
////            NSLog(@"did send changed to delegate: %@",delegate);
//        }
//        ignoreChanges=NO;
//    }
//}


-(MPWFDStreamSource*)source
{
    return [MPWFDStreamSource name:[self path]];
}

-(MPWByteStream *)sink
{
    return [MPWByteStream fileName:[self path]];
}

@end

