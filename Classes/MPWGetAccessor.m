//
//  MPWGetAccessor.m
//  MPWTalk
//
//  Created by Marcel Weiher on 21/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWGetAccessor.h"
#import "MPWInstanceVariable.h"
#import "MPWMethodHeader.h"

@implementation MPWGetAccessor

idAccessor( ivarDef, _setIvarDef )


-declarationString
{
	return [ivarDef name];
}

-(void)setIvarDef:newIvarDef
{
	[self _setIvarDef:newIvarDef];
	[self setMethodHeader:[MPWMethodHeader methodHeaderWithString:[self declarationString]]];
}

-initWithInstanceVariableDef:newIvarDef
{
	self = [super init];
	[self setIvarDef:newIvarDef];
	return self;
}

+accessorForInstanceVariable:ivarDef
{
	return [[[self alloc] initWithInstanceVariableDef:ivarDef] autorelease];
}

+(NSArray*)testSelectors {
	return [NSArray array];
}

-evaluateOnObject:target parameters:parameters
{
	return [ivarDef valueInContext:target];
}

@end
