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
#import "MPWRefScheme.h"
#import "MPWSchemeScheme.h"
#import "MPWVarScheme.h"
#import "MPWFrameworkScheme.h"
#import "MPWSelfContainedBinding.h"
#import <MPWFoundation/MPWGenericReference.h>

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

-min:otherNumber
{
    if ( [self doubleValue] > [otherNumber doubleValue] ) {
        return otherNumber;
    } else {
        return self;
    }
}

-(void)to:otherNumber do:aBlock
{
    [[self to:otherNumber] do:aBlock];
}

-(void)to:otherNumber by:stepNumber do:aBlock
{
    [[self to:otherNumber by:stepNumber] do:aBlock];
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
    [varScheme setContext:self];
	[schemes setSchemeHandler:[[MPWClassScheme new] autorelease] forSchemeName:@"class"];
	[schemes setSchemeHandler:[[MPWRefScheme new] autorelease] forSchemeName:@"ref"];
	[schemes setSchemeHandler:schemes forSchemeName:@"scheme"];
	[schemes setSchemeHandler:varScheme forSchemeName:@"default"];
	[schemes setSchemeHandler:[MPWFrameworkScheme scheme] forSchemeName:@"framework"];
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
	[self bindValue:@YES toVariableNamed:@"true"];
	[self bindValue:@NO toVariableNamed:@"false"];
	[self bindValue:[NSNumber numberWithDouble:M_PI] toVariableNamed:[NSString stringWithFormat:@"%C",(unsigned short)960]];
	[self bindValue:[NSNil nsNil] toVariableNamed:@"nil"];
//	[self bindValue:self toVariableNamed:@"context"];
    id newStdout=[parent bindingForLocalVariableNamed:@"stdout"];
    if ( !newStdout) {
        newStdout=[MPWByteStream Stdout];
    }
	[self bindValue:newStdout toVariableNamed:@"stdout"];
    bindingCache=[NSMutableDictionary new];
	parent = aParent;
    return self;
}

-init
{
	return [self initWithParent:nil];
}

-bindingClass
{
	return [MPWSelfContainedBinding class];
}


-evaluate:expr
{
    return [expr evaluateIn:self];
}

-(MPWBinding*)cachedBindingForName:aName
{
    return [bindingCache objectForKey:aName];
}

-(void)cacheBinding:aBinding forName:aName
{
    if ( aBinding && aName) {
        [bindingCache setObject:aBinding forKey:aName];
    }
}

-(MPWBinding*)bindingForLocalVariableNamed:(NSString*)localVarName
{
    MPWBinding *binding=nil;
    if ( [localVarName isEqualToString:@"context"]) {
        binding=[[self bindingClass] bindingWithValue:self];
    } else {
        binding = [localVars objectForKey:localVarName];
    }
    if (! binding) {
        binding = [parent bindingForLocalVariableNamed:localVarName];
    }
    return binding;
}

-(MPWScheme*)schemeForName:schemeName
{
	MPWScheme* scheme;
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

-(MPWBinding*)createLocalBindingForName:(NSString*)variableName
{
    MPWBinding *binding = [self makeLocalBindingNamed:variableName];
    [localVars setObject:binding forKey:variableName];
    return binding;
}

-(void)bindValue:value toVariableNamed:(NSString*)variableName withScheme:schemeName
{
    MPWScheme* scheme=[self schemeForName:schemeName];
    if ( [scheme isKindOfClass:[MPWVarScheme class]]) {   // legacy workaround, FIXME
        MPWBinding* binding=[scheme bindingForName:variableName inContext:self];
        if ( !binding ) {
            binding = [self createLocalBindingForName:variableName];
        }
        [binding setValue:value];
    } else {            // the way it should be
        [scheme setObject:value forReference:[scheme referenceForPath:variableName]];
    }
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
    } @catch ( id exception) {
        NSLog(@"Exception %@ in evaluateScript",exception);
        @throw exception;
    }
    @finally {
//        [self bindValue:nil toVariableNamed:@"self"];
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
    for (int i=0,max=(int)[args count]; i<max;i++ ) {
//        NSLog(@"== will evaluate arg %d of %d: %@",i,max,[args objectAtIndex:i]);
		id evalResult = [self evaluate:[args objectAtIndex:i]];
//        NSLog(@"== did evaluate to %p, nil-check",evalResult);
		if ( [evalResult respondsToSelector:@selector(isNotNil)] && ![evalResult isNotNil] ) {
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
	id returnValue;
	id evaluatedReceiver = [self evaluate:receiver];
	id evaluatedArgs[[args count]+5];
	[self evaluatedArgs:args into:evaluatedArgs];
	id message = [self messageForSelector:selector initialReceiver:evaluatedReceiver];
	if ( evaluatedReceiver == nil && [nilValue respondsToSelector:selector]) {
		evaluatedReceiver = nilValue;
	}
//	returnValue = objc_msgSend( evaluatedReceiver, selector, evaluatedArgs[0], evaluatedArgs[1], evaluatedArgs[2] );
	returnValue =[evaluatedReceiver receiveMessage:message withArguments:evaluatedArgs count:(int)[args count]];
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
//        NSLog(@"Unknown identifier '%@'",aName);
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
//	value = [self valueOfVariableNamed:aName withScheme:[self defaultScheme]];
    return value;
}


-(void)dealloc
{
    [localVars release];
    [bindingCache release];
    [super dealloc];
}


@end


