//
//  MPWFrameworkScheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 4/15/14.
//
//

#import "MPWFrameworkScheme.h"
#import <MPWFoundation/MPWFoundation.h>


@implementation MPWFrameworkScheme

-(NSArray *)basePaths
{
    return @[ @"/Library/Frameworks/",
              @"/System/Library/Frameworks/",
              @"/System/Library/PrivateFrameworks/",
              @"/System/iOSSupport/System/Library/Frameworks/",
              ];
}

-(id)at:(id <MPWReferencing>)aReference
{
    NSString *name=[aReference path];
    NSBundle *result=nil;
    
    if ( [name containsString:@"/"])  {
        result=[NSBundle bundleWithPath:[name stringByAppendingPathExtension:@"framework"]];
    } else {
        for ( NSString *base in [self basePaths]) {
            result=[NSBundle bundleWithPath:[[base stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"framework"]];
            if ( result ) {
                break;
            }
        }
    }
    return result;
}

-(NSString *)frameworksIn:(NSString *)basePath
{
    return [[[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:basePath error:NULL] pathsMatchingExtensions:@[ @"framework"]] collect] stringByDeletingPathExtension];
}

-(NSString *)allFrameworks
{
    return [self frameworksIn:[self basePaths][0]];
}

-(NSArray<MPWReference*>*)childrenOfReference:(MPWReference*)aReference
{
    return (NSArray *)[[self collect] referenceForPath:[[self allFrameworks] each]];
}

@end
