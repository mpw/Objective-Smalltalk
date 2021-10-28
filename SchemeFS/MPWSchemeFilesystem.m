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

objectAccessor(MPWScheme, scheme, setScheme)

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
    NSLog(@"get directory: %@",path);
    //    return [NSArray arrayWithObject:@"hello.txt"];
    id v = [[[self scheme] bindingForName:path inContext:nil] childNames];
    NSLog(@"children: %@",v);
    NSLog(@"class %@, value: %@",[v class],v);
    return v;
}

- (NSData *)contentsAtPath:(NSString *)path {
    path = [path lastPathComponent];
    NSLog(@"get file: %@",path);
//    return [@"hello world!" asData];
    NSString *value = [[self scheme] get:path];
    NSLog(@"scheme: %@ Value: %@",[self scheme],value);
    NSData *data=[value asData];
    NSLog(@"Data: %@",data);
    return data;
//   return  [[[[self scheme] bindingForName:path inContext:nil] value] asData];
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
        return  @{NSFileType: NSFileTypeRegular,
                  NSFilePosixPermissions: @(4*8*8)
                  } ;
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
