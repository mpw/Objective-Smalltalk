//
//  MPWSchemeScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 6/30/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWSchemeScheme.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWVARBinding.h"

@implementation MPWSchemeScheme

objectAccessor( NSMutableDictionary, _schemes, setSchemes )

-(NSDictionary*)schemes { return [self _schemes]; }

-init
{
	self=[super init];
	[self setSchemes:[NSMutableDictionary dictionary]];
	return self;
}

-localVarsForContext:aContext
{
	return [self schemes];
}

-(void)setSchemeHandler:(MPWScheme*)aScheme   forSchemeName:(NSString*)schemeName
{
//    NSLog(@"%p scheme handler: '%@' for scheme name: '%@'",self,aScheme,schemeName);
    if ( aScheme && schemeName) {
        [[self _schemes] setObject:aScheme forKey:schemeName];
    }
}


-bindingForName:(NSString*)variableName inContext:aContext
{
//    NSLog(@"%p bindingForName: %@",self,variableName);
	id localVars = [self localVarsForContext:aContext];
	id binding=nil;
//    NSLog(@"scheme %p: localVars: %@",self,localVars);
	binding = [[[MPWVARBinding alloc] initWithBaseObject:localVars path:variableName] autorelease];		
//    NSLog(@"binding: %@",binding);
	return binding;
}


-objectForKey:aKey
{
	return [[self schemes] objectForKey:aKey];
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

@end
