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

static NSString *helloStr = @"Hello Brave New World!\n";
static NSString *helloPath = @"/hello.txt";

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
    return self;
}


-(id)init
{
    return [self initWithScheme:[[[MPWFileSchemeResolver alloc] init] autorelease]];
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
    return [[[self scheme] bindingForName:path inContext:nil] childNames];
}

- (NSData *)contentsAtPath:(NSString *)path {
    return [[[self scheme] get:[path lastPathComponent]] asData];
}

#pragma optional Custom Icon



- (NSDictionary *)finderAttributesAtPath:(NSString *)path 
                                   error:(NSError **)error {
//    NSLog(@"get finder attributes: %@",path);
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
        return  @{NSFileType: NSFileTypeRegular,
                  NSFilePosixPermissions: @(4*8*8)
                  } ;
    }
}



- (NSDictionary *)resourceAttributesAtPath:(NSString *)path
                                     error:(NSError **)error {
//    NSLog(@"get resource attrs: %@",path);
    if ([path isEqualToString:helloPath]) {
        NSString *file = [[NSBundle mainBundle] pathForResource:@"hellodoc" ofType:@"icns"];
        return [NSDictionary dictionaryWithObject:[NSData dataWithContentsOfFile:file]
                                           forKey:kGMUserFileSystemCustomIconDataKey];
    }
    return nil;
}

@end
