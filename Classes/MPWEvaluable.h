//
//  MPWEvaluable.h
//  Arch-S
//
//  Created by marcel on Mon Feb 13 2006.
//  Copyright (c) 2001 Marcel Weiher. All rights reserved.
//


#import <Foundation/Foundation.h>

@protocol STEvaluation;


@protocol MPWEvaluable

-(NSObject<MPWEvaluable>*)evaluateIn:(id <STEvaluation>)aContext;
-(NSObject<MPWEvaluable>*)evaluate;

@end

