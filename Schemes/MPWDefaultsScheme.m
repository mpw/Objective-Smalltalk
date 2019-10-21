//
//  MPWDefaultsScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 6/4/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import "MPWDefaultsScheme.h"

@implementation MPWDefaultsScheme



-(BOOL)isBoundBinding:aBinding
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:[aBinding name]] != nil;
}


-at:aReference
{
    NSString *path=[aReference path];
    if ( [path length]==0 || [path isEqualToString:@"."]) {
        return [self listForNames:[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys]];
    }
	return [[NSUserDefaults standardUserDefaults] objectForKey:[[aReference path] lastPathComponent]];
}

-(void)put:newValue at:aReference
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
