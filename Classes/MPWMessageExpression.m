/* MPWMessageExpression.m created by marcel on Tue 04-Jul-2000 */

#import "MPWMessageExpression.h"
#import "STEvaluator.h"
#import "MPWObjCGenerator.h"
#import "MPWIdentifierExpression.h"
#import "MPWIdentifier.h"
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
{
}

idAccessor( receiver, setReceiver )
scalarAccessor( SEL, selector, setSelector )
objectAccessor(NSArray*, args, setArgs )
scalarAccessor( const char*, _argtypes, setArgtypes )
scalarAccessor( char , returnType, setReturnType )

-(instancetype)initWithReceiver:(STExpression*)newReceiver
{
    self=[super init];
    self.isSuperSend = newReceiver.isSuper;
    if ( self.isSuperSend) {
        MPWIdentifierExpression *ie=[[[MPWIdentifierExpression alloc] init] autorelease];
        [ie setIdentifier:[MPWIdentifier identifierWithName:@"self"]];
        newReceiver=ie;
    }
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
        retval = [aContext sendMessage:selector to:receiver withArguments:args supersend:self.isSuperSend];
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

-(void)accumulateBlocks:(NSMutableArray*)blocks
{
    [[self receiver] accumulateBlocks:blocks];
    for ( id arg in [self args] ) {
        [arg accumulateBlocks:blocks];
    }
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
