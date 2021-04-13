//
//  MPWGetAccessor.m
//  Arch-S
//
//  Created by Marcel Weiher on 21/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWGetAccessor.h"
#import "MPWInstanceVariable.h"
#import "MPWMethodHeader.h"

@implementation MPWGetAccessor

objectAccessor( MPWInstanceVariable, ivarDef, _setIvarDef )


-declarationString
{
	return [ivarDef name];
}

-(void)setIvarDef:(MPWInstanceVariable*)newIvarDef
{
	[self _setIvarDef:newIvarDef];
	[self setMethodHeader:[MPWMethodHeader methodHeaderWithString:[self declarationString]]];
}

-initWithInstanceVariableDef:(MPWInstanceVariable*)newIvarDef
{
	self = [super init];
	[self setIvarDef:newIvarDef];
	return self;
}

+accessorForInstanceVariable:(MPWInstanceVariable*)ivarDef
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
