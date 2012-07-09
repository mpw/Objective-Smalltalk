//
//  MPWRelScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 5/10/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import "MPWGenericScheme.h"

@class MPWBinding;

@interface MPWRelScheme : MPWGenericScheme {
	MPWScheme* baseScheme;
	NSString* baseIdentifier;
    id storedContext;
    MPWBinding *baseRef;        // not used yet
}

@end
