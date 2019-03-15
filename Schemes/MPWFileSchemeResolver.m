//
//  MPWFileSchemeResolver.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/7/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "MPWFileSchemeResolver.h"
#import "MPWFileBinding.h"
#ifndef GS_API_LATEST
#import "MPWFileWatcher.h"
#endif
#import "MPWResource.h"

@implementation MPWFileSchemeResolver

-bindingForReference:aReference inContext:aContext
{
    return [MPWFileBinding bindingWithReference:aReference inStore:self];
}

#ifndef GS_API_LATEST
-(void)startWatching:(MPWFileBinding*)binding
{
    NSString *path=[binding path];
    NSString *dir=[path stringByDeletingLastPathComponent];
    
    [[MPWFileWatcher watcher] watchFile:path withDelegate:binding];
    [[MPWFileWatcher watcher] watchFile:dir withDelegate:binding];
    
}
#else
-(void)startWatching:(MPWFileBinding*)binding
{}
#endif




-(NSString*)completePartialPathFromAbsoluetPath:(NSString*)partialPath
{
    NSRange r=[partialPath rangeOfString:@"/" options:NSBackwardsSearch];
    return [partialPath substringToIndex:r.location+1];

}

-(NSArray *)completionsForPartialName:(NSString *)partialName inContext:aContext
{
    NSString *basePath=@".";
    if ( [partialName containsString:@"/"]) {
        basePath=[self completePartialPathFromAbsoluetPath:partialName];
        partialName=[partialName substringFromIndex:[basePath length]];
    }
    NSArray *childRefs=[self childrenOfReference:[self referenceForPath:basePath]];
    NSArray *childNames=(NSArray*)[[childRefs collect] path];
    NSMutableArray *names=[NSMutableArray array];
    for ( NSString *name in childNames) {
        if ( !partialName || [partialName length]==0 || [name hasPrefix:partialName]) {
            [names addObject:name];
        }
    }
    return names;
}


@end
#import "MPWStCompiler.h"

@implementation MPWFileSchemeResolver(testing)


+(void)testGettingASimpleFile
{
    NSString *tempUrlString = @"file:/tmp/fileSchemeTest.txt";
    NSString *textString = @"hello world!";
    [textString writeToURL:[NSURL URLWithString:tempUrlString] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    IDEXPECT([[MPWStCompiler evaluate:tempUrlString] stringValue],textString, @"get test file");
}

+(void)testGetDirContents
{
    MPWDirectoryBinding* dirContents =[MPWStCompiler evaluate:@"file:/"];
    EXPECTTRUE(dirContents.contents.count> 15, @"got directory contents");
    
}


+(void)testCompleteSubpath
{
    MPWFileSchemeResolver *s=[self store];
    NSString *tempUrlString = @"/tm";
    NSString *base=[s completePartialPathFromAbsoluetPath:tempUrlString ];
    IDEXPECT( base, @"/", @"base path");
}


+testSelectors
{
	return [NSArray arrayWithObjects:
            @"testGettingASimpleFile",
            @"testGetDirContents",
            @"testCompleteSubpath",
			nil];
}


@end

