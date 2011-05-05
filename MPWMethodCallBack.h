//
//  MPWMethodCallBack.h
//  MPWTalk
//
//  Created by Marcel Weiher on 22/04/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWBlockInvocable.h>
#import <objc/objc-class.h>

@class MPWMethodHeader;

@interface MPWMethodCallBack : MPWBlockInvocable {
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
	IMP stub;
}


-(void)installInClass:(Class)classToInstallNewMethodIn;
-(void)installInClass:(Class)aClass withSignature:(const char*)signature;

-invokeWithTarget:target args:(va_list)args;
-(void)setMethod:method;
-formalParameters;
-invokeOn:target withFormalParameters:formalParameters actualParamaters:parameters;


@end
