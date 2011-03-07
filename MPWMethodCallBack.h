//
//  MPWMethodCallBack.h
//  MPWTalk
//
//  Created by Marcel Weiher on 22/04/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>
#import <objc/objc-class.h>

@class MPWMethodHeader;

typedef struct {
	id	selfPtr;
	IMP	callBackFun;
} CallBackBlock;


#define  MPWMethodStubSize  800
#define  PADSIZE 32
@interface MPWMethodCallBack : MPWObject {
#if __OBJC2__ || ( MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 )
	Method	methodDescriptor;
	IMP		oldIMP;
#else
	struct objc_method_list undoList;
	struct objc_method_list list;
	struct objc_method methodDescriptor;
    Method oldMethodDescriptor;
#endif
	Class targetClass;
	id	method;
	int installed;
	SEL selname;
	CallBackBlock callback;
	char pad[PADSIZE];
	char stub[MPWMethodStubSize];
}


-(void)installInClass:(Class)classToInstallNewMethodIn;
-(void)installInClass:(Class)aClass withSignature:(const char*)signature;

-invokeOn:target;
-invokeOn:target withVarArgs:(va_list)args;
-(void)setMethod:method;
-(int)additionalArgs;
-formalParameters;
-invokeOn:target withFormalParameters:formalParameters actualParamaters:parameters;


@end
