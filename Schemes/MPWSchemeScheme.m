//
//  MPWSchemeScheme.m
//  Arch-S
//
//  Created by Marcel Weiher on 6/30/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWSchemeScheme.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWVARBinding.h"
#import "MPWIdentifier.h"
#import <MPWFoundation/MPWGenericReference.h>
#import "STPortScheme.h"
#import "STProtocolScheme.h"
#import "MPWClassScheme.h"
#import "MPWRefScheme.h"
#import "MPWFrameworkScheme.h"
#import "MPWEnvScheme.h"
#import "MPWEnvScheme.h"
#import "MPWBundleScheme.h"
#import "MPWDefaultsScheme.h"
#import "MPWGlobalVariableStore.h"

@implementation MPWSchemeScheme

objectAccessor(NSMutableDictionary*, _schemes, setSchemes )

id currentScheme=nil;

+(instancetype)currentScheme
{
    if (!currentScheme) {
        currentScheme=[[self createGlobalSchemeScheme] retain];
    }
    return currentScheme;
}

+(void)setCurrentScheme:newSchemeScheme
{
    currentScheme=newSchemeScheme;
}

typedef struct {
    NSString *key,*value;
} keyvalue;

+(instancetype)createGlobalSchemeScheme
{
    MPWSchemeScheme *schemes=[self store];
    keyvalue storemap[] = {
        { @"class", @"MPWClassScheme" },
        { @"builder", @"MPWClassScheme" },
        { @"protocol", @"STProtocolScheme" },
        { @"tcp", @"MPWTCPStore" },
        { @"sftp", @"MPWSFTPStore" },
        { @"template", @"MPWDictStore" },
        { @"ref", @"MPWRefScheme" },
        { @"framework", @"MPWFrameworkScheme" },
        { @"defaults", @"MPWDefaultsScheme" },
        { @"file", @"MPWFileSchemeResolver" },
        { @"env", @"MPWEnvScheme" },
        { @"bundle", @"MPWBundleScheme" },
        { @"global", @"MPWGlobalVariableStore" },
        { @"keychain", @"MPWKeychainStore" },
        { @"app", @"MPWScriptingBridgeScheme" },
        { nil, nil }
    };
  
    for (int i=0; storemap[i].key; i++) {
        Class storeClass=NSClassFromString(storemap[i].value);
        if ( storeClass ) {
            [schemes setSchemeHandler:[storeClass store] forSchemeName:storemap[i].key];
        }
    }
    [schemes setSchemeHandler:[MPWBundleScheme mainBundleScheme]  forSchemeName:@"mainbundle"];

    [schemes setSchemeHandler:schemes forSchemeName:@"scheme"];
    [schemes setSchemeHandler:[MPWURLSchemeResolver httpScheme]  forSchemeName:@"http"];
    [schemes setSchemeHandler:[MPWURLSchemeResolver httpsScheme]  forSchemeName:@"https"];
    [schemes setSchemeHandler:[[[MPWURLSchemeResolver alloc] initWithSchemePrefix:@"ftp"  ]  autorelease] forSchemeName:@"ftp"];
        
    return schemes;
}

-(NSDictionary*)schemes { return [self _schemes]; }

-init
{
	self=[super init];
	[self setSchemes:[NSMutableDictionary dictionary]];
	return self;
}

-(void)setSchemeHandler:(id <MPWStorage>)aScheme   forSchemeName:(NSString*)schemeName
{
    [self at:schemeName put:aScheme];
}

-(id)at:(id)aReference
{
    return [[self schemes] objectForKey:[aReference path]];
}

-(void)at:(id)aReference put:(id)theObject
{
    // FIXME:  the -identifierName shouldn't be there, but is needed or
    //         one of the constraint tests fails (so now have that
    //         weird NSObject category below
    [self _schemes][[aReference identifierName]]=theObject;
}

-(id)copy
{
    MPWSchemeScheme* copy=[[self class] new];
    NSDictionary *theSchemes=[self schemes];
    for ( NSString *key in [theSchemes allKeys]) {
        [copy setSchemeHandler:theSchemes[key] forSchemeName:key];
    }
    return copy;

}


-objectForKey:aKey
{
	return [[self schemes] objectForKey:aKey];
}

-(NSArray<MPWReference*>*)childrenOfReference:(MPWReference*)aReference
{
    NSArray *allNames=[[self schemes] allKeys];
    NSMutableArray *reference=[NSMutableArray array];
    for ( NSString *variableName in allNames) {
        [reference addObject:[self referenceForPath:variableName]];
    }
    return reference;
}

-(NSArray *)completionsForPartialName:(NSString *)partialName inContext:aContext
{
    return (NSArray*)[[[super completionsForPartialName:partialName inContext:aContext] collect] stringByAppendingString:@":"];
}


-description
{
	return [NSString stringWithFormat:@"<%@:%p: scheme-resolver with the following schemes: %@>",[self class],self,[[self schemes] allKeys]];
}

-(void)dealloc
{
	[_schemes release];
	[super dealloc];
}

id st_scheme_at( NSString *scheme, NSString *identifier)
{
    return [[[MPWSchemeScheme currentScheme] at:scheme] at:identifier];
}

void st_scheme_at_put( NSString *scheme, NSString *identifier, id value)
{
    [[[MPWSchemeScheme currentScheme] at:scheme] at:identifier put:value];
}


@end

@implementation NSObject(identifierName)

-identifierName         // FIXME: this is currently needed so setSchemeHandler:forSchemeName: can use at:put:
{
    return self;
}

@end
