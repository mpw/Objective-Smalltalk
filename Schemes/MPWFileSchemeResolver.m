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
    NSError *error=nil;
    NSURL *aURL=[NSURL fileURLWithPath:[aReference path]];
    NSData *rawData = [NSData dataWithContentsOfURL:aURL  options:NSDataReadingMapped error:&error];
    MPWResource *result=[[[MPWResource alloc] init] autorelease];
    [result setSource:aURL];
    [result setRawData:rawData];
    [result setError:error];
    return result;
}

-(void)setObject:(id)theObject forReference:(id)aReference
{
    NSLog(@"write a file: %@",aReference);
    [theObject writeToFile:[aReference path] atomically:YES];
}

-bindingForName:aName inContext:aContext
{
//    id binding = [MPWBinding bindingWithValue:[NSString stringWithContentsOfFile:aName]];
    id binding = [[[MPWFileBinding alloc] initWithPath:aName] autorelease];
    return binding;
}
//
//-valueForBinding:aBinding
//{
//    if ( [aBinding isKindOfClass:[MPWFileBinding class]] ) {
//        return [aBinding value];
//    } else {
////        return [[[self bindingForName:[aBinding name] inContext:nil] value] rawData];
//        return [[self bindingForName:[aBinding name] inContext:nil] value];
//    }
//}
//

-(NSArray*)childrenOf:(MPWBinding*)binding
{
    return [binding children];
}

-(NSArray*)childrenOf:(MPWBinding*)binding inContext:aContext
{
    return [binding children];
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
    NSArray *childNames=[[self bindingForName:basePath inContext:aContext] childNames];
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

