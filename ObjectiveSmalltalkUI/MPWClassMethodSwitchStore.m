//
//  MPWClassMethodSwitchStore.m
//  ViewBuilderFramework
//
//  Created by Marcel Weiher on 06.03.19.
//  Copyright © 2019 Marcel Weiher. All rights reserved.
//

#import "MPWClassMethodSwitchStore.h"

@implementation MPWClassMethodSwitchStore


-(id<MPWReferencing>)mapReference:(id<MPWReferencing>)aReference
{
    NSArray *path=[aReference relativePathComponents];
    if ( path.count >= 1 && [path[0] isEqualToString:@"."] ){
        path=[path subarrayWithRange:NSMakeRange(1, path.count-1)];
    }
    if ( path.count >= 1 && !(path.count >1 && [path[1] hasSuffix:@"Methods"]) )  {
        NSMutableArray *newPath=[[path mutableCopy] autorelease];
        [newPath insertObject:self.showClassMethods ? @"classMethods" : @"instanceMethods" atIndex:1];
        aReference = [[[[(NSObject*)aReference class] alloc] initWithPathComponents:newPath scheme:nil] autorelease];
    }
    return aReference;
}



@end

#import <MPWFoundation/DebugMacros.h>

@implementation MPWClassMethodSwitchStore(testing)

-(NSString*)_mapPathString:(NSString*)s
{
    return [[self mapReference:[self referenceForPath:s]] path];
}

+(void)testMapping
{
    MPWClassMethodSwitchStore *s=[self store];
    IDEXPECT( [s _mapPathString:@"."], @".", @"root" );
    IDEXPECT( [s _mapPathString:@"base"], @"base/instanceMethods", @"class name" );
    IDEXPECT( [s _mapPathString:@"base/setup"], @"base/instanceMethods/setup", @"method name" );
}

+testSelectors {
    return @[
             @"testMapping",
             ];
}

@end

