//
//  MPWBinding.h
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 BBC. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWScheme,MPWIdentifier,MPWEvaluator;

@interface MPWBinding : MPWObject {
	BOOL	isBound;
	id		_value;
    id		scheme;
    id      identifier;
    MPWEvaluator    *defaultContext;

}

+bindingWithValue:aValue;
-initWithValue:aValue;

idAccessor_h( value, _setValue )
idAccessor_h( scheme, setScheme )


-(void)bindValue:value;
-(void)unbindValue;
-(BOOL)isBound;
idAccessor_h(identifier, setIdentifier)
scalarAccessor_h(MPWEvaluator*, defaultContext, setDefaultContext)

@end
