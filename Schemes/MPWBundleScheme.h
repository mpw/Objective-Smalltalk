//
//  MPWBundleScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 5/28/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import "MPWFileSchemeResolver.h"


@interface MPWBundleScheme : MPWFileSchemeResolver {
	NSBundle *bundle;
}

+schemeWithBundle:(NSBundle*)aBundle;
+mainBundleScheme;
+classBundleScheme:(Class)aClass;

@end
