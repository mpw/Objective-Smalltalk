//
//  MPWEnvScheme.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 11/25/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWEnvScheme.h"
#import "MPWGenericBinding.h"

@implementation MPWEnvScheme

-bindingForName:aName inContext:aContext
{
	id binding = [[[MPWGenericBinding alloc] initWithName:aName scheme:self] autorelease];
	return binding;
}

-(const char*)cstringValueOfBinding:aBinding
{
	return getenv([[aBinding name] UTF8String]);
}



-(BOOL)isBoundBinding:aBinding
{
	return [self cstringValueOfBinding:aBinding] != NULL;
}

-valueForBinding:aBinding
{
	const char *val=[self cstringValueOfBinding:aBinding];
	if ( val ) {
		return [NSString stringWithUTF8String:val];
	} else {
		return nil;
	}
}

-(void)setValue:newValue forBidning:aBinding
{
	if ( [newValue isKindOfClass:[MPWBinding class]] ) {
		newValue=[newValue value];
	}
	newValue=[newValue stringValue];
	if ( newValue  ) {
		setenv( [[aBinding name] UTF8String],[newValue UTF8String], 1 );
	}
}


@end
