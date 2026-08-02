//
//  MPWExpression.h
//  Arch-S
//
//  Created by marcel on Mon Jul 02 2001.
//  Copyright (c) 2001 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>
#import <ObjectiveSmalltalk/STEvaluable.h>

// NSObject (atomic refcounting), not MPWObject: the compiled AST is shared
// across evaluation threads, and MPWObject's fast non-atomic refcount races
// under concurrent retain/release.  MPWObject's fast path is kept for the
// data-plane classes (streams, parsers) that actually need it.
@interface STExpression : NSObject <STEvaluable> {
    long textOffset,len;
}

-(NSSet*)variablesRead;
-(NSSet*)variablesWritten;
-(NSSet*)variableNamesRead;
-(NSSet*)variableNamesWritten;

longAccessor_h(offset , setOffset)
longAccessor_h(len, setLen)


-(NSException*)handleOffsetsInException:(NSException*)exception;
@property (readonly,assign ) BOOL isSuper;

@end

@interface NSObject(evaluating)

-(void)addToVariablesRead:(NSMutableSet*)variableList;
-(void)addToVariablesWritten:(NSMutableSet*)variableList;
-evaluateIn:(id <STEvaluation>)aContext;

@end


@interface NSObject(compiling)

-compileIn:aContext;

@end
