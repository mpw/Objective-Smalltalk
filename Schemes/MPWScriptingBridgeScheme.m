//
//  MPWScriptingBridgeScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 5/31/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import "MPWScriptingBridgeScheme.h"
#import "MPWScriptingBridgeBinding.h"

@implementation MPWScriptingBridgeScheme

objectAccessor( NSMutableDictionary, bridges, setBridges )

-init
{
	self=[super init];
	[self setBridges:[NSMutableDictionary dictionary]];
	return self;
}	


-appForIdentifier:(NSString*)identifer
{
	id remoteApp = [[self bridges] objectForKey:identifer];
	if ( !remoteApp ){ 
		remoteApp = [NSClassFromString(@"SBApplication") applicationWithBundleIdentifier:identifer];
		if ( remoteApp ) {
			[[self bridges] setObject:remoteApp forKey:identifer];
		}
	}
	return remoteApp;
}

-bindingForName:aName inContext:aContext
{
	NSURL *url=[NSURL URLWithString:aName];
	NSString *appIdentifier = [url host];
	NSString *path = [url path];
	if ( [path hasPrefix:@"/"] ) {
		path=[path substringFromIndex:1];
	}
	id remoteApp=[self appForIdentifier:appIdentifier];
	return [[[MPWScriptingBridgeBinding alloc] initWithBaseObject:remoteApp path:path] autorelease];
}



@end
