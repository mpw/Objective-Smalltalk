//
//  MPWRelScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 5/10/11.
//  Copyright 2011 metaobject ltd. All rights reserved.
//

#import "MPWGenericScheme.h"


@interface MPWRelScheme : MPWGenericScheme {
	MPWScheme* baseScheme;
	NSString* baseIdentifier;
}

@end
