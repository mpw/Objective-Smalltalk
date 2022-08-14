//
//  MPWVariableExpression.h
//  Arch-S
//
//  Created by marcel on Mon Jul 02 2001.
//  Copyright (c) 2001 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWExpression.h>

@class MPWIdentifier;



@interface MPWIdentifierExpression : MPWExpression {
	id	evaluationEnvironment;
	MPWIdentifier*  identifier;
}

//idAccessor_h( name, setName )
//idAccessor_h( scheme, setScheme )
idAccessor_h( evaluationEnvironment, setEvaluationEnvironment )
objectAccessor_h(MPWIdentifier*, identifier, setIdentifier )
-evaluateAssignmentOf:value in:aContext;

-scheme;
-name;

-bindingWithContext:aContext;

@end
