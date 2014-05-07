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


-evaluateIn:aContext
{
    return self;
}

-evaluate
{
	return [self evaluateIn:nil];
}

@end

@implementation MPWMessageExpression

idAccessor( receiver, setReceiver )
scalarAccessor( SEL, selector, setSelector )
idAccessor( args, setArgs )

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
        retval = [aContext sendMessage:selector to:receiver withArguments:args];
    } @catch (id exception) {
        exception=[self handleOffsetsInException:exception];
//        NSLog(@"exception sending message: %@",exception);
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



-(void)dealloc
{
    [receiver release];
    [args release];
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
