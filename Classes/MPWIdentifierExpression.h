//
//  MPWVariableExpression.h
//  Arch-S
//
//  Created by marcel on Mon Jul 02 2001.
//  Copyright (c) 2001 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/STExpression.h>

@class MPWIdentifier;



@interface MPWIdentifierExpression : STExpression {
	MPWIdentifier*  identifier;
}

//idAccessor_h( name, setName )
//idAccessor_h( scheme, setScheme )
@property (nonatomic, strong)  id evaluationEnvironment;
objectAccessor_h(MPWIdentifier*, identifier, setIdentifier )
-evaluateAssignmentOf:value in:aContext;

-scheme;
-name;

-bindingWithContext:aContext;

@end
