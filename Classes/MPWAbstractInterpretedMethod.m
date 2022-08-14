//
//  MPWMethod.m
//  Arch-S
//
//  Created by Marcel Weiher on 12/09/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWAbstractInterpretedMethod.h>
#import "MPWMethodCallBack.h"
#import "MPWMethodHeader.h"

@implementation MPWAbstractInterpretedMethod


objectAccessor(MPWMethodHeader*, methodHeader, setMethodHeader )
idAccessor( context, setContext )
idAccessor( methodType, setMethodType )

-(MPWMethodHeader*)header
{
	return [self methodHeader];
}

-(NSArray*)formalParameters
{
	return [[self methodHeader] parameterNames];
}

-evaluateOnObject:target parameters:(NSArray*)parameters
{
	[NSException raise:@"abstract method evaluated" format:@"abstract method evaluated"];
	return nil;
}

-(NSString*)methodName
{
	return [[self methodHeader] methodName];
}

//-(void)encodeWithCoder:aCoder
//{
//    [super encodeWithCoder:aCoder];
//    encodeVar( aCoder, methodHeader );
//    encodeVar( aCoder, methodType );
//    encodeVar( aCoder, context );
//}
//
//-initWithCoder:aCoder
//{
//    self = [super initWithCoder:aCoder];
//    decodeVar( aCoder, methodHeader );
//    decodeVar( aCoder, methodType );
//    decodeVar( aCoder, context );
//    return self;
//}



-(void)dealloc 
{
	[methodHeader release];
	[context release];
	[methodType release];
	[super dealloc];
}


@end
