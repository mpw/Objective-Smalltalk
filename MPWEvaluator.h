//
//  MPWEvaluator.h
//  MPWTalk
//
//  Created by Marcel Weiher on 30/11/2004.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWEvaluator : MPWObject {
	id localVars;
	id parent;
	id messageCache;
	id _schemes;
}

-initWithParent:aParent;

-(void)bindValue:value toVariableNamed:(NSString*)variableName;
-(void)bindValue:value toVariableNamed:(NSString*)variableName withScheme:scheme;

-createSchemes;

-valueOfVariableNamed:aName;
-valueOfVariableNamed:aName withScheme:scheme;
-(NSString*)defaultScheme;

-valueForUndefinedVariableNamed:aName;

-evaluate:expr;
-evaluateScript:aString onObject:anObject;
-evaluate:aScriptString withFormalParameterList:formalParameterList actualParameters:parameterList;
-evaluateScript:script onObject:target formalParameters:formals parameters:params;

-evaluateScriptString:(NSString*)scriptString;

-sendMessage:(SEL)selector to:receiver withArguments:args;
-schemeForName:schemeName;


@end

@interface NSNumber(arithmetic)

-negated;
-add:otherNumber;
-mul:otherNumber;
-sub:otherNumber;
-div:otherNumber;
-(BOOL)isLessThan:other;
-(BOOL)isGreaterThan:other;
-to:otherNumber;			// creates an from the receiver to <otherNumber>
-to:otherNumber by:stepNumber;			// creates an from the receiver to <otherNumber>
-max:otherNumber;
@end

@interface NSNumber(conditionals)

-ifTrue:trueBlock ifFalse:falseBlock;
-ifTrue:trueBlock;
-ifFalse:falseBlock;

@end