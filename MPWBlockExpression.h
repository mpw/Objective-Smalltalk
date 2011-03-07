//
//  MPWBlockExpression.h
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWBlockExpression : MPWObject {
	id	statements;
	id  arguments;
}

+blockWithStatements:newStatements arguments:newArgs;


@end
