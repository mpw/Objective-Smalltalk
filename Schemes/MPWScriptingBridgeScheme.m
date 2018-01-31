//
//  MPWScriptingBridgeScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 5/31/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import "MPWScriptingBridgeScheme.h"
#import "MPWScriptingBridgeBinding.h"
#import "MPWGenericBinding.h"

@interface NSObject(scriptingBridge)

+applicationWithBundleIdentifier:(NSString*)bundleId;

@end


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
        Class sbappclass=NSClassFromString(@"SBApplication");
        if (!sbappclass) {
            NSLog(@"SBApplication not linked, link it or load it using 'context loadFramework:'ScriptingBridge''");
            return nil;
        }
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
    if ( appIdentifier) {
        id remoteApp=[self appForIdentifier:appIdentifier];
        id binding= [[[MPWScriptingBridgeBinding alloc] initWithBaseObject:remoteApp path:path] autorelease];
        return binding;
    } else {
        return [MPWGenericBinding bindingWithName:@"/" scheme:self];
    }
}

-(NSArray*)listOfApps
{
    MPWExternalFilter *f=[MPWExternalFilter filterWithCommandString:@"osascript -e 'tell application \"System Events\" to get name of every process whose background only is false'"];
    [f run];
    [f close];
    NSString *appListString=[[f target] target];
    NSString *cleanedNames=[[[appListString componentsSeparatedByString:@","] collect] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [[self collect] bindingForName:[cleanedNames each] inContext:nil];
}

-(id)valueForBinding:aBinding
{
    if ( [[aBinding name] isEqualToString:@"/"])  {
        return [self listOfApps];
    } else {
        return [super valueForBinding:aBinding];
    }
}
@end
