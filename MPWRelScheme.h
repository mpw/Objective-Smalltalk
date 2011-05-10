//
//  MPWRelScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 5/10/11.
//  Copyright 2011 metaobject ltd. All rights reserved.
//

#import "MPWScheme.h"


@interface MPWRelScheme : MPWScheme {
	MPWScheme* baseScheme;
	NSString* baseIdentifier;
}

@end
