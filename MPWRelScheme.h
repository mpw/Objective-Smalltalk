//
//  MPWRelScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 5/10/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import "MPWFilterScheme.h"

@class MPWBinding;

@interface MPWRelScheme : MPWFilterScheme {
	NSString* baseIdentifier;
    id storedContext;
    MPWBinding *baseRef;        // not used yet
}

@end
