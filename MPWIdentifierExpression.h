//
//  MPWVariableExpression.h
//  MPWTalk
//
//  Created by marcel on Mon Jul 02 2001.
//  Copyright (c) 2001 Marcel Weiher. All rights reserved.
//

#import <MPWTalk/MPWExpression.h>


@interface MPWIdentifierExpression : MPWExpression {
//	id	name;
//	id	scheme;
	id	evaluationEnvironment;
	id  identifier;
}

//idAccessor_h( name, setName )
//idAccessor_h( scheme, setScheme )
idAccessor_h( evaluationEnvironment, setEvaluationEnvironment )

@end
