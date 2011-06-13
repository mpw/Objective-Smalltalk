//
//  MPWDefaultsScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 6/4/11.
//  Copyright 2011 metaobject ltd. All rights reserved.
//

#import "MPWDefaultsScheme.h"
#import "MPWGenericBinding.h"

@implementation MPWDefaultsScheme


-bindingForName:aName inContext:aContext
{
	if ( [aName hasPrefix:@"/"] ) {
		aName=[aName substringFromIndex:1];
	}
	return [[[MPWGenericBinding alloc] initWithName:aName scheme:self] autorelease];
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
	[[NSUserDefaults standardUserDefaults] setObject:newValue forKey:[aBinding name]];
}


@end
