//
//  MPWMethod.m
//  MPWTalk
//
//  Created by Marcel Weiher on 12/09/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWMethod.h>
#import "MPWMethodCallBack.h"
#import "MPWMethodHeader.h"

@implementation MPWMethod


objectAccessor( MPWMethodHeader, methodHeader, setMethodHeader )
idAccessor( context, setContext )
idAccessor( methodType, setMethodType )

-(MPWMethodHeader*)header
{
	return [self methodHeader];
}

-formalParameters
{
	return [[self methodHeader] parameterNames];
}

-evaluateOnObject:target parameters:parameters
{
	[NSException raise:@"abstract method evaluated" format:@"abstract method evaluated"];
	return nil;
}

#ifndef __clang_analyzer__
// This leaks because we are installing into the runtime, can't remove after

-(void)installInClass:aClass
{
	id callback=[[MPWMethodCallBack alloc] init];
	[callback setMethod:self];
	[callback installInClass:aClass];
}

#endif

-methodName
{
	return [[self methodHeader] methodName];
}

-(void)encodeWithCoder:aCoder
{
	[super encodeWithCoder:aCoder];
	encodeVar( aCoder, methodHeader );
	encodeVar( aCoder, methodType );
	encodeVar( aCoder, context );
}

-initWithCoder:aCoder
{
	self = [super initWithCoder:aCoder];
	decodeVar( aCoder, methodHeader );
	decodeVar( aCoder, methodType );
	decodeVar( aCoder, context );
	return self;
}



-(void)dealloc 
{
	[methodHeader release];
	[context release];
	[methodType release];
	[super dealloc];
}


@end
