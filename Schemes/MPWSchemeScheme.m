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

+(instancetype)createGlobalSchemeScheme
{
    MPWSchemeScheme *schemes=[self store];
    
    MPWClassScheme *classScheme=[MPWClassScheme store];
    [schemes setSchemeHandler:classScheme forSchemeName:@"class"];
    [schemes setSchemeHandler:classScheme forSchemeName:@"builder"];
    [schemes setSchemeHandler:[STProtocolScheme store] forSchemeName:@"protocol"];
    [schemes setSchemeHandler:[MPWTCPStore store] forSchemeName:@"tcp"];
    [schemes setSchemeHandler:[MPWSFTPStore store] forSchemeName:@"sftp"];
    [schemes setSchemeHandler:[MPWDictStore store] forSchemeName:@"template"];
    [schemes setSchemeHandler:[[MPWRefScheme new] autorelease] forSchemeName:@"ref"];
    [schemes setSchemeHandler:schemes forSchemeName:@"scheme"];
    [schemes setSchemeHandler:[MPWFrameworkScheme store] forSchemeName:@"framework"];
    [schemes setSchemeHandler:[MPWDefaultsScheme store]  forSchemeName:@"defaults"];
    [schemes setSchemeHandler:[MPWFileSchemeResolver store]  forSchemeName:@"file"];
    [schemes setSchemeHandler:[MPWURLSchemeResolver httpScheme]  forSchemeName:@"http"];
    [schemes setSchemeHandler:[MPWURLSchemeResolver httpsScheme]  forSchemeName:@"https"];
    [schemes setSchemeHandler:[[[MPWURLSchemeResolver alloc] initWithSchemePrefix:@"ftp"  ]  autorelease] forSchemeName:@"ftp"];
    
    [schemes setSchemeHandler:[MPWEnvScheme store]  forSchemeName:@"env"];
    [schemes setSchemeHandler:[MPWBundleScheme store]  forSchemeName:@"bundle"];
    [schemes setSchemeHandler:[MPWBundleScheme mainBundleScheme]  forSchemeName:@"mainbundle"];
    //    [schemes setSchemeHandler:[MPWScriptingBridgeScheme scheme]  forSchemeName:@"app"];
    
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
