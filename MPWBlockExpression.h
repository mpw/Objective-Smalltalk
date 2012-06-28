//
//  MPWBlockExpression.h
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import "MPWExpression.h"


@interface MPWBlockExpression : MPWExpression {
	id	statements;
	id  arguments;
}

+blockWithStatements:newStatements arguments:newArgs;


@end
