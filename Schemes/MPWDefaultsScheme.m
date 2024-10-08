//
//  MPWDefaultsScheme.m
//  Arch-S
//
//  Created by Marcel Weiher on 6/4/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import "MPWDefaultsScheme.h"

@implementation MPWDefaultsScheme

-(NSArray<MPWIdentifying>*)childrenOfReference:(id <MPWIdentifying>)aReference
{
    return [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
}

-(BOOL)hasChildren:(id <MPWIdentifying>)aReference
{
    NSString *path=[aReference path];

    return ( [path length]==0 || [path isEqualToString:@"."]|| [path isEqualToString:@"/"]);
}

-at:aReference
{
    if ( [self hasChildren:aReference]) {
        return [self listForNames:[self childrenOfReference:aReference]];
    }
	return [[NSUserDefaults standardUserDefaults] objectForKey:[[aReference path] lastPathComponent]];
}

-(void)at:aReference put:newValue 
{
    NSString *name = [aReference path];
    if ( [name hasPrefix:@"initial/"]){
        name=[[name componentsSeparatedByString:@"/"] lastObject];
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{ name : newValue }];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:name];
    }
}


@end
