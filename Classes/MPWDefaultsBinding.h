//
//  MPWDefaultsBinding.h
//  MPWTalk
//
//  Created by Marcel Weiher on 6/4/11.
//  Copyright 2011 metaobject ltd. All rights reserved.
//

#import "MPWBinding.h"



@interface MPWDefaultsBinding : MPWBinding {
	NSString *key;
}

-initWithKey:(NSString*)newKey;

@end
