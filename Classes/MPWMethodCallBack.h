//
//  MPWMethodCallBack.h
//  MPWTalk
//
//  Created by Marcel Weiher on 22/04/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWBlockInvocable.h>
#import <objc/runtime.h>

@class MPWMethodHeader,MPWMethod;

@interface MPWMethodCallBack : MPWBlockInvocable {
	Method	savedMethodDescriptor;
	IMP		oldIMP;

	Class targetClass;
	id	method;
	BOOL installed;
	SEL selname;
}


-(void)installInClass:(Class)classToInstallNewMethodIn;
-(void)installInClassIfNecessary:(Class)aClass;
-(void)installInClass:(Class)aClass withSignature:(const char*)signature;

-(void)setMethod:method;
-(MPWMethod*)method;
-formalParameters;
-invokeOn:target withFormalParameters:formalParameters actualParamaters:parameters;

-(BOOL)installed;

@end
