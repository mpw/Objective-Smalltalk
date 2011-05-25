//
//  MPWResourceScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 5/15/11.
//  Copyright 2011 metaobject ltd. All rights reserved.
//

#import "MPWScheme.h"


@interface MPWResourceScheme : MPWScheme {
	MPWScheme *underlyingScheme;
}

@end
