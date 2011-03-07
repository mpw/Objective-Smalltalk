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
#import <MPWTalk/MPWMethod.h>
#import <objc/objc.h>
#import <objc/objc-runtime.h>
#import <stdarg.h>
#import <MPWFoundation/NSNil.h>
#import <sys/types.h>
#include <sys/mman.h>


#define SENTINEL1  12345678L
#define SENTINEL2  12345679L
#define SENTINEL3  12345689L

#define SENTINEL4  1122334455667788LL
#define SENTINEL5  1122334455667788LL
#define SENTINEL6  1122334455667788LL

id passMultiArgumentCallback( id self, SEL sel,id target, va_list ap) {
	NSLog(@"passMultiArgumentCallback");
	return [self invokeOn:target withVarArgs:ap];
}

@implementation MPWMethodCallBack


#if  __ppc__ || __x86_64__
//#warning now in ppc or x86_64
static id _callBackWithNoArgs( id target, SEL sel )
{
	CallBackBlock* callback = (CallBackBlock*) (((char*)_callBackWithNoArgs)-(sizeof (CallBackBlock) + PADSIZE));
//	NSLog(@"_callBackWithNoArgs");
	return callback->callBackFun( callback->selfPtr, @selector(invokeOn:) , target);
}

static id _callBackWithManyArgs( id target, SEL sel, ... )
{
    va_list ap;
	CallBackBlock* callback =(CallBackBlock*) (((char*)_callBackWithManyArgs)-(sizeof (CallBackBlock) + PADSIZE));
//	NSLog(@"_callBackWithNoArgs");
    va_start(ap,sel);
	return callback->callBackFun( callback->selfPtr, @selector(invokeOn:withVarArgs:), target, ap );
}

-(void)patchStub
{
	char *ptr=(char*)stub;
	mprotect( (void*)(((NSInteger)ptr) & ~4095) , 4096, PROT_EXEC|PROT_WRITE|PROT_READ );
}
#elif __i386__
//#warning 386

//	Trickery ahead!
//
//	both callbacks are templates that will be copied
//	they SENTINEL1 value will be replaced with the
//	actual pointer to the callback structure.
//
//	This assumes that the code-generated will 
//	support simply patching in that value.
//
//	The bogus if/then/else is required to
//	prevent the compiler from optimizing 
//	away the pointer-deference from what
//	it thinks is a constant value.


static id _callBackWithNoArgs( id target, SEL sel )
{
	int sentinel = SENTINEL1;
	CallBackBlock* callback; //=(void*)SENTINEL;
	if ( target ) {
		callback = (void*)sentinel;
	} else {
		callback = (void*)target;
	}
	return callback->callBackFun( callback->selfPtr,(void*)SENTINEL2, target);
}

static id _callBackWithManyArgs( id target, SEL sel, ... )
{
    va_list ap;
	int sentinel = SENTINEL1;
	CallBackBlock* callback;
	if ( target ) {
		callback = (void*)sentinel;
	} else {
		callback = (void*)target;
	}
    va_start(ap,sel);
	return callback->callBackFun( callback->selfPtr,(void*)SENTINEL3, target, ap );
}

-(void)patchStub
{
	char *ptr=(char*)stub,*stop=(char*)(stub+sizeof stub);
//	NSLog(@"will patch stub %x with %x",stub,&callback);
	while ( ptr < stop ) {
		if ( *(int*)ptr == SENTINEL1 ) {
			*(void**)ptr=&callback;
//			NSLog(@"did patch stub %x with %x",stub,&callback);
			return;
		}
		ptr++;
	}
}


#else
#error Callback hacks currently only support PowerPC and Intel i386
#endif



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

//idAccessor( formalParameters, setFormalParameters )
//objectAccessor( NSString*, name, _setName )
//idAccessor( header , _setHeader )



-(void)setName:(NSString*)newName
{
//	[self _setName:newName];
	selname = NSSelectorFromString( newName );
	if ( !selname ) {
		selname = sel_registerName( [newName cStringUsingEncoding:NSASCIIStringEncoding] );
	}
}

-(void)createStubAndSetupCallback
{
	BOOL isMultiArg = [self additionalArgs]>0;
//	NSLog(@"%s isMultiArg: %d",selname, isMultiArg);
	callback.selfPtr = self;
	if ( isMultiArg ) {
		memcpy( stub, _callBackWithManyArgs, sizeof stub );
	} else {
		memcpy( stub, _callBackWithNoArgs, sizeof stub );
	}
	[self patchStub];
	if ( isMultiArg) {
		callback.callBackFun = (IMP)passMultiArgumentCallback; 
	} else {
		callback.callBackFun = [self methodForSelector:@selector(invokeOn:)];
	}
	
	
}
-(int)additionalArgs
{
	return [[[self method] methodHeader] numArguments];
}

#if __OBJC2__ || ( MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 )

-(void)installInClass:(Class)aClass withSignature:(const char*)signature
{
	//--- setup the method structure
	if ( aClass != nil ) {
		methodDescriptor=class_getInstanceMethod( aClass, selname);
		
		if ( methodDescriptor ) {
			oldIMP= class_getMethodImplementation(aClass, selname);
		}
		//---   setup undo 
        
        //---
		
		//--- install method callback stub 
		
		[self createStubAndSetupCallback];
		
//		class_lookupMethod( aClass, selname );
		
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


#else



-(void)installInClass:(Class)aClass withSignature:(const char*)signature
{
	//--- setup the method structure
	if ( aClass != nil ) {
		memset( &methodDescriptor,  0, sizeof methodDescriptor );
		methodDescriptor.method_name = selname;
		methodDescriptor.method_types = (char*)signature;
		methodDescriptor.method_imp = [self function];
		
		//--- setup the method list
		
		memset( &list,  0, sizeof list );
		list.method_count = 1;
		list.method_list[0] = methodDescriptor;
		
		//---   setup undo 
        
        memset( &undoList,  0, sizeof undoList );
        oldMethodDescriptor = class_getInstanceMethod(aClass,selname);
        if ( oldMethodDescriptor ) {
            undoList.method_count = 1;
            undoList.method_list[0] = *oldMethodDescriptor;
        }
        
        //---
		
		class_addMethods( aClass, &list );
		//--- install method callback stub 
		
		[self createStubAndSetupCallback];
		
		class_lookupMethod( aClass, selname );
		
		installed = YES;
        targetClass = aClass;
        
        
	} else {
		installed = NO;
	}
	
}


-(void)uninstall
{
    if ( installed && targetClass && oldMethodDescriptor ) {
        class_removeMethods( targetClass, &list );
        class_addMethods(targetClass,&undoList );
		class_lookupMethod( targetClass, methodDescriptor.method_name );
        installed=NO;
        targetClass=nil;
    }
}
-(const char*)typeSignature
{
//	NSLog(@"%@ : %s",NSStringFromSelector(selname),methodDescriptor.method_types);
	return methodDescriptor.method_types;
}



#endif

-invokeOn:target withVarArgs:(va_list)args
{
	//	return [target evaluateScript:script];
	id formalParameters = [self formalParameters];
	id parameters=[NSMutableArray array];
	int i;
	const char *signature=[self typeSignature];
	id returnVal;
	NSLog(@"selector: %s",selname);
//	NSLog(@"signature: %s",signature);
//	NSLog(@"target: %@",target);
	for (i=0;i<[formalParameters count];i++ ) {
//		NSLog(@"param[%d]: %c",i,signature[i+3]);
		switch ( signature[i+3] ) {
				id theArg;
			case '@':
			case '#':
				theArg = va_arg( args, id );
				NSLog(@"object arg: %@",theArg);
				if ( theArg == nil ) {
					theArg=[NSNil nsNil];
				}
				[parameters addObject:theArg];
				break;
			case 'c':
			case 'C':
			case 's':
			case 'S':
			case 'i':
			case 'I':
			{
				int intArg = va_arg( args, int );
//				NSLog(@"int param: %d",intArg );
				[parameters addObject:[NSNumber numberWithInt:intArg]];
				break;
			}
			case 'f':
			case 'F':
				[parameters addObject:[NSNumber numberWithFloat:va_arg( args, double )]];
				break;
			default:
				va_arg( args, void* );
				[parameters addObject:@"unhandled parameters "];
		}
	}
	returnVal = [self invokeOn:target withFormalParameters:formalParameters actualParamaters:parameters];
	if ( signature[0] == 'i' ) {
#ifdef __x86_64__
		returnVal=(id)[returnVal longLongValue];
#else
		returnVal=(id)[returnVal intValue];
#endif
	}
	return returnVal;
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
	id returnVal;
	
	returnVal = [[self method] evaluateOnObject:target parameters:parameters];
	return returnVal;
}

-invokeOn:target
{
//	return [target evaluateScript:script];
//	NSLog(@"invokeOn:");
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
    return [NSString stringWithFormat:@"<%@:%x: address of callback block: %x callbackfun %x ",[self class],self,&callback,callback.callBackFun];
}

@end

@interface __MPWMethodCallBackDummyTestClass : NSObject {}
@end

@implementation __MPWMethodCallBackDummyTestClass

-compile:aScript
{
	return aScript;
}

-evaluateScript:script onObject:target
{
	//	NSLog(@"evaluateScript!");
	return [NSString stringWithFormat:@"script: %@ target: %x",script, target];
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

@end


@interface __MPWMethodCallBackDummyTestClass(silenceWarningsAboutMethodsWeWillDefineDynamically)

-xxxDummy2;
-xxxDummyMulti:anArg andMore:moreArgs;

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
	[method setScript:@"aScript"];
	[callback setMethod:method];
	[callback setName:@"xxxDummyMulti:andMore:"];
	[callback installInClass:[target class] withSignature:"@@:@@"];
	returnValue = [target xxxDummyMulti:@"testArg1" andMore:@"testArg2"];
//	IDEXPECT( returnValue, expectedReturn, @"expected return of install");
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
    NSAssert1( returnValue != initialReturn, @"original return value not same as override: %d",returnValue);
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

+(NSArray*)testSelectors
{
	return [NSArray arrayWithObjects:
		@"testInstallWorks",
		@"testActualCallbackDirect",
		@"testUndoOverride",
		@"testActualCallbackViaMessageSend",
		@"testMultiArgMessageSend",
		nil
		];
}

@end
