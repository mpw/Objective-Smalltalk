//
//  MPWEvaluator.m
//  MPWTalk
//
//  Created by Marcel Weiher on 30/11/2004.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import "MPWEvaluator.h"
#import "MPWBinding.h"
#import "MPWInterval.h"
#import <MPWFoundation/NSNil.h>
#import <MPWFoundation/MPWByteStream.h>
#import "MPWMessage.h"
#import "MPWClassScheme.h"
#import <ObjectiveSmalltalk/MPWExpression.h>
#import "MPWVARBinding.h"
#import "MPWRefScheme.h"
#import "MPWSchemeScheme.h"
#import "MPWVarScheme.h"
#import "MPWSELScheme.h"

@implementation NSNumber(controlStructures)


-to:otherNumber
{
    return [MPWInterval intervalFrom:self to:otherNumber];
}


-to:otherNumber by:stepNumber
{
    return [MPWInterval intervalFrom:self to:otherNumber step:stepNumber];
}

-max:otherNumber
{
	if ( [self doubleValue] < [otherNumber doubleValue] ) {
		return otherNumber;
	} else {
		return self;
	}
}

-to:otherNumber do:aBlock
{
    return [[self to:otherNumber] do:aBlock];
}

-to:otherNumber by:stepNumber do:aBlock
{
    return [[self to:otherNumber by:stepNumber] do:aBlock];
}


-ifTrue:trueBlock ifFalse:falseBlock
{
	id blockToEval;
	if ( [self boolValue] ) {
		blockToEval=trueBlock;
	} else {
		blockToEval=falseBlock;
	}
	return [blockToEval value];
}

-ifTrue:trueBlock
{
	return [self ifTrue:trueBlock ifFalse:nil];
}

-ifFalse:falseBlock
{
	return [self ifTrue:nil ifFalse:falseBlock];
}

@end



@implementation MPWEvaluator

idAccessor( _schemes, setSchemes )

-createSchemes
{
	MPWSchemeScheme *schemes=[[[MPWSchemeScheme alloc] init] autorelease];
	id varScheme = [[MPWVarScheme new] autorelease];
	[schemes setSchemeHandler:varScheme forSchemeName:@"var"];
	[schemes setSchemeHandler:[[MPWClassScheme new] autorelease] forSchemeName:@"class"];
	[schemes setSchemeHandler:[[MPWRefScheme new] autorelease] forSchemeName:@"ref"];
	[schemes setSchemeHandler:[[MPWSELScheme new] autorelease] forSchemeName:@"sel"];
	[schemes setSchemeHandler:schemes forSchemeName:@"scheme"];
	[schemes setSchemeHandler:varScheme forSchemeName:@"default"];
	return schemes;
}

-schemes
{
	if ( ![self _schemes] ) {
		[self setSchemes:[self createSchemes]];
	}
	return [self _schemes];
}

idAccessor( localVars, setLocalVars )
-initWithParent:aParent

{
    self=[super init];
	[self setSchemes:[aParent schemes]];
	[self setLocalVars:[NSMutableDictionary dictionary]];
	[self bindValue:[NSNumber numberWithBool:YES] toVariableNamed:@"true"];
	[self bindValue:[NSNumber numberWithBool:NO] toVariableNamed:@"false"];
	[self bindValue:[NSNil nsNil] toVariableNamed:@"nil"];
//	[self bindValue:self toVariableNamed:@"context"];
	[self bindValue:[MPWByteStream Stdout] toVariableNamed:@"stdout"];
	parent = aParent;
    return self;
}

-init
{
	return [self initWithParent:nil];
}

-bindingClass
{
	return [MPWBinding class];
}


-evaluate:expr
{
    return [expr evaluateIn:self];
}



-schemeForName:schemeName
{
	id scheme;
	if ( !schemeName ) {
		schemeName=[self defaultScheme];
	}
	scheme=[[self schemes] objectForKey:schemeName];
	return scheme;
}

-makeLocalBindingNamed:(NSString*)bindingName
{
    return [[[self bindingClass] new] autorelease];
}

-(void)bindValue:value toVariableNamed:(NSString*)variableName withScheme:scheme
{
	id binding=[[self schemeForName:scheme] bindingForName:variableName inContext:self];
	if ( !binding ) {
		binding = [self makeLocalBindingNamed:variableName];
		[localVars setObject:binding forKey:variableName];
	}
	[binding bindValue:value];
}

-(NSString*)defaultScheme
{
	return @"default";
}

-(void)bindValue:value toVariableNamed:(NSString*)variableName
{
	[self bindValue:value toVariableNamed:variableName withScheme:[self defaultScheme]];
}

-(void)applyParameters:parameterList forFormals:formalParameterList
{
	int i;
	for (i=0;i<[formalParameterList count];i++) {
		[self bindValue:[parameterList objectAtIndex:i] toVariableNamed:[formalParameterList objectAtIndex:i]];
	}
}



-evaluate:aScriptString withFormalParameterList:formalParameterList actualParameters:parameterList
{
	[self applyParameters:parameterList forFormals:formalParameterList];
	return [self evaluateScriptString:aScriptString];
}

-evaluateScriptString:(NSString*)aString
{
	return [self evaluate:aString];
}

-evaluateScript:aString onObject:anObject
{
	[self bindValue:anObject toVariableNamed:@"self"];
    id result=nil;
	//	NSLog(@"evaluate script '%@' on object: %@",aString,anObject);
    @try {
         result =  [self evaluateScriptString:aString];
    }
    @finally {
        [self bindValue:nil toVariableNamed:@"self"];
    }
    return result;
}

-evaluateScript:script onObject:target formalParameters:formals parameters:params
{
	[self applyParameters:params forFormals:formals];
//	NSLog(@"context %x will evaluate",self);
	return [self evaluateScript:script onObject:target];
}

-(void)evaluatedArgs:args into:(id*)evaluated
{
    int i,max;
    for (i=0,max=[args count]; i<max;i++ ) {
		id evalResult = [self evaluate:[args objectAtIndex:i]];
		if ( ![evalResult isNotNil] ) {
			evalResult=[NSNil nsNil];
		}
		evaluated[i]=evalResult;
//       [evaluated addObject:evalResult];
    }
//    return evaluated;
}

-messageForSelector:(SEL)selector initialReceiver:receiver
{
	id messageName = NSStringFromSelector( selector );
	id message;
	if ( !messageCache ) {
		messageCache=[[NSMutableDictionary alloc] init];
	}
	message = [messageCache objectForKey:messageName];
	if ( !message )  {
		message=[MPWMessage messageWithSelector:selector initialReceiver:receiver];
		[messageCache setObject:message forKey:messageName];
	}
	return message;
}

-sendMessage:(SEL)selector to:receiver withArguments:args
{	
	id nilValue = [NSNil nsNil];
	id returnValue = nilValue;
	id evaluatedReceiver = [self evaluate:receiver];
	id evaluatedArgs[[args count]+5];
	[self evaluatedArgs:args into:evaluatedArgs];
	id message = [self messageForSelector:selector initialReceiver:evaluatedReceiver];
	if ( evaluatedReceiver == nil && [nilValue respondsToSelector:selector]) {
		evaluatedReceiver = nilValue;
	}
//	returnValue = objc_msgSend( evaluatedReceiver, selector, evaluatedArgs[0], evaluatedArgs[1], evaluatedArgs[2] );
	returnValue =[evaluatedReceiver receiveMessage:message withArguments:evaluatedArgs count:[args count]];
	if ( returnValue == nil  ) {
		returnValue = nilValue;
	}
	return returnValue;
}


-valueForClassNamed:aName
{
    return NSClassFromString( aName ); 
}

-(BOOL)tryLocalMessageForUnboundSelectors
{
    return YES;
}

-valueForUndefinedVariableNamed:aName
{
	SEL sel= NSSelectorFromString(aName);
	BOOL found=NO;
    id retval;
    if ( [self tryLocalMessageForUnboundSelectors] && sel && [self respondsToSelector:sel] ) {
        retval = [self performSelector:sel];
		found = YES;
    } else {
        retval = [self valueForClassNamed:aName];
		found = retval != nil;
    }
	if ( !found ) {
        NSLog(@"Unknown identifier '%@'",aName);
		[NSException raise:@"unknownidentifer" format:@"Unknown identifier '%@'",aName];
	}
    return retval;
}


-valueOfVariableNamed_disabled:aName withScheme:scheme
{
	id value=nil;
	id binding=nil;
//	NSLog(@"context %x retrieving variable named '%@', len: %d",self,aName,[aName length]);
	if ( nil != (binding=[[self schemeForName:scheme]  bindingForName:aName inContext:self])) {
		value=[binding value];
	} else {
//		NSLog(@"context %x localVars: %@",self,localVars);
        value = [self valueForUndefinedVariableNamed:aName];
	}
	if ( ![value isNotNil] ) {
		value=nil;
	}
	return value;
}

-valueOfVariableNamed:aName
{
    id value = [[[self localVars] objectForKey:aName] value];
    if ( !value && [aName isEqual:@"context"]) {
        value=self;
    }
//	return [self valueOfVariableNamed:aName withScheme:[self defaultScheme]];
}


-(void)dealloc
{
    [localVars release];
    [super dealloc];
}


@end

