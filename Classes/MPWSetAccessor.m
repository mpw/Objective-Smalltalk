//
//  MPWSetAccessor.m
//  Arch-S
//
//  Created by Marcel Weiher on 21/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWSetAccessor.h"
#import "MPWInstanceVariable.h"

@implementation MPWSetAccessor

-declarationString
{
	NSString *varName = [ivarDef name];
	NSString *upperCasedVarName;
	upperCasedVarName = [[[varName substringToIndex:1] uppercaseString] stringByAppendingString:[varName substringFromIndex:1]];
	return [NSString stringWithFormat:@"<void>set%@:newObject",upperCasedVarName];
}

-evaluateOnObject:target parameters:parameters
{
	id value=[parameters objectAtIndex:0];
	[ivarDef setValue:value inContext:target];
	return value;
}


@end
