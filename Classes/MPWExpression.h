//
//  MPWExpression.h
//  Arch-S
//
//  Created by marcel on Mon Jul 02 2001.
//  Copyright (c) 2001 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>
#import <ObjectiveSmalltalk/MPWEvaluable.h>

@interface MPWExpression : MPWObject <MPWEvaluable> {
    long offset,len;
}

-(NSSet*)variablesRead;
-(NSSet*)variablesWritten;
-(NSSet*)variableNamesRead;
-(NSSet*)variableNamesWritten;

longAccessor_h(offset , setOffset)
longAccessor_h(len, setLen)


-(NSException*)handleOffsetsInException:(NSException*)exception;

@end

@interface NSObject(evaluating)

-(void)addToVariablesRead:(NSMutableSet*)variableList;
-(void)addToVariablesWritten:(NSMutableSet*)variableList;
-evaluateIn:aContext;

@end


@interface NSObject(compiling)

-compileIn:aContext;

@end
