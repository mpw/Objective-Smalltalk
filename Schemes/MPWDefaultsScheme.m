//
//  MPWDefaultsScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 6/4/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import "MPWDefaultsScheme.h"

@implementation MPWDefaultsScheme



-(BOOL)isBoundBinding:aBinding
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:[aBinding name]] != nil;
}

-objectForReference:aReference
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:[aReference path]];
}

-(void)setObject:newValue forReference:aReference
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
