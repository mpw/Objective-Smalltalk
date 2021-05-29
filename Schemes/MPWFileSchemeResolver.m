//
//  MPWFileSchemeResolver.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/7/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "MPWFileSchemeResolver.h"
#ifndef GS_API_LATEST
#import "MPWFileWatcher.h"
#endif
#import "MPWScheme.h"

@implementation MPWFileSchemeResolver


-directoryForReference:(MPWGenericReference*)aReference
{
    MPWDirectoryBinding *dir=[super directoryForReference:aReference];
    return [[[MPWDirectoryBinding alloc] initWithContents:(NSArray*)[[self collect] bindingForReference:dir.contents.each inContext:nil]] autorelease];
}

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
    // FIXME: stripping "./" prefixes that probably shouldn't be there in the first place
    NSMutableArray *stripped=[NSMutableArray array];
    for ( NSString *name in [super completionsForPartialName:partialName inContext:aContext]) {
        if ( [name hasPrefix:@"./"] && [name length]>2) {
            name=[name substringFromIndex:2];
        }
        [stripped addObject:name];
    }
    return stripped;
}


-(NSArray *)completionsForPartialName_disabled:(NSString *)partialName inContext:aContext
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
#import "STCompiler.h"

@implementation MPWFileSchemeResolver(testing)


+(void)testGettingASimpleFile
{
    NSString *tempUrlString = @"file:/tmp/fileSchemeTest.txt";
    NSString *textString = @"hello world!";
    [textString writeToURL:[NSURL URLWithString:tempUrlString] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    IDEXPECT([[STCompiler evaluate:tempUrlString] stringValue],textString, @"get test file");
}

+(void)testGetDirContents
{
    MPWDirectoryBinding* dirContents =[STCompiler evaluate:@"file:/"];
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

