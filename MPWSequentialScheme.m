//
//  MPWSequentialScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 6/13/11.
//  Copyright 2011 metaobject ltd. All rights reserved.
//

#import "MPWSequentialScheme.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWBinding.h"

@implementation MPWSequentialScheme

objectAccessor( NSMutableArray, schemes, setSchemes) 

-initWithSchemes:(NSArray*)newSchemes
{
	self=[super init];
	[self setSchemes:[[newSchemes mutableCopy] autorelease]];
	return self;
}

-init
{
	return [self initWithSchemes:[NSMutableArray array]];
}

+schemeWithSchemes:(NSArray*)newSchemes
{
	return [[[self alloc] initWithSchemes:newSchemes] autorelease];
}

-(void)addScheme:newScheme
{
	[(NSMutableArray*)[self schemes] addObject:newScheme];
}

-bindingWithIdentifier:anIdentifier withContext:aContext
{
	MPWBinding *binding = nil;
	for ( MPWScheme *scheme in [self schemes] ) {
		NSLog(@"scheme: %@",scheme);
		binding = [scheme bindingWithIdentifier:anIdentifier withContext:aContext];
		NSLog(@"binding: %@",binding);
		if ( binding && [binding isBound] ) {
			NSLog(@"found it!");
			break;
		}
	}
	return binding;
}

-(void)dealloc
{
	[schemes release];
	[super dealloc];
}

@end

#import "MPWStCompiler.h"

@implementation MPWSequentialScheme(testing)

+(void)testBasicSequentialAccess
{
	MPWStCompiler *compiler=[[[MPWStCompiler alloc] init] autorelease];
	[compiler evaluateScriptString:@"scheme:seq := MPWSequentialScheme scheme."];
	EXPECTNOTNIL([compiler evaluateScriptString:@"scheme:var"],@"should have var scheme");
	[compiler evaluateScriptString:@"scheme:seq addScheme: scheme:var"];
	[compiler evaluateScriptString:@"scheme:seq addScheme: scheme:env"];
	[compiler evaluateScriptString:@"env:bozo := 'hi'"];
	IDEXPECT([compiler evaluateScriptString:@"seq:bozo"],@"hi",@"env");
	[compiler evaluateScriptString:@"seq:bozo := 'bozo'"];
	IDEXPECT([compiler evaluateScriptString:@"seq:bozo"],@"bozo",@"var");
}


+testSelectors {
	return [NSArray arrayWithObjects:@"testBasicSequentialAccess",
			nil];
}

@end

