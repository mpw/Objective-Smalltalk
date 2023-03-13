//
//  MPWExpression.m
//  Arch-S
//
//  Created by marcel on Mon Jul 02 2001.
//  Copyright (c) 2001 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/STExpression.h>
#import "STCompiler.h"
#import "MPWIdentifier.h"

@implementation STExpression

longAccessor(textOffset , setTextOffset)
longAccessor(len, setLen)


-(NSObject<MPWEvaluable>*)evaluateIn:aContext
{
	return self;
}

-(NSObject<MPWEvaluable>*)evaluate
{
	return self;
}

-(void)accumulateLocalVars:(NSMutableArray*)vars
{
    
}

-(NSException*)handleOffsetsInException:(NSException*)exception
{
//    NSLog(@"handleOffsetsInException: %@",exception);
    id dict=[exception userInfo];
    if ( ![dict objectForKey:@"offset"]) {
        if (dict) {
            dict=[[[exception userInfo] mutableCopy] autorelease];
        } else {
            dict=[NSMutableDictionary dictionaryWithCapacity:1];
        }
        [dict setObject:[NSNumber numberWithLong:textOffset] forKey:@"offset"];
        exception =  [NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:dict];
//        NSLog(@"offset: %ld",offset);
   }
    return exception;
}


-compileIn:aContext
{
	return self;
}

-(NSSet*)variablesRead
{
    id result = [NSMutableSet set];
    [self addToVariablesRead:result];
    return result;
}

-(NSSet*)variablesWritten
{
    id result = [NSMutableSet set];
    [self addToVariablesWritten:result];
    return result;
}

-(NSSet*)variableNamesRead
{
    NSSet *written = [self variablesRead];
    NSMutableSet *names = [NSMutableSet set];
//    NSLog(@"read identifiers: %@",written);
    for ( MPWIdentifier *identifier in written) {
        [names addObject:[identifier identifierName]];
    }
    //    NSArray *names=[[written collect] identifierName];
//    NSLog(@"names: %@",names);
    return names;
}

-(NSSet*)variableNamesWritten
{
    NSSet *written = [self variablesWritten];
    NSMutableSet *names = [NSMutableSet set];
//    NSLog(@"written identifiers: %@",written);
    for ( MPWIdentifier *identifier in written) {
        [names addObject:[identifier identifierName]];
    }
//    NSArray *names=[[written collect] identifierName];
//    NSLog(@"names: %@",names);
    return names;
}

-(BOOL)isSuper
{
    return NO;
}

-(void)accumulateBlocks:(NSMutableArray*)blocks
{
    ;
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
