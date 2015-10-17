//
//  MPWFileBinding.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/11/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWGenericBinding.h>


@interface MPWFileBinding : MPWGenericBinding {
	id	url;
    BOOL ignoreChanges;
}

-url;
-initWithURLString:(NSString*)urlString;
-initWithURL:(NSURL*)newURL;
-initWithPath:(NSString*)path;

@end
