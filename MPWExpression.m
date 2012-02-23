//
//  MPWExpression.m
//  MPWTalk
//
//  Created by marcel on Mon Jul 02 2001.
//  Copyright (c) 2001 Marcel Weiher. All rights reserved.
//

#import <MPWTalk/MPWExpression.h>
#import "MPWStCompiler.h"

@implementation MPWExpression

-(NSObject<MPWEvaluable>*)evaluateIn:aContext
{
	return self;
}
-(NSObject<MPWEvaluable>*)evaluate
{
	return self;
}


-compileIn:aContext
{
	return self;
}
-variablesRead
{
	id result = [NSMutableSet set];
	[self addToVariablesRead:result];
	return result;
}

-variablesWritten
{
	id result = [NSMutableSet set];
	[self addToVariablesWritten:result];
	return result;
}

@end


@implementation NSObject(evaluateIn)


-(void)addToVariablesRead:(NSMutableSet*)variableList
{
}
-(void)addToVariablesWritten:(NSMutableSet*)variableList
{
}


-evaluateIn:aContext
{
	return self;
}

@end

@implementation NSString(stringValue)

-(NSString *)stringValue { return self; }

@end

@implementation NSObject(compiling)

-compileIn:aContext
{
	return [aContext compile:[self stringValue]];
}


@end