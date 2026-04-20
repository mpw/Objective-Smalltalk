//
//  STEvaluable.h
//  Arch-S
//
//  Created by marcel on Mon Feb 13 2006.
//  Copyright (c) 2001 Marcel Weiher. All rights reserved.
//


#import <Foundation/Foundation.h>

@protocol STEvaluation;


@protocol STEvaluable

-(NSObject<STEvaluable>*)evaluateIn:(id <STEvaluation>)aContext;
-(NSObject<STEvaluable>*)evaluate;

@end

