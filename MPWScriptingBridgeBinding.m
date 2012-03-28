//
//  MPWScripingBridgeBinding.m
//  MPWTalk
//
//  Created by Marcel Weiher on 5/31/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import "MPWScriptingBridgeBinding.h"


@implementation MPWScriptingBridgeBinding

-_value
{
	id value=[super _value];
	if ( [value isKindOfClass:NSClassFromString(@"SBObject")] ) {
		id getValue=[value get];
		if ( getValue ) {
			value=getValue;
		}
	}
	return value;
}



@end
