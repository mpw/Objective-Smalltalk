//
//  MPWMethod.h
//  MPWTalk
//
//  Created by Marcel Weiher on 12/09/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWExpression.h>

@class MPWMethodHeader;

@interface MPWMethod : MPWExpression {
	MPWMethodHeader*	methodHeader;
	id					context;
	id					methodType;
}

objectAccessor_h(MPWMethodHeader*, methodHeader, setMethodHeader )
idAccessor_h( context, setContext )
idAccessor_h( methodType, setMethodType )

-evaluateOnObject:target parameters:parameters;
-(MPWMethodHeader*)header;
-formalParameters;


@end
