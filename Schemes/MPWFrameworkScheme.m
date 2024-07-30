//
//  MPWFrameworkScheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 4/15/14.
//
//

#import "MPWFrameworkScheme.h"
#import <MPWFoundation/MPWFoundation.h>


@interface MPWFrameworkScheme()

@property (nonatomic, strong) NSMutableArray *paths;

@end

@implementation MPWFrameworkScheme

-(NSArray *)basePaths
{
    return @[ @"/Library/Frameworks/",
              @"/System/Library/Frameworks/",
              @"/System/Library/PrivateFrameworks/",
              @"/System/iOSSupport/System/Library/Frameworks/",
              ];
}

-(instancetype)init {
    self=[super init];
    self.paths=[self basePaths];
    return self;
}

-(void)addPath:(NSString*)path
{
    [self.paths insertObject:path atIndex:0];
}

-(id)at:(id <MPWIdentifying>)aReference
{
    NSString *name=[aReference path];
    NSBundle *result=nil;
    
    if ( [name containsString:@"/"])  {
        result=[NSBundle bundleWithPath:[name stringByAppendingPathExtension:@"framework"]];
    } else {
        for ( NSString *base in self.paths) {
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

-(NSArray<MPWIdentifier*>*)childrenOfReference:(MPWIdentifier*)aReference
{
    return (NSArray *)[[self collect] referenceForPath:[[self allFrameworks] each]];
}

@end
