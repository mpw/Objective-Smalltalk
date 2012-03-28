//
//  MPWObjectMirror.h
//  MPWTest
//
//  Created by Marcel Weiher on 5/30/11.
//  Copyright 2011 metaobject ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPWClassMirror;

@interface MPWObjectMirror : NSObject
{
	id	theObject;
}

-initWithObject:anObject;
+mirrorWithObject:anObject;
-(MPWClassMirror*)classMirror;
-(Class)setObjectClass:(Class)aClass;

@end
