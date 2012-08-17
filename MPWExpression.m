//
//  MPWExpression.m
//  MPWTalk
//
//  Created by marcel on Mon Jul 02 2001.
//  Copyright (c) 2001 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWExpression.h>
#import "MPWStCompiler.h"

@implementation MPWExpression

intAccessor(offset , setOffset)
intAccessor(len, setLen)


-(NSObject<MPWEvaluable>*)evaluateIn:aContext
{
	return self;
}

-(NSObject<MPWEvaluable>*)evaluate
{
	return self;
}


-(NSException*)handleOffsetsInException:(NSException*)exception
{
    id dict=[exception userInfo];
    if ( ![dict objectForKey:@"offset"]) {
        if (dict) {
            dict=[[[exception userInfo] mutableCopy] autorelease];
        } else {
            dict=[NSMutableDictionary dictionaryWithCapacity:1];
        }
        [dict setObject:[NSNumber numberWithInt:offset] forKey:@"offset"];
        exception =  [NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:dict];
    }
    return exception;
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