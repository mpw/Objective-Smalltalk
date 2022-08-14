//
//  MPWMethod.h
//  Arch-S
//
//  Created by Marcel Weiher on 12/09/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWExpression.h>

@class MPWMethodHeader;

@interface MPWAbstractInterpretedMethod : MPWExpression {
	MPWMethodHeader*	methodHeader;
	id					context;
	id					methodType;
}

objectAccessor_h(MPWMethodHeader*, methodHeader, setMethodHeader )
idAccessor_h( context, setContext )
idAccessor_h( methodType, setMethodType )

-evaluateOnObject:target parameters:(NSArray*)parameters;
-(MPWMethodHeader*)header;
-(NSArray*)formalParameters;
-(NSString*)methodName;

@end
