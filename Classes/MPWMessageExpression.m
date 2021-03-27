/* MPWMessageExpression.m created by marcel on Tue 04-Jul-2000 */

#import "MPWMessageExpression.h"
#import "MPWEvaluator.h"
#import "MPWObjCGenerator.h"

#ifndef GNUSTEP
#include <objc/runtime.h>
#endif
#import <MPWFoundation/NSNil.h>


@interface NSObject(_evaluateIn)

-_evaluateIn:aContext;

@end


@implementation NSObject(evaluation)


-evaluate
{
	return [self evaluateIn:nil];
}

@end

@implementation MPWMessageExpression

idAccessor( receiver, setReceiver )
scalarAccessor( SEL, selector, setSelector )
objectAccessor( NSArray, args, setArgs )
scalarAccessor( const char*, _argtypes, setArgtypes )
scalarAccessor( char , returnType, setReturnType )

-initWithReceiver:newReceiver
{
    self=[super init];
    [self setReceiver:newReceiver];
    return self;
}

-(BOOL)isToken
{
    return NO;
}

-(NSString*)messageName
{
    return NSStringFromSelector([self selector]);
}

-(NSString*)messageNameForCompletion
{
    return [self messageName];
}

-(NSObject<MPWEvaluable>*)evaluateIn:aContext
{
	id retval = nil;
    @try {
        retval = [aContext sendMessage:selector to:receiver withArguments:args supersendInside:self.isSuper ? self.classOfMethod : nil];
    } @catch (id exception) {
        exception=[self handleOffsetsInException:exception];
        NSLog(@"exception sending message '%@': %@ offset: %@",NSStringFromSelector(selector) ,exception,[exception userInfo]);
        @throw  exception;
    }
    return retval;
}

-(void)addToVariablesWritten:(NSMutableSet*)variablesWritten
{
	[receiver addToVariablesWritten:variablesWritten];
	[[args do] addToVariablesWritten:variablesWritten];
}

-(void)addToVariablesRead:(NSMutableSet*)variablesRead
{
	[receiver addToVariablesRead:variablesRead];
	[[args do] addToVariablesRead:variablesRead];
}


-description
{
    return [NSString stringWithFormat:@"[receiver: %@, message: %@, args: %@]",
        receiver,NSStringFromSelector(selector),args];
}

-(void)generateObjectiveCOn:aGenerator
{
    [aGenerator writeMessage:NSStringFromSelector([self selector]) toReceiver:[self receiver] withArgs:[self args]];
}

-(const char*)argtypes
{
    return _argtypes ? _argtypes : "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";
}


-(void)dealloc
{
    [receiver release];
    [args release];
    [_classOfMethod release];
    [super dealloc];
}

@end

@implementation NSProxy(evaluate)

-evaluateIn:aContext
{
//    [NSException raise:@"help" format:@"evaluateInContext" ];
    return self;
}

@end

@implementation NSObject(_evaluateIn)

-_evaluateIn:aContext
{
    return [self evaluateIn:aContext];
}


@end
