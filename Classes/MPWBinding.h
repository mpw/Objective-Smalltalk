//
//  MPWBinding.h
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWScheme,MPWIdentifier,MPWEvaluator;

@interface MPWBinding : MPWObject {
	BOOL	isBound;
	id		_value;
    id		scheme;
    MPWIdentifier*      identifier;
    MPWEvaluator    *defaultContext;
    id      delegate;

}

+bindingWithValue:aValue;
-initWithValue:aValue;
-_value;
idAccessor_h( value, _setValue )
idAccessor_h( delegate, setDelegate)
objectAccessor_h( MPWScheme, scheme, setScheme )


-(void)bindValue:value;
-(void)unbindValue;
-(BOOL)isBound;
objectAccessor_h(MPWIdentifier,identifier, setIdentifier)
scalarAccessor_h(MPWEvaluator*, defaultContext, setDefaultContext)
-valueForPathComponent:(NSString*)kvpath;

-(BOOL)hasChildren;
-(BOOL)isDirectory;
-children;
-(NSArray*)childNames;
-(NSArray*)allLinks;
-bindNames;
-name;


@end
