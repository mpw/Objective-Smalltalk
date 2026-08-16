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
//    NSLog(@"fast message send to: %@",NSStringFromSelector(selector));
    switch (argCount) {
        case 0:
            return ((IMP0)objc_msgSend)( receiver, selector);
        case 1:
            return ((IMP1)objc_msgSend)( receiver, selector,argbuf[0]);
        case 2:
            return ((IMP2)objc_msgSend)( receiver, selector,argbuf[0],argbuf[1]);
        case 3:
            return ((IMP3)objc_msgSend)( receiver, selector,argbuf[0],argbuf[1],argbuf[2]);
        case 4:
            return ((IMP4)objc_msgSend)( receiver, selector,argbuf[0],argbuf[1],argbuf[2],argbuf[3]);
        case 5:
            return ((IMP5)objc_msgSend)( receiver, selector,argbuf[0],argbuf[1],argbuf[2],argbuf[3],argbuf[4]);
        case 6:
            return ((IMP6)objc_msgSend)( receiver, selector,argbuf[0],argbuf[1],argbuf[2],argbuf[3],argbuf[4],argbuf[5]);
        default:
            [NSException raise:@"unsupported" format:@"unsupported message with %d args",argCount];
            return nil;
    }
}


@end
