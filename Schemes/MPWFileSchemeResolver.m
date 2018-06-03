//
//  MPWFileSchemeResolver.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/7/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "MPWFileSchemeResolver.h"
#import "MPWFileBinding.h"
#import "MPWDirectoryBinding.h"
#import "MPWFileWatcher.h"
#import "MPWResource.h"

@implementation MPWFileSchemeResolver


-(void)startWatching:(MPWFileBinding*)binding
{
    NSString *path=[binding path];
    NSString *dir=[path stringByDeletingLastPathComponent];
    
    [[MPWFileWatcher watcher] watchFile:path withDelegate:binding];
    [[MPWFileWatcher watcher] watchFile:dir withDelegate:binding];
    
}

-(id)objectForReference:(id)aReference
{
    if ( [self isLeafReference:aReference]) {
        NSError *error=nil;
        NSURL *aURL=[NSURL fileURLWithPath:[aReference path]];
        NSData *rawData = [NSData dataWithContentsOfURL:aURL  options:NSDataReadingMapped error:&error];
        MPWResource *result=[[[MPWResource alloc] init] autorelease];
        [result setSource:aURL];
        [result setRawData:rawData];
        [result setError:error];
        return result;
    } else {
        return [self childrenOfReference:aReference];
    }
 }

-(void)setObject:(id)theObject forReference:(id)aReference
{
    NSLog(@"write a file: %@",aReference);
    [theObject writeToFile:[aReference path] atomically:YES];
}


-(BOOL)isLeafReference:(MPWReference *)aReference
{
    BOOL    isDirectory=NO;
    BOOL    exists=NO;
    exists=[[NSFileManager defaultManager] fileExistsAtPath:[aReference path] isDirectory:&isDirectory];
    return !isDirectory;
}

//-bindingForReference:aReference inContext:aContext
//{
//    return [[[MPWFileBinding alloc] initWithReference:aReference inStore:self] autorelease];
//}


-(NSArray*)childrenOfReference:(MPWGenericReference*)aReference
{
    NSArray *childNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[aReference path] error:nil];
    return (NSArray*)[[MPWGenericReference collect] referenceWithPath:[childNames each]];
}

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
    [textString writeToURL:[NSURL URLWithString:tempUrlString] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    IDEXPECT([[MPWStCompiler evaluate:tempUrlString] stringValue],textString, @"get test file");
}

+(void)testCompleteSubpath
{
    MPWFileSchemeResolver *s=[self scheme];
    NSString *tempUrlString = @"/tm";
    NSString *base=[s completePartialPathFromAbsoluetPath:tempUrlString ];
    IDEXPECT( base, @"/", @"base path");
}


+testSelectors
{
	return [NSArray arrayWithObjects:
            @"testGettingASimpleFile",
            @"testCompleteSubpath",
			nil];
}


@end

