//
//  MPWSchemeFilesystem.m
//  Arch-S
//
//  Created by Marcel Weiher on 11/3/11.
//  Copyright (c) 2012 Marcel Weiher. All rights reserved.
//

#import "MPWSchemeFilesystem.h"
#import <OSXFUSE/OSXFUSE.h>
#import <ObjectiveSmalltalk/MPWScheme.h>
#import <ObjectiveSmalltalk/MPWFileSchemeResolver.h>
#import <MPWFoundation/MPWFoundation.h>

static NSString *helloPath = @"/hello.txt";

@interface MPWSchemeFilesystem()

@property (nonatomic,strong) GMUserFileSystem *filesystem;

@end


@implementation MPWBinding(childNames)

-childNames
{
    return [[[[[self children] collect] reference] collect] path];
}

@end


@implementation MPWSchemeFilesystem


-(id)initWithScheme:newScheme
{
    self = [super init];
    [self setScheme:newScheme];
    self.filesystem = [[[GMUserFileSystem alloc] initWithDelegate:self isThreadSafe:NO] autorelease];
    return self;
}


-(id)init
{
    return [self initWithScheme:[[[MPWFileSchemeResolver alloc] init] autorelease]];
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
    NSLog(@"dir: %@",path);
    id names = nil;
    @try {
        names = [[self scheme] childrenOfReference:path];
        names = [[names collect] stringByReplacingOccurrencesOfString:@":" withString:@"_"];
//        names = [[names collect] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    } @catch (id e) {
        
    }
    NSLog(@"dir contents: %@",names);
    return names;
}

- (NSData *)contentsAtPath:(NSString *)path {
    NSLog(@"contents of %@: '%@'",path,[[self scheme] at:path]);
    @try {
        return [[[self scheme] at:path] asData];
    } @catch ( id e) {
        return nil;
    }
}

#pragma optional Custom Icon



- (NSDictionary *)finderAttributesAtPath:(NSString *)path 
                                   error:(NSError **)error {
//    if ([path isEqualToString:helloPath]) {
//        NSNumber* finderFlags = [NSNumber numberWithLong:kHasCustomIcon];
//        return [NSDictionary dictionaryWithObject:finderFlags
//                                           forKey:kGMUserFileSystemFinderFlagsKey];
//    }
    return nil;
}

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path
                                userData:(id)userData
                                   error:(NSError **)error {
//    NSLog(@"attributesOfItemAtPath: %@",path);
//    NSLog(@"binding: %@ hasChildren: %d",binding,[binding hasChildren]);
    if ( [[self scheme] hasChildren:path] ) {
        NSLog(@"%@ is directory",path);
        return [NSDictionary dictionaryWithObject:NSFileTypeDirectory forKey:NSFileType];
    } else {
        NSLog(@"%@ is file ",path);
        return  @{NSFileType: NSFileTypeRegular,
                  NSFilePosixPermissions: @(4*8*8)
                  } ;
    }
}



- (NSDictionary *)resourceAttributesAtPath:(NSString *)path
                                     error:(NSError **)error {
//        NSLog(@"get resource attrs: %@",path);
//    if ([path isEqualToString:helloPath]) {
//        NSString *file = [[NSBundle mainBundle] pathForResource:@"hellodoc" ofType:@"icns"];
//        return [NSDictionary dictionaryWithObject:[NSData dataWithContentsOfFile:file]
//                                           forKey:kGMUserFileSystemCustomIconDataKey];
//    }
    return nil;
}

-(void)unmount {
    [_filesystem unmount];
}

-(void)mountAt:(NSString*)mountPath
{
    [self.filesystem mountAtPath:[mountPath path] withOptions:@[@"direct_io"]];
}

-(void)dealloc
{
    [_filesystem release];
    [_scheme release];
    [super dealloc];
}

@end


@implementation MPWAbstractStore(mounting)

-(MPWSchemeFilesystem*)mountAt:(NSString*)mountPath
{
    MPWSchemeFilesystem *fs=[[[MPWSchemeFilesystem alloc] initWithScheme:self] autorelease];
    [fs mountAt:mountPath];
    return fs;
}

@end
