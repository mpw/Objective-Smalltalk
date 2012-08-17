//
//  MPWSchemeFilesystem.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/3/11.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "MPWSchemeFilesystem.h"
#import <OSXFUSE/OSXFUSE.h>
#import <ObjectiveSmalltalk/MPWScheme.h>
#import <ObjectiveSmalltalk/MPWFileSchemeResolver.h>
#import <MPWFoundation/MPWFoundation.h>

static NSString *helloStr = @"Hello Brave New World!\n";
static NSString *helloPath = @"/hello.txt";

@implementation MPWSchemeFilesystem

objectAccessor(MPWScheme, scheme, setScheme)

-(id)init
{
    self = [super init];
    [self setScheme:[[[MPWFileSchemeResolver alloc] init] autorelease]];
    return self;
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
    NSLog(@"get directory: %@",path);
    //    return [NSArray arrayWithObject:@"hello.txt"];
    id v = [[[self scheme] bindingForName:path inContext:nil] value];
    NSLog(@"class %@, value: %@",[v class],v);
    return v;
}

- (NSData *)contentsAtPath:(NSString *)path {
    NSLog(@"get file: %@",path);
    return [@"hello world!" asData];
    //    [[[self scheme] bindingForName:path inContext:nil] value];
}

#pragma optional Custom Icon



- (NSDictionary *)finderAttributesAtPath:(NSString *)path 
                                   error:(NSError **)error {
    NSLog(@"get finder attributes: %@",path);
    if ([path isEqualToString:helloPath]) {
        NSNumber* finderFlags = [NSNumber numberWithLong:kHasCustomIcon];
        return [NSDictionary dictionaryWithObject:finderFlags
                                           forKey:kGMUserFileSystemFinderFlagsKey];
    }
    return nil;
}

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path
                                userData:(id)userData
                                   error:(NSError **)error {
    id v = [[self scheme] bindingForName:path inContext:nil];
    if ( [v hasChildren] ) {
        return [NSDictionary dictionaryWithObject:NSFileTypeDirectory forKey:NSFileType];
    } else {
        return [NSDictionary dictionaryWithObject:NSFileTypeRegular forKey:NSFileType];
    }
}



- (NSDictionary *)resourceAttributesAtPath:(NSString *)path
                                     error:(NSError **)error {
    NSLog(@"get resource attrs: %@",path);
    if ([path isEqualToString:helloPath]) {
        NSString *file = [[NSBundle mainBundle] pathForResource:@"hellodoc" ofType:@"icns"];
        return [NSDictionary dictionaryWithObject:[NSData dataWithContentsOfFile:file]
                                           forKey:kGMUserFileSystemCustomIconDataKey];
    }
    return nil;
}

@end
