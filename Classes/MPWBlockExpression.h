//
//  MPWBlockExpression.h
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import "MPWExpression.h"


@interface MPWBlockExpression : MPWExpression {
	NSArray* statements;
	NSArray* declaredArguments;
}

+blockWithStatements:newStatements arguments:newArgs;

-(NSArray*)arguments;

@end
