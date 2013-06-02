//
//  MPWGenericBinding.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 11/27/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWBinding.h>


@interface MPWGenericBinding : MPWBinding {
	NSString* name;
}

-initWithName:(NSString*)envName scheme:newScheme;
+bindingWithName:(NSString*)envName scheme:newScheme;
-(NSString*)name;
-(BOOL)hasChildren;
-path;

@end
