//
//  MPWBundleScheme.h
//  Arch-S
//
//  Created by Marcel Weiher on 5/28/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWFileSchemeResolver.h>


@interface MPWBundleScheme : MPWFileSchemeResolver {
	NSBundle *bundle;
}

+schemeWithBundle:(NSBundle*)aBundle;
+mainBundleScheme;
+classBundleScheme:(Class)aClass;

@end
