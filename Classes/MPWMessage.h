//
//  MPWMessage.h
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWBoxerUnboxer;

@interface MPWMessage : MPWObject {
	SEL	selector;
	id	_signature;
}

+messageWithSelector:(SEL)aSelector ;
+messageWithSelector:(SEL)aSelector initialReceiver:msgReceiver;

-sendTo:aReceiver withArguments:(id*)args count:(int)argCount;

+(void)setBoxer:(MPWBoxerUnboxer*)aBoxer forTypeString:(NSString*)typeString;


@end

@interface NSObject(receiveMessage)

-receiveMessage:(MPWMessage*)aMessage withArguments:(id*)args count:(int)argCount;

@end