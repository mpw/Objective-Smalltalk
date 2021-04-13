//
//  MPWMessage.h
//  Arch-S
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

@property (nonatomic,assign) BOOL isSuper;
@property (nonatomic,assign) Class classToStart;


@end

@interface NSObject(receiveMessage)

-receiveMessage:(MPWMessage*)aMessage withArguments:(id*)args count:(int)argCount;

@end
