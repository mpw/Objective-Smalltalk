//
//  MPWBlockContext.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import "MPWBlockContext.h"
#import "MPWStatementList.h"
#import "MPWEvaluator.h"
#import <MPWFoundation/MPWBlockFilterStream.h>
#import "MPWBinding.h"
#import "MPWMethodHeader.h"

#include <Block.h>
#import <objc/runtime.h>

@implementation MPWBlockContext

idAccessor( block, setBlock )
idAccessor( context, setContext )

typedef id (^OneArgBlock)(id randomArgument);
typedef id (^ZeroArgBlock)(void);

+(void)initialize
{
    static int initialized=NO;
    if  ( !initialized) {
        Class blockClass=NSClassFromString(@"NSBlock");
        IMP theImp=imp_implementationWithBlock( ^(id blockSelf, id argument){ ((OneArgBlock)blockSelf)(argument); } );
        class_addMethod(blockClass, @selector(value:), theImp, "@@:@");
        initialized=YES;
    }
}

-initWithBlock:aBlock context:aContext
{
	self=[super init];
	[self setBlock:aBlock];
	[self setContext:aContext];
	return self;
}

+blockContextWithBlock:aBlock context:aContext
{
	return [[[self alloc] initWithBlock:aBlock context:aContext] autorelease];
}


-contextClass
{
	id localContextClass=[[self context] class];
	if ( !localContextClass) {
		localContextClass=[MPWEvaluator class];
	}
	return localContextClass;
}


-freshExecutionContextForRealLocalVars
{
    //	NSLog(@"creating new context from context: %@",[self context]);
	MPWEvaluator *evalContext= [[[[self contextClass] alloc] initWithParent:[self context]] autorelease];

    
    return evalContext;
}

-evaluationContext
{
#if 0
    return [self context];
#else
    MPWEvaluator *evalContext=[self freshExecutionContextForRealLocalVars];
    return evalContext;
#endif
}


-evaluateIn_block:aContext arguments:(NSArray*)args {
    int numArgs=[args count];
    NSArray *formals=[[self block] arguments];
    numArgs=MIN(numArgs,[formals count]);
    id returnVal=nil;
    for (int i=0;i<numArgs;i++) {
        MPWBinding *b=[aContext createLocalBindingForName:[formals objectAtIndex:i]];
        [b bindValue:[args objectAtIndex:i]];
//        [aContext bindValue:[args objectAtIndex:i] toVariableNamed:[formals objectAtIndex:i]];
    }
    
    @try {
        if ( aContext ) {
            returnVal = [aContext evaluate:[[self block] statements]];
        } else {
            returnVal = [[[self block] statements] evaluateIn:aContext];
        }
    } @catch (NSException * exception) {
#if 1
        [exception setCombinedStackTrace:[exception callStackSymbols]];
        NSLog(@"exception: %@ at %@",exception,[exception combinedStackTrace]);
        Class c=NSClassFromString(@"MethodServer");
        [c addException:exception];
        NSLog(@"added exception to %@",c);
#else
        @throw newException;
#endif
    }
    return returnVal;
}

-(NSArray*)formalParameters
{
    return [[self block] arguments];
}

-invokeWithTarget1:aTarget args:(va_list)args
{
    NSArray* formalParameters = [self formalParameters];
    NSLog(@"%d parameters",(int)[formalParameters count]);
    NSMutableArray *argArray=[NSMutableArray arrayWithCapacity:[formalParameters count]];
    for (int i=0,max=[formalParameters count];i<max;i++ ) {
        [argArray addObject:va_arg(args, id)];
    }
    return [self evaluateIn_block:[self evaluationContext] arguments:argArray];

}

-invokeOn:target withFormalParameters:formalParameters actualParamaters:parameters
{
    return [self evaluateIn_block:[self evaluationContext] arguments:parameters];
}




-invokeWithArgs:(va_list)args
{
	return [self invokeWithTarget:nil args:args];
}


-value
{
	return [self evaluateIn_block:[self evaluationContext] arguments:nil];
}

-valueWithObjects:(NSArray*)args
{
    return [self evaluateIn_block:[self evaluationContext] arguments:args];
}

-value:anObject
{
    return [self valueWithObjects:@[ anObject]];
}


-value:anObject with:otherObject
{
    return [self valueWithObjects:@[ anObject , otherObject]];
}



-(void)drawOnContext:aContext
{
    [self value:aContext];
}

-whileTrue:anotherBlock
{
    id retval=nil;
	while ( [[self value] boolValue] ) {
		retval=[anotherBlock value];
	}
    return retval;
}

-copyWithZone:aZone
{
    return [self retain];
}

-copy
{
    return [self retain];
}

-(void)dealloc
{
	[block release];
	[context release];
	[super dealloc];
}



-defaultComponentInstance

{
    MPWBlockFilterStream *s=[MPWBlockFilterStream stream];
    [s setBlock:self];
    return s;
}



-(void)installInClass:(Class)aClass withMethodHeaderString:(NSString*)methodHeaderString
{
    MPWMethodHeader *header=[MPWMethodHeader methodHeaderWithString:methodHeaderString];
    NSString *typeString=[header typeString];
    NSString *methodName=[header methodName];
    
    //--- account for the mapping of arguments from method to block
    //--- by imp_implementationWithBloc()
    
    typeString = [[[typeString substringToIndex:3] stringByAppendingString:@"@"] stringByAppendingString:[typeString substringFromIndex:3]];
    [self installInClass:aClass withSignatureString:typeString selectorString:methodName];
    
}




@end

@implementation MPWEvaluator(autorelease)

-(void)autoreleased:(ZeroArgBlock)block
{
    @autoreleasepool {  block(); }
}

@end 

#import "MPWStCompiler.h"

@interface NSNumber(methodsAddedByBlockTest)

-(int)theIntAnswer;
-theAnswer;
-answerPlus;
-answerPlus:arg;
-(int)addThirtenAndArgToSelf:(int)anArg;

@end

@implementation MPWBlockContext(tests)

+(void)testObjcBlocksWithNoArgsAreMapped
{
    IDEXPECT([MPWStCompiler evaluate:@"a:=0. #( 1 2 3 4 ) enumerateObjectsUsingBlock:[ a := a+1. ]. a."], [NSNumber numberWithInt:4], @"just counted the elements in an array using block enumeration");
}

+(void)testObjcBlocksWithObjectArgsAreMapped
{
    IDEXPECT([MPWStCompiler evaluate:@"a:=0. #( 1 2 3 4 ) enumerateObjectsUsingBlock:[ :obj |  a := a+obj. ]. a."], [NSNumber numberWithInt:10], @"added the elements in an array using block enumeration");
}


+(void)testBlockArgsDontMessWithEnclosingScope
{
    IDEXPECT([MPWStCompiler evaluate:@"a:=3. block:=[:a| a+10]. block value:42. a."], [NSNumber numberWithInt:3], @"local var");
}
typedef id  (^idBlock)(id arg );

+(void)testSTBlockAsObjCBlock
{
    MPWBlockContext *stblock = [MPWStCompiler evaluate:@"[:a| a+10]"];
    IDEXPECT([stblock class],self, @"class");
    idBlock objcBlock=(idBlock)stblock;
    NSNumber *val=@(12);
    NSNumber *retval=objcBlock(val);
    IDEXPECT(retval, @(22), @"retval");
    
    
}

+(void)testCopiedSTBlockAsObjCBlock
{
    idBlock copiedBlock=nil;
    MPWBlockContext *stblock = [MPWStCompiler evaluate:@"[:a| a+10]"];
    IDEXPECT([stblock class],self, @"class");
    INTEXPECT([stblock retainCount], 1, @"retainCount");
        idBlock objcBlock=(idBlock)stblock;

        copiedBlock=Block_copy(objcBlock);
    NSNumber *retval=copiedBlock(@(12));
    IDEXPECT(retval, @(22), @"retval");
    Block_release(copiedBlock);
    
    
}

#ifndef __clang_analyzer__
// This test leaks, but it's supposed to do so

+(void)testRetainedSTBlockOriginalAutoreleased
{
    idBlock copiedBlock=nil;
    @autoreleasepool {
        MPWBlockContext *stblock = [MPWStCompiler evaluate:@"[:a| a+10]"];
        IDEXPECT([stblock class],self, @"class");
        idBlock objcBlock=(idBlock)stblock;
        copiedBlock=[objcBlock retain];
    }
    NSNumber *retval=copiedBlock(@(12));
    IDEXPECT(retval, @(22), @"retval");
    Block_release(copiedBlock);
}

#endif

+(void)testBlock_copiedSTBlockOriginalAutoreleased
{
    idBlock copiedBlock=nil;
    @autoreleasepool {
        MPWBlockContext *stblock = [MPWStCompiler evaluate:@"[:a| a+10]"];
        IDEXPECT([stblock class],self, @"class");
        INTEXPECT([stblock retainCount], 1, @"retainCount");
        idBlock objcBlock=(idBlock)stblock;
        INTEXPECT([stblock retainCount], 1, @"retainCount");
        copiedBlock=Block_copy(objcBlock);

    }
    NSNumber *retval=copiedBlock(@(12));
    IDEXPECT(retval, @(22), @"retval");
    Block_release(copiedBlock);
    INTEXPECT([copiedBlock retainCount], 1, @"retainCount");
   
    
}

+(void)testBlockInstalledAsMethod
{
    MPWBlockContext *stblock = [MPWStCompiler evaluate:@"[ 42 ]"];
    [stblock installInClass:[NSNumber class] withSignature:"@@:@" selector:@selector(theAnswer)];
    id theAnswer=[@(2) theAnswer];
    IDEXPECT(theAnswer, @(42), @"theAnswer");
}

+(void)testBlockAsMethodWithSelfAsArg
{
    MPWBlockContext *stblock = [MPWStCompiler evaluate:@"[ :self | self + 42. ]"];
    [stblock installInClass:[NSNumber class] withSignature:"@@:@" selector:@selector(answerPlus)];
    id theAnswer=[@(2) answerPlus];
    IDEXPECT(theAnswer, @(44), @"theAnswer");
}


+(void)testBlockAsMethodWithArg
{
    MPWBlockContext *stblock = [MPWStCompiler evaluate:@"[ :self :arg | arg + 42. ]"];
    [stblock installInClass:[NSNumber class] withSignature:"@@:@@" selector:@selector(answerPlus:)];
    id theAnswer=[@(2) answerPlus:@(10)];
    IDEXPECT(theAnswer, @(52), @"theAnswer");
}

+(void)testBlockAsMethodWithIntReturn
{
    MPWBlockContext *stblock = [MPWStCompiler evaluate:@"[ 42 ]"];
    [stblock installInClass:[NSNumber class] withSignature:"i@:" selector:@selector(theIntAnswer)];
    NSLog(@"=== should convert to int");
    int theAnswer=[@(2) theIntAnswer];
    INTEXPECT(theAnswer, 42, @"theAnswer");
}

+(void)testBlockAsMethodWithMethodHeader
{
    MPWBlockContext *stblock = [MPWStCompiler evaluate:@"[ :self :arg | self + 13 + (arg * 2)]"];
    [stblock installInClass:[NSNumber class] withMethodHeaderString:@"<int>addThirtenAndArgToSelf:<int>anArg"];
//    NSLog(@"=== should convert to int");
    int theAnswer=[@(2) addThirtenAndArgToSelf:7];
    INTEXPECT(theAnswer, 13+2+(7*2), @"theAnswer");
}



+(NSArray*)testSelectors
{
    return [NSArray arrayWithObjects:
            @"testObjcBlocksWithNoArgsAreMapped",
            @"testObjcBlocksWithObjectArgsAreMapped",
            @"testBlockArgsDontMessWithEnclosingScope",
            @"testSTBlockAsObjCBlock",
            @"testCopiedSTBlockAsObjCBlock",
            @"testRetainedSTBlockOriginalAutoreleased",
            @"testBlock_copiedSTBlockOriginalAutoreleased",
            @"testBlockInstalledAsMethod",
            @"testBlockAsMethodWithSelfAsArg",
            @"testBlockAsMethodWithArg",
            @"testBlockAsMethodWithArg",
            @"testBlockAsMethodWithIntReturn",
            @"testBlockAsMethodWithMethodHeader",
            nil];
}

@end
