//
//  MPWFastMessage.m
//  Arch-S
//
//  Created by Marcel Weiher on 9/9/06.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import "MPWFastMessage.h"
#import <objc/objc.h>
#import <objc/message.h>

@implementation MPWFastMessage

-initWithSelector:(SEL)aSelector count:(int)newCount
{
	self=[super init];
	selector=aSelector;
	count=newCount;
	return self;
}


+messageWithSelector:(SEL)aSelector typestring:(char*)newTypestring
{
	return [[[self alloc] initWithSelector:aSelector count:(int)strlen(newTypestring)] autorelease];
}
-sendTo:receiver withArguments:(id*)argbuf count:(int)argCount
{
    return ((IMP4)objc_msgSend)( receiver, selector, argbuf[0],argbuf[1],argbuf[2],argbuf[3] );
}


@end
