//
//  MPWGenericBinding.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 11/27/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <MPWTalk/MPWBinding.h>


@interface MPWGenericBinding : MPWBinding {
	NSString* name;
	id		scheme;
}

-initWithName:(NSString*)envName scheme:newScheme;

@end
