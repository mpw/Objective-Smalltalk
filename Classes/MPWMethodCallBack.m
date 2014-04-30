//
//  MPWMethodCallBack.m
//  MPWTalk
//
//  Created by Marcel Weiher on 22/04/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//
//	Installs scripts directly into the Objective-C runtime,
//	using call-back functions as glue. The callbacks retrieve
//	information from the object by getting the entry point
//	of the method (using PC-relative addressing), from which
//  they then derive other pointers (every callback is copied
//	into its own object)
//


#import "MPWMethodCallBack.h"
#import "MPWMethodHeader.h"
#import "MPWScriptedMethod.h"
#import "MPWStCompiler.h"
#import <ObjectiveSmalltalk/MPWMethod.h>
#import <objc/objc.h>
#import <objc/runtime.h>
#import <stdarg.h>
#import <MPWFoundation/NSNil.h>
#if 0 // !TARGET_OS_IPHONE 
#import <PLBlockIMP/PLBlockIMP.h>
#endif

@implementation MPWMethodCallBack


//idAccessor( context, setContext )
idAccessor( method, _setMethod )

-script
{
	return [[self method] script];
}

-header
{
	return [[self method] header];
}


-(void)setName:(NSString*)newName
{
//	[self _setName:newName];
	selname = NSSelectorFromString( newName );
	if ( !selname ) {
		selname = sel_registerName( [newName cStringUsingEncoding:NSASCIIStringEncoding] );
	}
}

-(Method)getMethodForMessage:(SEL)messageName inClass:(Class)aClass
{
    unsigned int methodCount=0;
    Method *methods = class_copyMethodList(aClass, &methodCount);
    Method result=NULL;
    
    if ( methods ) {
        for ( int i=0;i< methodCount; i++ ) {
            if ( method_getName(methods[i]) == messageName ) {
                result = methods[i];
                break;
            }
        }
        free(methods);
    }
   return result;
}

-(void)installInClass:(Class)aClass withSignature:(const char*)signature
{
	//--- setup the method structure
//    NSLog(@"install %@ in %@",NSStringFromSelector(selname),aClass);
	if ( aClass != nil ) {
		methodDescriptor=[self getMethodForMessage:selname inClass:aClass];
		
		if ( methodDescriptor ) {
			oldIMP= class_getMethodImplementation(aClass, selname);
		}
		//---   setup undo 
   
#if 1 // TARGET_OS_IPHONE        
		stub=imp_implementationWithBlock( self );
#else        
		stub=pl_imp_implementationWithBlock( self );
#endif	
		if ( methodDescriptor ) {
			method_setImplementation(methodDescriptor, (IMP)stub);
			installed = YES;
		} else {
			installed =  class_addMethod(aClass, selname, (IMP)stub, signature);
			methodDescriptor=class_getInstanceMethod( aClass, selname);

		}
		//		NSLog(@"did install: %d",installed);
		
        targetClass = aClass;
        
        
	} else {
		installed = NO;
	}
	
}

-(const char*)typeSignature
{
	const char *types = method_getTypeEncoding(methodDescriptor);
//	NSLog(@"%@ : %s",NSStringFromSelector(selname),types);
	return types;
}

-(void)uninstall
{
    if ( installed && methodDescriptor && oldIMP ) {
		method_setImplementation(methodDescriptor, oldIMP);
        installed=NO;
    }
}


-invokeWithArgs:(va_list)args
{
	id target=va_arg(args,id);
	return [self invokeWithTarget:target args:args];
}


-(IMP)function
{
	return (IMP)stub;
}

-(void)setMethod:aMethod
{
	[self _setMethod:aMethod];
	[self setName:[aMethod methodName]];
}

-methodForTarget:aTarget
{
    return [self method];
}

-(void)installInClass:(Class)aClass
{
	[self installInClass:aClass withSignature:[[self header] typeSignature]];
}

-formalParameters
{
	return [[self header] parameterNames];
}

-invokeOn:target withFormalParameters:formalParameters actualParamaters:parameters
{
	id returnVal=nil;
	@try {
        returnVal = [[self methodForTarget:target] evaluateOnObject:target parameters:parameters];
    } @catch (id exception) {
//        NSLog(@"exception %@ executing %@",exception,[self header]);
        @throw exception;
    }
	return returnVal;
}

-invokeOn:target
{
	return [self invokeOn:target withFormalParameters:nil actualParamaters:nil];
}


-(void)dealloc
{
/*	[context release];
	[script release];
	[name release];
	[super dealloc];
*/
	//-- can't release, installed in objc_runtime
	return;
	//-- make the naggy compiler happy
	[super dealloc];
}

-description
{
    return [NSString stringWithFormat:@"<%@:%p:  ",[self class],self];
}

@end

@interface __MPWMethodCallBackDummyTestClass : NSObject {}
-(id)answerToEverythingWillOverrideInSubclass;

@end

@implementation __MPWMethodCallBackDummyTestClass

-compile:aScript
{
	return aScript;
}

-evaluateScript:script onObject:target
{
	//	NSLog(@"evaluateScript!");
	return [NSString stringWithFormat:@"script: %@ target: %p",script, target];
}
-evaluateScript:script onObject:target formalParameters:formals parameters:params
{
	return [self evaluateScript:script onObject:target];
}

#ifdef __x86_64__
-(long long)answerToEverything
#else
-(int)answerToEverything
#endif
{
    return 42;
}

-(id)answerToEverythingWillOverrideInSubclass
{
    return @"43";
}

@end


@interface __MPWMethodCallBackDummyTestClass(silenceWarningsAboutMethodsWeWillDefineDynamically)

-xxxDummy2;
-xxxDummyMulti:anArg andMore:moreArgs;

@end

@interface __MPWMethodCallBackDummyTestClassSubclass : __MPWMethodCallBackDummyTestClass

@end

@implementation  __MPWMethodCallBackDummyTestClassSubclass 
@end


@implementation MPWMethodCallBack(testing)

+(void)testInstallWorks
{
	MPWMethodCallBack* callback=[[[self alloc] init] autorelease];
	id target =[[[__MPWMethodCallBackDummyTestClass alloc] init] autorelease];
	SEL selector;
	id method = [[[MPWScriptedMethod alloc] init] autorelease];
//	[method setContext:target];
	[callback setMethod:method];
	[callback setName:@"xxxDummy"];
	[callback installInClass:[target class] withSignature:"@@:"];
	selector = NSSelectorFromString(@"xxxDummy");
	NSAssert( selector != NULL, @"selector xxxDummy should now exist" );
	NSAssert( [target respondsToSelector:selector],@"callback doesn't respond to Selector" );
}

+(void)testActualCallbackViaMessageSend
{
	MPWMethodCallBack* callback=[[[self alloc] init] autorelease];
	id target =[[[__MPWMethodCallBackDummyTestClass alloc] init] autorelease];
	id returnValue;
	id expectedReturn = @"45"; // [target evaluateScript:@"45" onObject:target];
 	id method = [[[MPWScriptedMethod alloc] init] autorelease];
//	[method setContext:target];
 	[method setScript:@"45"];
	[callback setMethod:method];
	[callback setName:@"xxxDummy2"];
	[callback installInClass:[target class] withSignature:"@@:"];
	returnValue = [target xxxDummy2];
	IDEXPECT( returnValue, expectedReturn, @"expected return of install");
}

+(void)testMultiArgMessageSend
{
	MPWMethodCallBack* callback=[[[self alloc] init] autorelease];
	id target =[[[__MPWMethodCallBackDummyTestClass alloc] init] autorelease];
	id returnValue;
	id method = [[[MPWScriptedMethod alloc] init] autorelease];
//	[method setContext:target];
	[method setScript:@"dummyReturnValueInsteadOfActualMethodBody"];
	[callback setMethod:method];
	[callback setName:@"xxxDummyMulti:andMore:"];
	[callback installInClass:[target class] withSignature:"@@:@@"];
	returnValue = [target xxxDummyMulti:@"testArg1" andMore:@"testArg2"];
	IDEXPECT( returnValue, @"dummyReturnValueInsteadOfActualMethodBody", @"expected return of install");
}

+(void)testUndoOverride
{
	MPWMethodCallBack* callback=[[[self alloc] init] autorelease];
	id target =[[[__MPWMethodCallBackDummyTestClass alloc] init] autorelease];
	id returnValue;
	id initialReturn = (id)[target answerToEverything];
    id expectedReturnAfterOverride = @"45"; [target evaluateScript:@"45" onObject:target];
	id method = [[[MPWScriptedMethod alloc] init] autorelease];
//	[method setContext:target];
	[method setScript:@"45"];
//	[method setContext:target];
    [method setMethodHeader:[MPWMethodHeader methodHeaderWithString:@"<int>answerToEverything"]];
	[callback setMethod:method];
	[callback installInClass:[target class]];
	returnValue = (id)[target answerToEverything];
	NSLog(@"returnValue: %@ expectedReturnAfterOverride: %@",returnValue,expectedReturnAfterOverride);
	IDEXPECT( returnValue, expectedReturnAfterOverride, @"expected return after override");
    NSAssert1( returnValue != initialReturn, @"original return value not same as override: %d",(int)returnValue);
    [callback uninstall];
 	returnValue = (id)[target answerToEverything];
	INTEXPECT( (NSInteger)returnValue, (NSInteger)initialReturn, @"uninstall of method should yield original result");
}


+(void)testActualCallbackDirect
{
	MPWMethodCallBack* callback=[[[self alloc] init] autorelease];
	id target =[[[__MPWMethodCallBackDummyTestClass alloc] init] autorelease];
	id returnValue;
	id expectedReturn = @"45"; // [target evaluateScript:@"45" onObject:target];
	IMP function;
	id method = [[[MPWScriptedMethod alloc] init] autorelease];
//	[method setContext:target];
	[method setScript:@"45"];
    [method setMethodHeader:[MPWMethodHeader methodHeaderWithString:@"<int>answerToEverything"]];
	[callback setMethod:method];
	[callback setName:@"xxxDummy3"];
	[callback installInClass:[target class] withSignature:"@@:"];
	function = [callback function];
	returnValue = function( target, @selector(dummy3) );
	IDEXPECT( returnValue, expectedReturn, @"expected return of install");
}

+(void)testNewSubclassMethodDoesNotGoToSuperclassThatDefinesIt
{
	MPWMethodCallBack* callback=[[[self alloc] init] autorelease];
	id target =[[[__MPWMethodCallBackDummyTestClassSubclass alloc] init] autorelease];
	id superclassTarget =[[[__MPWMethodCallBackDummyTestClass alloc] init] autorelease];
	id returnValue;
	id expectedReturn = @"47"; // [target evaluateScript:@"45" onObject:target];
	id expectedSuperclassReturn = @"43"; // [target evaluateScript:@"45" onObject:target];
//	IMP function;
	id method = [[[MPWScriptedMethod alloc] init] autorelease];
    //	[method setContext:target];
	[method setScript:@"47"];
    [method setMethodHeader:[MPWMethodHeader methodHeaderWithString:@"answerToEverythingWillOverrideInSubclass"]];
	[callback setMethod:method];
	[callback setName:@"answerToEverythingWillOverrideInSubclass"];
    returnValue = (id)[target answerToEverythingWillOverrideInSubclass];
	IDEXPECT( returnValue, expectedSuperclassReturn, @"expected return for subclassbefore  we installed the method");

	[callback installInClass:[target class] withSignature:"@@:"];
//	function = [callback function];
//	returnValue = function( target, @selector(answerToEverythingWillOverrideInSubclass) );
    returnValue = (id)[target answerToEverythingWillOverrideInSubclass];

	IDEXPECT( returnValue, expectedReturn, @"expected return for subclass we installed the method in");
    returnValue = (id)[superclassTarget answerToEverythingWillOverrideInSubclass];
	IDEXPECT( returnValue, expectedSuperclassReturn, @"expected return for superclass that has the original method (and should not be overridden");
    
}

+(NSArray*)testSelectors
{
	return [NSArray arrayWithObjects:
		@"testInstallWorks",
		@"testActualCallbackDirect",
//		@"testUndoOverride",
		@"testActualCallbackViaMessageSend",
        @"testMultiArgMessageSend",
        @"testNewSubclassMethodDoesNotGoToSuperclassThatDefinesIt",
         nil
		];
}

@end
