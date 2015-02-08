//
//  MPWDefaultsScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 6/4/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import "MPWDefaultsScheme.h"
#import "MPWGenericBinding.h"

@implementation MPWDefaultsScheme


-bindingForName:aName inContext:aContext
{
	if ( [aName hasPrefix:@"/"] ) {
		aName=[aName substringFromIndex:1];
	}
	return [super bindingForName:aName inContext:aContext];
}


-(BOOL)isBoundBinding:aBinding
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:[aBinding name]] != nil;
}

-valueForBinding:aBinding
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:[aBinding name]];
}

-(void)setValue:newValue forBinding:aBinding
{
    NSString *name = [aBinding name];
    if ( [name hasPrefix:@"initial/"]){
        name=[[name componentsSeparatedByString:@"/"] lastObject];
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{ name : newValue }];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:name];
    }
}


@end
