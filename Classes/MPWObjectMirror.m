//
//  MPWObjectMirror.m
//  MPWTest
//
//  Created by Marcel Weiher on 5/30/11.
//  Copyright 2011 Marcel Weiher. All rights reserved.
//

#import "MPWObjectMirror.h"
#import <MPWFoundation/AccessorMacros.h>
#import "MPWClassMirror.h"
#import <objc/runtime.h>


@implementation MPWObjectMirror : NSObject

idAccessor( theObject, setTheObject )

-initWithObject:anObject
{
	self=[super init];
	[self setTheObject:anObject];
	return self;
}

+mirrorWithObject:anObject
{
	return [[[self alloc] initWithObject:anObject] autorelease];
}

-(MPWClassMirror*)classMirror
{
	return [MPWClassMirror mirrorWithClass:object_getClass(theObject)];
}

-(Class)setObjectClass:(Class)aClass
{
#if 1
	return object_setClass( theObject, aClass);
#else
	Class *ptr=(Class*)theObject;
	Class previous=*ptr;
	*ptr=aClass;
	return previous;
#endif	
}

@end
