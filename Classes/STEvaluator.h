//
//  MPWEvaluator.h
//  Arch-S
//
//  Created by Marcel Weiher on 30/11/2004.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWBinding,MPWScheme,MPWSchemeScheme;

@interface STEvaluator : MPWObject {
	id localVars;
	id parent;
	id messageCache;
	id _schemes;
    id homeContext;
    NSMutableDictionary *bindingCache;
}


-initWithParent:aParent;

-(void)bindValue:value toVariableNamed:(NSString*)variableName;
-(void)bindValue:value toVariableNamed:(NSString*)variableName withScheme:scheme;

-(MPWSchemeScheme*)createSchemes;

@property (nonatomic, retain) id schemes;
@property (nonatomic, assign) Class contextClass;

-valueOfVariableNamed:aName;
-(MPWBinding*)bindingForLocalVariableNamed:(NSString*)localVarName;
-(MPWBinding*)cachedBindingForName:aName;
-(void)cacheBinding:(MPWBinding*)binding forName:aName;

//-valueOfVariableNamed:aName withScheme:scheme;
-(MPWBinding*)createLocalBindingForName:(NSString*)variableName;
-(NSString*)defaultScheme;

-valueForUndefinedVariableNamed:aName;

-evaluate:expr;
-evaluateScript:aString onObject:anObject;
-evaluate:aScriptString withFormalParameterList:formalParameterList actualParameters:parameterList;
-evaluateScript:script onObject:target formalParameters:formals parameters:params;

-evaluateScriptString:(NSString*)scriptString;

-sendMessage:(SEL)selector to:receiver withArguments:args supersend:(BOOL)isSuper;
-(MPWScheme*)schemeForName:schemeName;
-localVars;


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
