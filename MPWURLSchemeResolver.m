//
//  MPWURLSchemeResolver.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/11/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "MPWURLSchemeResolver.h"
#import "MPWURLBinding.h"

@implementation MPWURLSchemeResolver

-bindingForName:aName inContext:aContext
{
	id urlbinding = [[[MPWURLBinding alloc] initWithURLString:[@"http:" stringByAppendingString:aName]] autorelease];
	return urlbinding;
}



@end
