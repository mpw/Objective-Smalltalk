//
//  MPWBlockContext.m
//  Arch-S
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import "MPWBlockContext.h"
#import "MPWStatementList.h"
#import "STEvaluator.h"
#import "STCompiler.h"
#import <MPWFoundation/MPWMapFilter.h>
#import "MPWBindingLegacy.h"
#import "MPWMethodHeader.h"
#import "MPWScriptedMethod.h"    // for stack-trace 

//#include <Block.h>
#import <objc/runtime.h>

@interface NSObject(MethodServeraddException)

+(void)addException:(NSException*)newException;

@end


@implementation MPWBlockContext

idAccessor( block, setBlock )
idAccessor( context, setContext )

typedef id (^SevenArgBlock)(id arg1, id arg2,id arg3, id arg4,id arg5 ,id arg6 ,id arg7);
typedef id (^SixArgBlock)(id arg1, id arg2,id arg3, id arg4, id arg5 ,id arg6 );
typedef id (^FiveArgBlock)(id arg1, id arg2,id arg3, id arg4, id arg5  );
typedef id (^FourArgBlock)(id arg1, id arg2,id arg3 , id arg4 );
typedef id (^ThreeArgBlock)(id arg1, id arg2,id arg3 );
typedef id (^TwoArgBlock)(id arg1, id arg2);
typedef id (^OneArgBlock)(id randomArgument);
typedef id (^ZeroArgBlock)(void);

typedef id (^ArrayArgBlock)(id blockSelf, NSArray* argsArray);


static ArrayArgBlock valueWithArgsBlock = (id)^(id blockSelf, NSArray *a){
//    NSLog(@"args: %@",a);
    switch (a.count ) {
        case 0:
            return ((ZeroArgBlock)blockSelf)();
        case 1:
            return ((OneArgBlock)blockSelf)( a[0]);
        case 2:
            return ((TwoArgBlock)blockSelf)( a[0],a[1]);
        case 3:
            return ((ThreeArgBlock)blockSelf)( a[0],a[1],a[2]);
        case 4:
            return ((FourArgBlock)blockSelf)( a[0],a[1],a[2],a[3]);
        case 5:
            return ((FiveArgBlock)blockSelf)( a[0],a[1],a[2],a[3],a[4]);
        case 6:
            return ((SixArgBlock)blockSelf)( a[0],a[1],a[2],a[3],a[4],a[5]);
        default:
//            NSLog(@"blocks with %d args not supported",(int)a.count);
            return ((SixArgBlock)blockSelf)( a[0],a[1],a[2],a[3],a[4],a[5]);
    }
};

+(void)initialize
{
    static int initialized=NO;
    if  ( !initialized) {
        Class blockClass=NSClassFromString(@"NSBlock");
        IMP oneArgImp=imp_implementationWithBlock( ^(id blockSelf, id argument){ ((OneArgBlock)blockSelf)(argument); } );
        class_addMethod(blockClass, @selector(value:), oneArgImp, "@@:@");
        IMP zeroArgImp=imp_implementationWithBlock( ^(id blockSelf){ ((ZeroArgBlock)blockSelf)(); } );
        class_addMethod(blockClass, @selector(value), zeroArgImp, "@@:");
        IMP varArgImp=imp_implementationWithBlock( valueWithArgsBlock );
        class_addMethod(blockClass, @selector(valueWithObjects:), varArgImp, "@@:@");
        initialized=YES;
    }
}

-initWithBlock:aBlock context:aContext
{
	self=[super init];
	[self setBlock:aBlock];
    numParams=(int)[[self formalParameters] count];
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
		localContextClass=[STCompiler class];
	}
	return localContextClass;
}


-freshExecutionContextForRealLocalVars
{
    //    NSLog(@"creating new context from context: %@",[self context]);
    STEvaluator *evalContext= [[[[self contextClass] alloc] initWithParent:[self context]] autorelease];

    
    return evalContext;
}

-evaluationContext
{
#if 0
    return [self context];
#else
    STEvaluator *evalContext=[self freshExecutionContextForRealLocalVars];
    return evalContext;
#endif
}


-evaluateIn_block:aContext arguments:(NSArray*)args {
    id returnVal=nil;
    @autoreleasepool {

    int numArgs=(int)[args count];
    NSArray *formals=[[self block] arguments];
    int formalsCount = (int)[formals count];
    numArgs=MIN(numArgs,formalsCount);
    for (int i=0;i<numArgs;i++) {
        MPWBinding *b=[aContext createLocalBindingForName:[formals objectAtIndex:i]];
        [b setValue:[args objectAtIndex:i]];
//        [aContext bindValue:[args objectAtIndex:i] toVariableNamed:[formals objectAtIndex:i] withScheme:@"var"];
    }
    
    @try {
        if ( aContext ) {
            returnVal = [aContext evaluate:[[self block] statements]];
        } else {
            returnVal = [[[self block] statements] evaluateIn:aContext];
        }
    } @catch (NSException * exception) {
#if 0
        id trace = [[[exception callStackSymbols] mutableCopy] autorelease];
        if (trace) {
            [exception setCombinedStackTrace:trace];
        }
        NSLog(@"exception: %@ at %@",exception,[exception combinedStackTrace]);
        Class c=NSClassFromString(@"MethodServer");
        [c addException:exception];
        NSLog(@"added exception to %@",c);
#else
        @throw exception;
#endif
    }
        [returnVal retain];
//        NSLog(@"will autorelease after block eval");
    }
//    NSLog(@"did autorelease after block eval");

    return [returnVal autorelease];
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
    for (long i=0,max=[formalParameters count];i<max;i++ ) {
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
    return [MPWMapFilter filterWithBlock:self];
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

-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%p: block: %@>",[self class],self,block];
}


@end

@implementation STEvaluator(autorelease)

-(void)autoreleased:(ZeroArgBlock)block
{
    @autoreleasepool {  block(); }
}

@end 

#import "STCompiler.h"

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
    IDEXPECT([STCompiler evaluate:@"a:=0. #( 1, 2, 3, 4 ) enumerateObjectsUsingBlock:{ a := a+1. }. a."], [NSNumber numberWithInt:4], @"just counted the elements in an array using block enumeration");
}

+(void)testObjcBlocksWithObjectArgsAreMapped
{
    IDEXPECT([STCompiler evaluate:@"a:=0. #( 1, 2, 3, 4 ) enumerateObjectsUsingBlock:{ :obj |  a := a+obj. }. a."], [NSNumber numberWithInt:10], @"added the elements in an array using block enumeration");
}


+(void)testBlockArgsDontMessWithEnclosingScope
{
    IDEXPECT([STCompiler evaluate:@"a:=3. block:={ :a| a+10. }. block value:42. a."], [NSNumber numberWithInt:3], @"local var");
}
typedef id  (^idBlock)(id arg );

+(void)testSTBlockAsObjCBlock
{
    MPWBlockContext *stblock = [STCompiler evaluate:@"{ :a| a+10. }"];
    IDEXPECT([stblock class],self, @"class");
    idBlock objcBlock=(idBlock)stblock;
    NSNumber *val=@(12);
    NSNumber *retval=objcBlock(val);
    IDEXPECT(retval, @(22), @"retval");
    
    
}

+(void)testCopiedSTBlockAsObjCBlock
{
    idBlock copiedBlock=nil;
    MPWBlockContext *stblock = [STCompiler evaluate:@"{ :a| a+10. }"];
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
        MPWBlockContext *stblock = [STCompiler evaluate:@"{ :a| a+10 .}"];
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
        MPWBlockContext *stblock = [STCompiler evaluate:@"{ :a| a+10. }"];
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
    MPWBlockContext *stblock = [STCompiler evaluate:@"{ 42. }"];
    [stblock installInClass:[NSNumber class] withSignature:"@@:@" selector:@selector(theAnswer)];
    id theAnswer=[@(2) theAnswer];
    IDEXPECT(theAnswer, @(42), @"theAnswer");
}

+(void)testBlockAsMethodWithSelfAsArg
{
    MPWBlockContext *stblock = [STCompiler evaluate:@"{ :self | self + 42. }"];
    [stblock installInClass:[NSNumber class] withSignature:"@@:@" selector:@selector(answerPlus)];
    id theAnswer=[@(2) answerPlus];
    IDEXPECT(theAnswer, @(44), @"theAnswer");
}


+(void)testBlockAsMethodWithArg
{
    MPWBlockContext *stblock = [STCompiler evaluate:@"{ :self :arg | arg + 42. }"];
    [stblock installInClass:[NSNumber class] withSignature:"@@:@@" selector:@selector(answerPlus:)];
    id theAnswer=[@(2) answerPlus:@(10)];
    IDEXPECT(theAnswer, @(52), @"theAnswer");
}

+(void)testBlockAsMethodWithIntReturn
{
    MPWBlockContext *stblock = [STCompiler evaluate:@"{ 42. }"];
    [stblock installInClass:[NSNumber class] withSignature:"i@:" selector:@selector(theIntAnswer)];
//    NSLog(@"=== should convert to int");
    int theAnswer=[@(2) theIntAnswer];
    INTEXPECT(theAnswer, 42, @"theAnswer");
}

+(void)testBlockAsMethodWithMethodHeader
{
    MPWBlockContext *stblock = [STCompiler evaluate:@"{ :self :arg | self + 13 + (arg * 2). }"];
    [stblock installInClass:[NSNumber class] withMethodHeaderString:@"<int>addThirtenAndArgToSelf:<int>anArg"];
//    NSLog(@"=== should convert to int");
    int theAnswer=[@(2) addThirtenAndArgToSelf:7];
    INTEXPECT(theAnswer, 13+2+(7*2), @"theAnswer");
}



+(NSArray*)testSelectors
{
    return @[
            @"testObjcBlocksWithNoArgsAreMapped",
            @"testObjcBlocksWithObjectArgsAreMapped", 
            @"testBlockArgsDontMessWithEnclosingScope",
            @"testSTBlockAsObjCBlock",
            @"testCopiedSTBlockAsObjCBlock",
            @"testRetainedSTBlockOriginalAutoreleased",
//            @"testBlock_copiedSTBlockOriginalAutoreleased",
            @"testBlockInstalledAsMethod",
            @"testBlockAsMethodWithSelfAsArg",
            @"testBlockAsMethodWithArg",
            @"testBlockAsMethodWithArg",
            @"testBlockAsMethodWithIntReturn",
            @"testBlockAsMethodWithMethodHeader",
//            @"testAnonymousBlockParamsWorkWith",
            ];
}

@end
