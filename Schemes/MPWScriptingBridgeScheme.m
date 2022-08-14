//
//  MPWScriptingBridgeScheme.m
//  Arch-S
//
//  Created by Marcel Weiher on 5/31/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import "MPWScriptingBridgeScheme.h"
#import "MPWScriptingBridgeBinding.h"

@interface NSObject(scriptingBridge)

+applicationWithBundleIdentifier:(NSString*)bundleId;

@end


@implementation MPWScriptingBridgeScheme

objectAccessor(NSMutableDictionary*, bridges, setBridges )

-init
{
	self=[super init];
	[self setBridges:[NSMutableDictionary dictionary]];
	return self;
}	

//-(void)_addObjectCreationMethodToSBApplication
//{
//    static BOOL added=NO;
//    if (!added) {
//        Class sbappclass=NSClassFromString(@"SBApplication");
//        id a = ^(id blockself, NSString* name, NSDictionary * props){
//            id obj = [[[blockself classForScriptingClass:name] alloc] initWithProperties:props];
//            NSLog(@"Created object: %p",obj);
//            NSLog(@"Created object: %@",obj);
//            return obj;
//
//        };
//        IMP methodImp=imp_implementationWithBlock(a);
//        class_addMethod(sbappclass, @selector(instanceForClass:withProperties:), methodImp, "@@:@@");
//        added=YES;
//    }
//}

-appForIdentifier:(NSString*)identifier
{
	id remoteApp = [[self bridges] objectForKey:identifier];
	if ( !remoteApp ){
        Class sbappclass=NSClassFromString(@"SBApplication");
        if (!sbappclass) {
            NSLog(@"SBApplication not linked, link it or load it using 'context loadFramework:'ScriptingBridge''");
            return nil;
        }
//        [self _addObjectCreationMethodToSBApplication];
		remoteApp = [NSClassFromString(@"SBApplication") applicationWithBundleIdentifier:identifier];
        NSLog(@"remote app: %@",remoteApp);
		if ( remoteApp ) {
			[[self bridges] setObject:remoteApp forKey:identifier];
		}
	}
	return remoteApp;
}

-bindingForReference:aReference inContext:aContext
{
	NSURL *url=[NSURL URLWithString:[aReference path]];
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
        return [super bindingForReference:aReference inContext:nil];
    }
}

-(NSArray*)listOfApps
{
    MPWExternalFilter *f=[MPWExternalFilter filterWithCommandString:@"osascript -e 'tell application \"System Events\" to get name of every process whose background only is false'"];
    [f run];
    [f close];
    NSString *appListString=(NSString*)[(MPWFilter*)[f target] target];   // FIXME
    NSString *cleanedNames=[[[appListString componentsSeparatedByString:@","] collect] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return (NSArray*)[[self collect] bindingForName:[cleanedNames each] inContext:nil];
}

@end



