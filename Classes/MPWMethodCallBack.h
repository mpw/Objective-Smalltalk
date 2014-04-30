//
//  MPWMethodCallBack.h
//  MPWTalk
//
//  Created by Marcel Weiher on 22/04/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWBlockInvocable.h>
#import <objc/runtime.h>

@class MPWMethodHeader;

@interface MPWMethodCallBack : MPWBlockInvocable {
	Method	savedMethodDescriptor;
	IMP		oldIMP;

	Class targetClass;
	id	method;
	int installed;
	SEL selname;
	IMP stub;
}


-(void)installInClass:(Class)classToInstallNewMethodIn;
-(void)installInClass:(Class)aClass withSignature:(const char*)signature;

-(void)setMethod:method;
-formalParameters;
-invokeOn:target withFormalParameters:formalParameters actualParamaters:parameters;


@end
